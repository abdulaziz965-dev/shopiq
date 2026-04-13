import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class DealCard extends StatelessWidget {
  final Map<String, dynamic> deal;
  final bool showDiscount;
  final VoidCallback? onTap;

  const DealCard({
    super.key,
    required this.deal,
    required this.showDiscount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 156,
        height: 178,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(deal['color'] as int),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border2, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: showDiscount ? AppColors.red : AppColors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  showDiscount
                      ? '-${deal['discount']}'
                      : '↓${deal['drop']}',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Emoji
            Container(
              width: double.infinity,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  deal['emoji'] as String,
                  style: const TextStyle(fontSize: 34),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              deal['title'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),

            // Price
            Text(
              deal['price'] as String,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            Text(
              deal['original'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppColors.textMuted,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
