import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';

class CompareSheet extends StatelessWidget {
  final List<Product> products;

  const CompareSheet({super.key, required this.products});

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
    final best = products.reduce((a, b) => a.score > b.score ? a : b);
    final cheapest = products.reduce((a, b) => a.price < b.price ? a : b);
    final topRated = products.reduce((a, b) => a.rating > b.rating ? a : b);
    final fastest = products.reduce((a, b) => a.deliveryDays < b.deliveryDays ? a : b);

    final rows = [
      _CompareRow('💰 Price', products.map((p) => _fmt(p.price)).toList(), cheapest.id, products),
      _CompareRow('⭐ Rating', products.map((p) => '${p.rating}/5').toList(), topRated.id, products),
      _CompareRow('🚚 Delivery', products.map((p) => p.delivery).toList(), fastest.id, products),
      _CompareRow('💸 Discount', products.map((p) => '${p.discount}%').toList(),
          products.reduce((a, b) => a.discount > b.discount ? a : b).id, products),
      _CompareRow('🏆 Score', products.map((p) => '${p.score.toInt()}/100').toList(), best.id, products),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚖️ Side-by-Side Comparison',
                  style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 16),

                // Column headers
                Row(
                  children: [
                    const SizedBox(width: 90),
                    ...products.map((p) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: p.id == best.id ? AppColors.accent.withValues(alpha: 0.12) : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: p.id == best.id ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border2,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(p.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(p.platform,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                            if (p.id == best.id)
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.badgeBest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Best', style: GoogleFonts.dmSans(fontSize: 8, color: AppColors.accent, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 10),

                // Comparison rows
                ...rows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(row.label,
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted)),
                      ),
                      ...row.values.asMap().entries.map((entry) {
                        final prod = row.products[entry.key];
                        final isWinner = prod.id == row.winnerId;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isWinner ? AppColors.accent.withValues(alpha: 0.12) : AppColors.card2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isWinner ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border2,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              entry.value,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400,
                                color: isWinner ? AppColors.accent : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareRow {
  final String label;
  final List<String> values;
  final String winnerId;
  final List<Product> products;
  _CompareRow(this.label, this.values, this.winnerId, this.products);
}
