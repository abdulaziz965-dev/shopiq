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
    return Scaffold(
      backgroundColor: AppColors.bg,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good morning',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
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
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: GestureDetector(
        onTap: () {
          onOpenSearch?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.7),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120B1324),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 10),
              Text(
                'Search any product...',
                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GestureDetector(
        onTap: () => onOpenChat?.call(),
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.bg3, AppColors.bg4],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.7),
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
                      style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    'Ask me anything — "Best earphones under ₹3000"',
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTrending(BuildContext context) {
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
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border2, width: 0.5),
                  ),
                  child: Text(
                    '🔥 $term',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
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
