import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../models/dashboard_model.dart';
import 'service_legends_modal.dart';
import 'payments_ledger_modal.dart';

class CollectionsLedgerCard extends StatelessWidget {
  final RevenueAnalytics revenue;
  final List<dynamic> payments;

  const CollectionsLedgerCard({
    super.key,
    required this.revenue,
    this.payments = const [],
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    final points = revenue.chart;
    final total = revenue.totalAmount;

    // Find highest point for Y-axis scaling
    double maxY = 1000.0;
    for (var p in points) {
      if (p.total > maxY) maxY = p.total;
    }
    // Round to nearest upper step
    maxY = (maxY * 1.25).clamp(1000.0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row Matching Web: 📈 COLLECTIONS LEDGER + Legend Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.trendingUp, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    "COLLECTIONS LEDGER",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              // Action Buttons: Legend Modal Trigger
              InkWell(
                onTap: () => ServiceLegendsModal.show(
                  context,
                  payments: payments,
                  totalRevenue: total,
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.tags, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 5),
                      Text(
                        "LEGEND",
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Total Revenue Subtitle matching Web: "Total Revenue: ₱14,957.15"
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              children: [
                const TextSpan(
                  text: "Total Revenue: ",
                  style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
                TextSpan(
                  text: currencyFormat.format(total),
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 120dp Multi-Point FlChart Line with Dots Matching Web Aesthetics
          SizedBox(
            height: 125,
            child: points.isEmpty
                ? Center(
                    child: Text(
                      "No collection data recorded in this period",
                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 3,
                        getDrawingHorizontalLine: (val) => FlLine(
                          color: Colors.white.withValues(alpha: 0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final idx = spot.spotIndex;
                              final date = (idx >= 0 && idx < points.length) ? points[idx].date : '';
                              return LineTooltipItem(
                                "$date\n${currencyFormat.format(spot.y)}",
                                GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: maxY / 2,
                            getTitlesWidget: (val, _) {
                              if (val == 0) {
                                return Text("₱0", style: GoogleFonts.inter(fontSize: 8, color: AppColors.textSecondary));
                              }
                              if (val >= 1000) {
                                return Text(
                                  "₱${(val / 1000).toStringAsFixed(0)}K",
                                  style: GoogleFonts.inter(fontSize: 8, color: AppColors.textSecondary),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 18,
                            interval: points.length > 6 ? (points.length / 4).floorToDouble() : 1,
                            getTitlesWidget: (val, _) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < points.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    points[idx].date,
                                    style: GoogleFonts.inter(
                                      fontSize: 8.5,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.total)).toList(),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: const Color(0xFF10B981),
                          barWidth: 2.2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: Colors.white,
                                strokeWidth: 1.5,
                                strokeColor: const Color(0xFF10B981),
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          const SizedBox(height: 14),

          // Bottom Button Matching Web Exactly: "GO TO PAYMENTS LEDGER"
          InkWell(
            onTap: () => PaymentsLedgerModal.show(
              context,
              payments: payments,
              totalRevenue: total,
            ),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.creditCard, size: 14, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "GO TO PAYMENTS LEDGER",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
