import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../services/wishlist_service.dart';
import '../models/product.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  String _fmt(double price) {
    final s = price.toStringAsFixed(0);
    final result = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) result.write(',');
      result.write(s[i]);
      count++;
    }
    return '₹${result.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Consumer<WishlistService>(
          builder: (_, wishlist, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('❤️ Wishlist',
                        style: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text('${wishlist.count} item${wishlist.count != 1 ? 's' : ''} saved',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                wishlist.count == 0
                    ? _buildEmpty()
                    : Expanded(child: _buildItems(wishlist, context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('❤️', style: TextStyle(fontSize: 64, color: Colors.white12)),
            const SizedBox(height: 12),
            Text('Your wishlist is empty',
              style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Text('Save products to track price drops!',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildItems(WishlistService wishlist, BuildContext context) {
    final items = wishlist.items.values.toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      itemBuilder: (_, i) => _WishlistItem(
        product: items[i],
        hasDrop: wishlist.hasPriceDrop(items[i].id),
        onRemove: () => wishlist.remove(items[i].id),
        formatPrice: _fmt,
      ),
    );
  }
}

class _WishlistItem extends StatelessWidget {
  final Product product;
  final bool hasDrop;
  final VoidCallback onRemove;
  final String Function(double) formatPrice;

  const _WishlistItem({
    required this.product,
    required this.hasDrop,
    required this.onRemove,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDrop ? AppColors.green.withValues(alpha: 0.3) : AppColors.border2,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Emoji image
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppColors.bg4,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(formatPrice(product.price),
                      style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    const SizedBox(width: 8),
                    if (hasDrop)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('↓ Price Drop!',
                          style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.green)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${product.platformIcon} ${product.platform}',
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),

          // Remove
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: AppColors.bg4, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
