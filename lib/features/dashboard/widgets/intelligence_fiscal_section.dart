import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../models/dashboard_model.dart';

class IntelligenceFiscalSection extends StatefulWidget {
  final RevenueAnalytics revenue;
  final TransactionAnalytics transactions;
  final DemographicAnalytics demographics;
  final List<dynamic> reports;

  const IntelligenceFiscalSection({
    super.key,
    required this.revenue,
    required this.transactions,
    required this.demographics,
    required this.reports,
  });

  @override
  State<IntelligenceFiscalSection> createState() => _IntelligenceFiscalSectionState();
}

class _IntelligenceFiscalSectionState extends State<IntelligenceFiscalSection> {
  int _activeTabIndex = 0; // 0: Treasury, 1: Requests, 2: Demographics, 3: Reports

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ultra Compact Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(LucideIcons.barChart3, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "INTELLIGENCE & FISCAL HUB",
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "LIVE",
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accentGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          // 4 Compact Segmented Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCompactTab(0, "Treasury", LucideIcons.wallet, const Color(0xFF10B981)),
                const SizedBox(width: 6),
                _buildCompactTab(1, "Requests", LucideIcons.fileText, const Color(0xFF8B5CF6)),
                const SizedBox(width: 6),
                _buildCompactTab(2, "Census", LucideIcons.users, const Color(0xFF3B82F6)),
                const SizedBox(width: 6),
                _buildCompactTab(3, "Reports", LucideIcons.alertTriangle, const Color(0xFFF59E0B)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Active View Body with smooth animated switcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildActiveTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTab(int index, String title, IconData icon, Color activeColor) {
    final isSelected = _activeTabIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _activeTabIndex = index),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.16) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: isSelected ? activeColor.withValues(alpha: 0.5) : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12.5,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return _buildTreasuryView();
      case 1:
        return _buildRequestsView();
      case 2:
        return _buildDemographicsView();
      case 3:
      default:
        return _buildReportsView();
    }
  }

  // 1. Treasury / Collections Compact View
  Widget _buildTreasuryView() {
    final points = widget.revenue.chart;
    final total = widget.revenue.totalAmount;
    final peakPoint = points.isNotEmpty
        ? points.reduce((curr, next) => curr.total > next.total ? curr : next)
        : null;

    return Column(
      key: const ValueKey('treasury_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Metric Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TOTAL REVENUE COLLECTED",
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _currencyFormat.format(total),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (peakPoint != null && peakPoint.total > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Peak: ${_currencyFormat.format(peakPoint.total)}",
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Compact Sparkline Chart (120dp height)
        SizedBox(
          height: 120,
          child: points.isEmpty
              ? _buildEmptyState("No revenue recorded in this period")
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.spotIndex;
                            final date = (idx >= 0 && idx < points.length) ? points[idx].date : '';
                            return LineTooltipItem(
                              "$date\n${_currencyFormat.format(spot.y)}",
                              GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 18,
                          interval: points.length > 5 ? (points.length / 3).floorToDouble() : 1,
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
                    lineBarsData: [
                      LineChartBarData(
                        spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.total)).toList(),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: const Color(0xFF10B981),
                        barWidth: 2.2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        const SizedBox(height: 10),

        // 2-Column Mini Snapshot
        Row(
          children: [
            Expanded(
              child: _buildMiniStatPill(
                title: "Average Daily",
                value: points.isNotEmpty ? _currencyFormat.format(total / points.length) : "₱0",
                icon: LucideIcons.trendingUp,
                accentColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniStatPill(
                title: "Velocity",
                value: "${points.length} Days Tracked",
                icon: LucideIcons.calendar,
                accentColor: AppColors.accentBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Service Demand / Requests Compact View
  Widget _buildRequestsView() {
    final points = widget.transactions.chart;
    final total = widget.transactions.totalCount;

    return Column(
      key: const ValueKey('requests_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TOTAL SERVICE REQUESTS",
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$total Processed",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Civil Services",
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Compact Bar / Line Chart (120dp)
        SizedBox(
          height: 120,
          child: points.isEmpty
              ? _buildEmptyState("No transaction requests recorded")
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.spotIndex;
                            final date = (idx >= 0 && idx < points.length) ? points[idx].date : '';
                            return LineTooltipItem(
                              "$date\n${spot.y.toInt()} Requests",
                              GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 18,
                          interval: points.length > 5 ? (points.length / 3).floorToDouble() : 1,
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
                    lineBarsData: [
                      LineChartBarData(
                        spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.total.toDouble())).toList(),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: const Color(0xFF8B5CF6),
                        barWidth: 2.2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildMiniStatPill(
                title: "Daily Volume",
                value: points.isNotEmpty ? "${(total / points.length).toStringAsFixed(1)} / day" : "0",
                icon: LucideIcons.fileCheck,
                accentColor: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniStatPill(
                title: "Service Scope",
                value: "Barangay & LGU",
                icon: LucideIcons.building2,
                accentColor: AppColors.accentAmber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Demographic Census Compact View
  Widget _buildDemographicsView() {
    final points = widget.demographics.chart;
    final total = widget.demographics.totalCount;

    return Column(
      key: const ValueKey('demographics_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CENSUS POPULATION IN SCOPE",
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$total Residents",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Mapandan Pulse",
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 120,
          child: points.isEmpty
              ? _buildEmptyState("No registration velocity in this period")
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.spotIndex;
                            final date = (idx >= 0 && idx < points.length) ? points[idx].date : '';
                            return LineTooltipItem(
                              "$date\n+${spot.y.toInt()} New",
                              GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 18,
                          interval: points.length > 5 ? (points.length / 3).floorToDouble() : 1,
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
                    lineBarsData: [
                      LineChartBarData(
                        spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble())).toList(),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: const Color(0xFF3B82F6),
                        barWidth: 2.2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildMiniStatPill(
                title: "Realtime Sync",
                value: "Supabase Active",
                icon: LucideIcons.radio,
                accentColor: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniStatPill(
                title: "Coverage",
                value: "100% Jurisdictions",
                icon: LucideIcons.shieldCheck,
                accentColor: AppColors.accentGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 4. Reports & Incidents Compact View
  Widget _buildReportsView() {
    final list = widget.reports;

    return Column(
      key: const ValueKey('reports_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CIVIC INCIDENT LOGS",
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${list.length} Recent Issues",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Public Safety",
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (list.isEmpty)
          _buildEmptyState("No recent incident complaints filed")
        else
          ...list.take(3).map((r) {
            final category = (r is Map ? r['category'] : null) ?? "General Inquiry";
            final reporter = (r is Map ? r['reporterName'] : null) ?? "Resident";
            final date = (r is Map ? r['date'] : null) ?? "Recently";

            return Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.alertTriangle, size: 12, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Filed by $reporter • $date",
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMiniStatPill({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: accentColor),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          message,
          style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
