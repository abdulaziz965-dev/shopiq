import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../services/mock_data_service.dart';
import '../services/search_service.dart';
import '../widgets/deal_card.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenChat;

  const HomeScreen({
    super.key,
    this.onOpenSearch,
    this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildSearchBox(context)),
            SliverToBoxAdapter(child: _buildAIBanner(context)),
            SliverToBoxAdapter(child: _buildTrending(context)),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: '⚡ Flash Deals',
                showMore: true,
                onTapMore: () => _searchAndOpen(context, 'best flash deals'),
              ),
            ),
            SliverToBoxAdapter(child: _buildDealsRow(context, MockDataService.flashDeals, showDiscount: true)),
            const SliverToBoxAdapter(child: SectionHeader(title: '📉 Price Drops')),
            SliverToBoxAdapter(child: _buildDealsRow(context, MockDataService.priceDrops, showDiscount: false)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  void _searchAndOpen(BuildContext context, String query) {
    context.read<SearchService>().search(query);
    onOpenSearch?.call();
  }

  Widget _buildHeader(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary;
    final muted = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good morning',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: body,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.accent, AppColors.accent2],
            ).createShader(bounds),
            child: Text(
              'Smart Shopper 👋',
              style: GoogleFonts.sora(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find better prices across stores in seconds.',
            style: GoogleFonts.dmSans(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: GestureDetector(
        onTap: () {
          onOpenSearch?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65), width: 0.7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: muted, size: 20),
              const SizedBox(width: 10),
              Text(
                'Search any product...',
                style: GoogleFonts.dmSans(color: muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIBanner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary;
    final muted = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GestureDetector(
        onTap: () => onOpenChat?.call(),
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.18),
              cs.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65), width: 0.7),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ShopIQ AI Assistant',
                      style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    'Ask me anything — "Best earphones under ₹3000"',
                    style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: muted, size: 20),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTrending(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '🔥 Trending'),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: MockDataService.trendingTerms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final term = MockDataService.trendingTerms[i];
              return GestureDetector(
                onTap: () {
                  _searchAndOpen(context, term);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6), width: 0.5),
                  ),
                  child: Text(
                    '🔥 $term',
                    style: GoogleFonts.dmSans(fontSize: 12, color: textSecondary),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDealsRow(BuildContext context, List<Map<String, dynamic>> deals, {required bool showDiscount}) {
    return SizedBox(
      height: 194,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: deals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => DealCard(
          deal: deals[i],
          showDiscount: showDiscount,
          onTap: () => _searchAndOpen(context, (deals[i]['title'] as String?) ?? ''),
        ),
      ),
    );
  }
}
