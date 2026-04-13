import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../services/search_service.dart';
import '../services/backend_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/ai_summary_card.dart';
import '../widgets/compare_sheet.dart';
import '../widgets/price_history_chart.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _recentSearchesKey = 'recent_searches_v1';

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _backend = BackendService();
  String? _aiSummary;
  static const _filters = ['All', 'Amazon', 'Flipkart', 'Myntra', 'Under ₹5000', '4★+'];
  static const _baseSuggestions = [
    'iPhone 15',
    'Samsung Galaxy S24',
    'OnePlus 12',
    'MacBook Air M3',
    'Gaming Laptop',
    'Sony WH-1000XM5',
    'Boat Airdopes',
    'Smartwatch',
    'Running Shoes',
    'Bluetooth Speaker',
    'DSLR Camera',
    'Air Conditioner',
  ];

  List<String> _suggestions = [];
  List<String> _recentSearches = [];
  List<String> _resultTitleHints = [];
  List<String> _backendHints = [];
  Timer? _suggestDebounce;
  int _suggestionRequestId = 0;

  bool get _showSuggestions => _suggestions.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _suggestDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_recentSearchesKey) ?? const [];
    if (!mounted) return;
    setState(() {
      _recentSearches = saved;
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    final updated = <String>[q, ..._recentSearches.where((e) => e.toLowerCase() != q.toLowerCase())]
        .take(10)
        .toList();

    setState(() {
      _recentSearches = updated;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, updated);
  }

  Future<void> _doSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    _focusNode.unfocus();
    _suggestDebounce?.cancel();
    _suggestionRequestId++;
    setState(() {
      _suggestions = [];
      _aiSummary = null;
    });
    await _saveRecentSearch(normalized);
    final svc = context.read<SearchService>();
    await svc.search(normalized);
    if (!mounted) return;
    setState(() {
      _aiSummary = _compactSummary(svc.results);
      _resultTitleHints = svc.results
          .map((e) => e.title.trim())
          .where((e) => e.isNotEmpty)
          .take(20)
          .toList();
    });
  }

  void _onQueryChanged(String value) {
    final q = value.trim().toLowerCase();
    if (q.isEmpty) {
      _suggestDebounce?.cancel();
      setState(() {
        _backendHints = [];
        _suggestions = [];
      });
      return;
    }

    _rebuildSuggestions(q);
    _scheduleBackendHints(q);
  }

  void _scheduleBackendHints(String query) {
    _suggestDebounce?.cancel();
    final requestId = ++_suggestionRequestId;

    _suggestDebounce = Timer(const Duration(milliseconds: 280), () async {
      final hints = await _backend.autocompleteSuggestions(query, limit: 6);
      if (!mounted || requestId != _suggestionRequestId) return;
      setState(() {
        _backendHints = hints;
      });
      _rebuildSuggestions(query);
    });
  }

  void _rebuildSuggestions(String loweredQuery) {
    final merged = <String>[];

    void addMatching(Iterable<String> source) {
      for (final candidate in source) {
        final normalized = candidate.trim();
        if (normalized.isEmpty) continue;
        if (!normalized.toLowerCase().contains(loweredQuery)) continue;
        if (merged.any((e) => e.toLowerCase() == normalized.toLowerCase())) continue;
        merged.add(normalized);
        if (merged.length >= 8) return;
      }
    }

    addMatching(_recentSearches);
    addMatching(_backendHints);
    addMatching(_resultTitleHints);
    addMatching(_baseSuggestions);

    merged.sort((a, b) {
      final byScore = _scoreSuggestion(b, loweredQuery).compareTo(_scoreSuggestion(a, loweredQuery));
      if (byScore != 0) return byScore;
      return a.length.compareTo(b.length);
    });

    if (!mounted) return;
    setState(() {
      _suggestions = merged.take(8).toList();
    });
  }

  Future<void> _selectSuggestion(String value) async {
    final selected = value.trim();
    if (selected.isEmpty) return;

    FocusScope.of(context).unfocus();
    _suggestDebounce?.cancel();
    _suggestionRequestId++;

    _controller.value = TextEditingValue(
      text: selected,
      selection: TextSelection.collapsed(offset: selected.length),
    );

    setState(() {
      _suggestions = [];
      _aiSummary = null;
    });

    await _saveRecentSearch(selected);
    final svc = context.read<SearchService>();
    await svc.search(selected);
    if (!mounted) return;
    setState(() {
      _aiSummary = _compactSummary(svc.results);
      _resultTitleHints = svc.results
          .map((e) => e.title.trim())
          .where((e) => e.isNotEmpty)
          .take(20)
          .toList();
    });
  }

  int _scoreSuggestion(String candidate, String loweredQuery) {
    final text = candidate.toLowerCase();
    if (text == loweredQuery) return 100;
    if (text.startsWith(loweredQuery)) return 80;

    final words = text.split(RegExp(r'\s+'));
    if (words.any((w) => w.startsWith(loweredQuery))) return 65;

    final tokens = loweredQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isNotEmpty && tokens.every((t) => text.contains(t))) return 50;

    if (text.contains(loweredQuery)) return 35;
    return 0;
  }

  String? _compactSummary(List<Product> results) {
    if (results.isEmpty) return null;
    final top = results.first;
    return '${top.title} - ${top.platform}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      body: SafeArea(child: Column(children: [
        _buildSearchBar(),
        if (_showSuggestions) _buildSuggestionDropdown(),
        Expanded(child: Consumer<SearchService>(builder: (_, svc, __) {
          switch (svc.state) {
            case SearchState.idle: return _buildIdle();
            case SearchState.loading: return _buildLoading(svc);
            case SearchState.empty: return _buildEmpty(svc);
            case SearchState.results: return _buildResults(svc);
          }
        })),
      ])),
    );
  }

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 2),
    child: Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.7), width: 0.7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]),
          child: Row(children: [
            Padding(padding: const EdgeInsets.only(left: 14),
              child: Icon(Icons.search_rounded, color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted, size: 20)),
            Expanded(child: TextField(
              controller: _controller, focusNode: _focusNode,
              onTapOutside: (_) {
                _focusNode.unfocus();
                if (_suggestions.isNotEmpty && mounted) {
                  setState(() => _suggestions = []);
                }
              },
              onChanged: _onQueryChanged,
              onSubmitted: _doSearch, textInputAction: TextInputAction.search,
              style: GoogleFonts.dmSans(fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Search any product...', filled: false,
                hintStyle: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
            )),
            GestureDetector(onTap: () => _doSearch(_controller.text),
              child: Container(margin: const EdgeInsets.all(6), width: 38, height: 38,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18))),
          ]),
        ),
      ),
    ]),
  );

  Widget _buildSuggestionDropdown() => Container(
    margin: const EdgeInsets.fromLTRB(12, 2, 12, 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.65), width: 0.7),
    ),
    child: Material(
      type: MaterialType.transparency,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        itemBuilder: (_, i) {
          final item = _suggestions[i];
          return InkWell(
            onTap: () => _selectSuggestion(item),
            child: ListTile(
              dense: true,
              minLeadingWidth: 18,
              leading: Icon(Icons.search_rounded, size: 16, color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted),
              title: Text(
                item,
                style: GoogleFonts.dmSans(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _buildResults(SearchService svc) {
    final isCompact = MediaQuery.of(context).size.width < 380;

    return Column(children: [
    if (svc.errorMessage != null) _buildInfoBanner(svc.errorMessage!),
    SizedBox(height: isCompact ? 42 : 46, child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: _filters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (_, i) {
        final f = _filters[i]; final isActive = svc.activeFilter == f;
        final label = isCompact && f == 'Under ₹5000' ? '<₹5k' : f;
        return GestureDetector(onTap: () => svc.applyFilter(f),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 14, vertical: isCompact ? 6 : 7),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? AppColors.accent : AppColors.border2, width: 0.7)),
            child: Text(label, style: GoogleFonts.dmSans(fontSize: isCompact ? 11 : 12,
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400))));
      },
    )),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${svc.results.length} results', style: GoogleFonts.dmSans(fontSize: isCompact ? 11 : 12, color: AppColors.textMuted)),
        GestureDetector(onTap: () => showModalBottomSheet(context: context, isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CompareSheet(products: svc.results.take(3).toList())),
          child: Container(padding: EdgeInsets.symmetric(horizontal: isCompact ? 9 : 11, vertical: isCompact ? 5 : 6),
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.border2, width: 0.7),
            ),
            child: Text(isCompact ? 'Compare' : '⚖️ Compare', style: GoogleFonts.dmSans(fontSize: isCompact ? 10.5 : 11, color: AppColors.textSecondary)))),
      ])),
    if (_aiSummary != null) AISummaryCard(summary: _aiSummary, loading: false),
    Expanded(child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: svc.results.length,
      itemBuilder: (_, i) => ProductCard(product: svc.results[i], index: i,
        onPriceHistory: () => showModalBottomSheet(context: context, isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => PriceHistorySheet(product: svc.results[i]))))),
    ]);
  }


  Widget _buildInfoBanner(String msg) => Container(
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: AppColors.accent4.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.accent4.withValues(alpha: 0.2), width: 0.5)),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: AppColors.accent4, size: 15),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.accent4))),
    ]));

  Widget _buildLoading(SearchService svc) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 64, height: 64,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
        borderRadius: BorderRadius.circular(20)),
      child: const Center(child: Text('🔍', style: TextStyle(fontSize: 30)))),
    const SizedBox(height: 20),
    const SizedBox(width: 32, height: 32,
      child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5)),
    const SizedBox(height: 16),
    Text('⚡ Scanning Amazon, Flipkart & more...',
      style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary)),
    const SizedBox(height: 6),
    Text('Comparing real-time prices', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted)),
  ]));

  Widget _buildEmpty(SearchService svc) => Center(child: Padding(padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('😕', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 12),
      Text('No results found', style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
      if (svc.errorMessage != null) ...[
        const SizedBox(height: 8),
        Text(svc.errorMessage!, textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted, height: 1.5)),
      ],
      const SizedBox(height: 20),
    ])));

  Widget _buildIdle() {
    final cats = [['🎧','Headphones'],['📱','Smartphones'],['💻','Laptops'],
      ['👟','Shoes'],['⌚','Smartwatches'],['🎮','Gaming'],['📷','Cameras'],['🏠','Appliances']];
    return Column(children: [
      const SizedBox(height: 16),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [Text('Browse Categories', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600))])),
      const SizedBox(height: 10),
      Expanded(child: GridView.count(crossAxisCount: 2, padding: const EdgeInsets.symmetric(horizontal: 12),
        crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.5,
        children: cats.map((c) => GestureDetector(
          onTap: () { _controller.text = c[1]; _doSearch(c[1]); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border2, width: 0.5)),
            child: Row(children: [
              Text(c[0], style: const TextStyle(fontSize: 22)), const SizedBox(width: 10),
              Text(c[1], style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500)),
            ])))).toList())),
    ]);
  }
}
