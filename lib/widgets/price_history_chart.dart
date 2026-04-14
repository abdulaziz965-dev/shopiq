import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/mock_data_service.dart';
import '../utils/app_colors.dart';

class PriceHistorySheet extends StatelessWidget {
  final Product product;
  const PriceHistorySheet({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 380;
    final history = MockDataService.getPriceHistory(product.id);
    final minPrice = history.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = history.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final currentPrice = product.price;

    final spots = history.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.price)).toList();

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.show_chart_rounded, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Text('Price History',
                      style: GoogleFonts.sora(fontSize: isCompact ? 15 : 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const Spacer(),
                    Text('Last 6 months',
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(product.platform,
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(child: _statBox('Current price', _fmt(currentPrice), AppColors.accent)),
                    const SizedBox(width: 8),
                    Expanded(child: _miniInfoBox('Platform', product.platform)),
                  ],
                ),
                const SizedBox(height: 16),

                // Chart
                SizedBox(
                  height: isCompact ? 150 : 160,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.border2,
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= history.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat('MMM').format(history[idx].date),
                                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.accent,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                              radius: 3,
                              color: AppColors.accent,
                              strokeWidth: 0,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accent.withValues(alpha: 0.2),
                                AppColors.accent.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      minY: minPrice * 0.95,
                      maxY: maxPrice * 1.05,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Price alert button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🔔 Price alert set! We\'ll notify you when price drops.',
                              style: GoogleFonts.dmSans()),
                          backgroundColor: AppColors.card2,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_rounded, size: 18),
                    label: Text('Set Price Drop Alert',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: color.withValues(alpha: 0.8))),
            const SizedBox(height: 3),
            Text(value, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _miniInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border2, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 3),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

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
}
