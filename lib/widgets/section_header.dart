import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool showMore;
  final VoidCallback? onTapMore;

  const SectionHeader({
    super.key,
    required this.title,
    this.showMore = false,
    this.onTapMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
            style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          if (showMore)
            GestureDetector(
              onTap: onTapMore,
              behavior: HitTestBehavior.opaque,
              child: Text('See all',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.accent)),
            ),
        ],
      ),
    );
  }
}
