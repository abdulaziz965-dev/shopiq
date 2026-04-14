import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../services/wishlist_service.dart';
import '../utils/app_colors.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final int index;
  final VoidCallback? onPriceHistory;

  const ProductCard({super.key, required this.product, required this.index, this.onPriceHistory});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 65), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmt(double price) {
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) buf.write(',');
      buf.write(s[i]);
      count++;
    }
    return '₹${buf.toString().split('').reversed.join()}';
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening ${widget.product.platform}...'),
            backgroundColor: AppColors.card2, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isSaved = context.watch<WishlistService>().isSaved(p.id);
    final isCompact = MediaQuery.of(context).size.width < 380;
    final imageSize = isCompact ? 74.0 : 82.0;

    return FadeTransition(opacity: _fade, child: SlideTransition(position: _slide,
      child: Padding(padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: p.isBest ? AppColors.accent : AppColors.border2,
              width: p.isBest ? 1.0 : 0.5),
            boxShadow: p.isBest ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.12), blurRadius: 14, spreadRadius: 1)] : null,
          ),
          child: Material(color: Colors.transparent, child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openLink(p.affiliateUrl),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Product image (real URL or emoji fallback)
                  Container(width: imageSize, height: imageSize,
                    decoration: BoxDecoration(
                      color: AppColors.bg4, 
                      borderRadius: BorderRadius.circular(14),
                      gradient: p.imageUrl == null ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.bg4,
                          AppColors.bg4.withValues(alpha: 0.7),
                        ],
                      ) : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: p.imageUrl != null
                        ? Image.network(p.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(p.emoji, style: const TextStyle(fontSize: 36)),
                                  const SizedBox(height: 2),
                                  Text('No image', style: GoogleFonts.dmSans(fontSize: 8, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            loadingBuilder: (_, child, progress) => progress == null ? child
                                : Center(child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2, color: AppColors.accent)))
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.emoji, style: const TextStyle(fontSize: 36)),
                              const SizedBox(height: 2),
                              Text('No image', style: GoogleFonts.dmSans(fontSize: 8, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Badges
                    if (p.isBest || p.isCheapest || p.isTopRated || p.isFastest)
                      Padding(padding: const EdgeInsets.only(bottom: 6),
                        child: Wrap(spacing: 4, runSpacing: 3, children: [
                          if (p.isBest) _badge('🏆 Best Value', AppColors.badgeBest, AppColors.accent),
                          if (p.isCheapest) _badge('💚 Cheapest', AppColors.badgeCheap, AppColors.green),
                          if (p.isTopRated) _badge('⭐ Top Rated', AppColors.badgeRated, AppColors.accent4),
                          if (p.isFastest) _badge('⚡ Fastest', AppColors.badgeFast, AppColors.accent2),
                        ])),

                    Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(fontSize: isCompact ? 12.5 : 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.35)),
                    const SizedBox(height: 4),

                    Row(children: [
                      Text(p.platformIcon, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${p.platform} · ${p.delivery}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),

                    // Price row
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text(_fmt(p.price), style: GoogleFonts.sora(fontSize: isCompact ? 16.5 : 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(width: 6),
                        if (p.originalPrice > p.price) ...[
                          Text(_fmt(p.originalPrice), style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 4),
                          Text('-${p.discount}%', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green)),
                        ],
                      ]),
                    ),

                    const SizedBox(height: 4),
                    // Rating
                    Row(children: [
                      const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
                      const SizedBox(width: 2),
                      Text('${p.rating}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 3),
                      if (p.reviews > 0)
                        Flexible(
                          child: Text(
                            '(${p.reviews > 999 ? '${(p.reviews/1000).toStringAsFixed(1)}K' : p.reviews} reviews)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ),
                      const SizedBox(width: 4),
                      if (p.hasVerifiedReviews) const Icon(Icons.verified_rounded, color: AppColors.green, size: 12),
                      if (p.suspiciousReviews) const Icon(Icons.warning_amber_rounded, color: AppColors.accent4, size: 12),
                    ]),
                  ])),

                  // Heart button
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); context.read<WishlistService>().toggle(p); },
                    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                      width: isCompact ? 30 : 32, height: isCompact ? 30 : 32,
                      decoration: BoxDecoration(
                        color: isSaved ? AppColors.accent2.withValues(alpha: 0.15) : AppColors.bg4,
                        shape: BoxShape.circle),
                      child: Center(child: Icon(
                        isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isSaved ? AppColors.accent2 : AppColors.textMuted, size: 17)))),
                ]),

                // Score bar
                const SizedBox(height: 12),
                const Divider(color: AppColors.border2, height: 1),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('ShopIQ Score', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
                  Text('${p.score.toInt()}/100', style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent)),
                ]),
                const SizedBox(height: 5),
                ClipRRect(borderRadius: BorderRadius.circular(2),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: p.score / 100),
                    duration: Duration(milliseconds: 800 + widget.index * 50),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v, backgroundColor: AppColors.bg4,
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent), minHeight: 4))),

                // Action buttons
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: GestureDetector(onTap: widget.onPriceHistory,
                    child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: AppColors.bg4, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.show_chart_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text('Price History', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                      ])))),
                  const SizedBox(width: 8),
                  Expanded(child: GestureDetector(onTap: () => _openLink(p.affiliateUrl),
                    child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Flexible(child: Text('Buy on ${p.platform}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600))),
                      ])))),
                ]),
              ],
            )),
          )),
        ),
      ),
    ));
  }

  Widget _badge(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: fg)));
}
