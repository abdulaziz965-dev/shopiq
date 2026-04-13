import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_colors.dart';
import '../services/search_service.dart';
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
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _picker = ImagePicker();
  String? _aiSummary;
  static const _filters = ['All', 'Amazon', 'Flipkart', 'Myntra', 'Under ₹5000', '4★+'];

  @override
  void dispose() { _controller.dispose(); _focusNode.dispose(); super.dispose(); }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) return;
    _focusNode.unfocus();
    setState(() => _aiSummary = null);
    final svc = context.read<SearchService>();
    await svc.search(query);
    if (!mounted) return;
    setState(() => _aiSummary = _compactSummary(svc.results));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1024);
      if (picked == null || !mounted) return;
      setState(() => _aiSummary = null);
      final svc = context.read<SearchService>();
      await svc.searchFromFile(File(picked.path));
      if (!mounted) return;
      if (svc.imageResult != null) {
        _controller.text = svc.imageResult!.searchQuery;
      }
      setState(() => _aiSummary = _compactSummary(svc.results));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image error: $e'), backgroundColor: AppColors.card2));
      }
    }
  }

  String? _compactSummary(List<Product> results) {
    if (results.isEmpty) return null;
    final top = results.first;
    return '${top.title} - ${top.platform}';
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) =>
      Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Search by Image', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Snap or upload any product — AI identifies it and finds listings',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _ImgBtn(icon: Icons.camera_alt_rounded, label: 'Camera',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); })),
            const SizedBox(width: 12),
            Expanded(child: _ImgBtn(icon: Icons.photo_library_rounded, label: 'Gallery',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); })),
          ]),
          const SizedBox(height: 8),
        ]),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Column(children: [
        _buildSearchBar(),
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
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.7),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100B1324),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ]),
          child: Row(children: [
            const Padding(padding: EdgeInsets.only(left: 14),
              child: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20)),
            Expanded(child: TextField(
              controller: _controller, focusNode: _focusNode,
              onSubmitted: _doSearch, textInputAction: TextInputAction.search,
              style: GoogleFonts.dmSans(fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search any product...', filled: false,
                hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
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
      const SizedBox(width: 8),
      GestureDetector(onTap: _showImageSourceSheet,
        child: Container(width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x222563EB),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ]),
          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22))),
    ]),
  );

  Widget _buildResults(SearchService svc) {
    final isCompact = MediaQuery.of(context).size.width < 380;

    return Column(children: [
    if (svc.mode == SearchMode.image && svc.imageResult != null) _buildImgBanner(svc.imageResult!),
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

  Widget _buildImgBanner(dynamic r) {
    final c = r.confidence as String;
    final cc = c == 'high' ? AppColors.green : c == 'medium' ? AppColors.accent4 : AppColors.accent2;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.card2, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5)),
      child: Row(children: [
        Text(r.emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📷 Identified: ${r.productName}',
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: cc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text('${c.toUpperCase()} confidence',
                style: GoogleFonts.dmSans(fontSize: 9, color: cc, fontWeight: FontWeight.w700))),
            if ((r.brand as String).isNotEmpty) ...[
              const SizedBox(width: 6),
              Text('· ${r.brand}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted)),
            ],
          ]),
        ])),
      ]),
    );
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
    Text(svc.mode == SearchMode.image ? '🤖 Identifying product with AI...' : '⚡ Scanning Amazon, Flipkart & more...',
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
      GestureDetector(onTap: _showImageSourceSheet,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
            borderRadius: BorderRadius.circular(14)),
          child: Text('📷 Try Image Search',
            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)))),
    ])));

  Widget _buildIdle() {
    final cats = [['🎧','Headphones'],['📱','Smartphones'],['💻','Laptops'],
      ['👟','Shoes'],['⌚','Smartwatches'],['🎮','Gaming'],['📷','Cameras'],['🏠','Appliances']];
    return Column(children: [
      const SizedBox(height: 16),
      GestureDetector(onTap: _showImageSourceSheet,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.accent2.withValues(alpha: 0.08)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 0.5)),
          child: Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
                borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('📷', style: TextStyle(fontSize: 24)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Search by Photo', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700)),
              Text('Snap any product — AI identifies & finds real listings',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
            ])),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ]),
        )),
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

class _ImgBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _ImgBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
        borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 28), const SizedBox(height: 6),
        Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
      ])));
}
