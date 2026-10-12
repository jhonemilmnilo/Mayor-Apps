import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header matching web: Intelligence & Fiscal Reports
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(LucideIcons.barChart3, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "INTELLIGENCE & FISCAL REPORTS",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Revenue trends, service demand analytics, and demographic intelligence",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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

          const SizedBox(height: 14),

          // 4 Segmented Tabs Controller
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSegmentTab(0, "TREASURY", LucideIcons.wallet, const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildSegmentTab(1, "REQUESTS", LucideIcons.fileText, const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                _buildSegmentTab(2, "CENSUS", LucideIcons.users, const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildSegmentTab(3, "REPORTS", LucideIcons.alertTriangle, const Color(0xFFF59E0B)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Active Tab View Content
          _buildActiveTabContent(),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(int index, String title, IconData icon, Color activeColor) {
    final isSelected = _activeTabIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  letterSpacing: 0.5,
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

  // 1. Treasury / Collections Ledger View
  Widget _buildTreasuryView() {
    final points = widget.revenue.chart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TOTAL REVENUE COLLECTED",
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                Text(
                  _currencyFormat.format(widget.revenue.totalAmount),
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF10B981)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Last 7 Days",
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF10B981)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: points.isEmpty
              ? _buildEmptyState("No revenue recorded in this period")
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: points.length > 5 ? (points.length / 3).floorToDouble() : 1,
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < points.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  points[idx].date,
                                  style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
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
                        color: const Color(0xFF10B981),
                        barWidth: 2.5,
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
      ],
    );
  }

  // 2. Service Demand / Daily Requests View
  Widget _buildRequestsView() {
    final points = widget.transactions.chart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TOTAL TRANSACTIONS PROCESSED",
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                Text(
                  "${widget.transactions.totalCount} Requests",
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF8B5CF6)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Daily Volume",
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF8B5CF6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: points.isEmpty
              ? _buildEmptyState("No transaction requests recorded")
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: points.length > 5 ? (points.length / 3).floorToDouble() : 1,
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < points.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  points[idx].date,
                                  style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
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
                        color: const Color(0xFF8B5CF6),
                        barWidth: 2.5,
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
      ],
    );
  }

  // 3. Demographic Census Intelligence View
  Widget _buildDemographicsView() {
    final points = widget.demographics.chart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "REGISTERED RESIDENTS IN SCOPE",
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                Text(
                  "${widget.demographics.totalCount} Individuals",
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF3B82F6)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Census Velocity",
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: points.isEmpty
              ? _buildEmptyState("No registration velocity in this period")
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: points.length > 5 ? (points.length / 3).floorToDouble() : 1,
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < points.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  points[idx].date,
                                  style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
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
                        color: const Color(0xFF3B82F6),
                        barWidth: 2.5,
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
      ],
    );
  }

  // 4. Citizen Incidents & Reports View
  Widget _buildReportsView() {
    final list = widget.reports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LATEST INCIDENT REPORTS",
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                Text(
                  "${list.length} Recent Issues",
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFFF59E0B)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Citizen Pulse",
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          _buildEmptyState("No recent incident complaints filed")
        else
          ...list.take(3).map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.alertTriangle, size: 14, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['category'] ?? "General Complaint",
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        Text(
                          "Reported by ${r['reporterName'] ?? 'Citizen'} • ${r['date'] ?? 'Recently'}",
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
