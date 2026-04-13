import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class AISummaryCard extends StatelessWidget {
  final String? summary;
  final bool loading;

  const AISummaryCard({super.key, this.summary, required this.loading});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 380;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.08),
            AppColors.accent2.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_rounded, color: AppColors.accent, size: 14),
              const SizedBox(width: 5),
              Text(
                'TOP PICK',
                style: GoogleFonts.dmSans(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: AppColors.accent, letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loading)
            Row(
              children: [
                const _PulseDot(delay: 0),
                const SizedBox(width: 3),
                const _PulseDot(delay: 200),
                const SizedBox(width: 3),
                const _PulseDot(delay: 400),
                const SizedBox(width: 10),
                Text('Analyzing listings...',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted)),
              ],
            )
          else if (summary != null)
            Text(
              summary!,
              maxLines: isCompact ? 4 : 5,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 12.5, color: AppColors.textSecondary, height: 1.55,
              ),
            ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final int delay;
  const _PulseDot({required this.delay});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6, height: 6,
        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
      ),
    );
  }
}
