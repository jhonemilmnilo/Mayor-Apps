import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import 'resident_filter_modal.dart';
import 'residents_directory_modal.dart';

/// Interactive Resident Analytics Card matching Web dashboard parity 100%.
/// Clean, executive-grade minimal layout with blue curved line chart (#3B82F6),
/// timeline filter toolbar, sector demographics badge, and full-width "VIEW RESIDENTS DIRECTORY" button.
class DemographicCensusCard extends ConsumerStatefulWidget {
  final DemographicAnalytics demographics;

  const DemographicCensusCard({super.key, required this.demographics});

  @override
  ConsumerState<DemographicCensusCard> createState() =>
      _DemographicCensusCardState();
}

class _DemographicCensusCardState
    extends ConsumerState<DemographicCensusCard> {
  late ResidentFilterCriteria _filter;
  final DateFormat _displayDateFormat = DateFormat('MM/dd/yyyy');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  bool _isLoading = false;

  DemographicAnalytics? _filteredDemographics;

  final Map<String, Map<String, dynamic>> _sectorConfigs = {
    'ALL': {'label': 'All Citizens', 'color': Color(0xFF3B82F6)},
    'SENIOR': {'label': 'Senior Citizens', 'color': Color(0xFFF59E0B)},
    'PWD': {'label': 'Persons with Disability', 'color': Color(0xFF10B981)},
    'SOLO_PARENT': {'label': 'Solo Parents', 'color': Color(0xFFEC4899)},
    'FOUR_PS': {'label': '4Ps Beneficiaries', 'color': Color(0xFF8B5CF6)},
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = ResidentFilterCriteria(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      gender: 'ALL',
      civilStatus: 'ALL',
      sector: 'ALL',
      activePreset: '30D',
    );
  }

  Future<void> _handleApplyFilter(ResidentFilterCriteria newFilter) async {
    setState(() {
      _filter = newFilter;
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final currentBarangay = ref.read(selectedBarangayProvider);

      final formattedStart = _apiDateFormat.format(newFilter.startDate);
      final formattedEnd = _apiDateFormat.format(newFilter.endDate);

      final queryParams = <String, dynamic>{
        if (!newFilter.isAllTime) ...{
          "resFrom": formattedStart,
          "resTo": formattedEnd,
          "from": formattedStart,
          "to": formattedEnd,
          "startDate": formattedStart,
          "endDate": formattedEnd,
        },
        if (newFilter.isAllTime) ...{
          "resFrom": "2020-01-01",
          "resTo": _apiDateFormat.format(DateTime.now()),
        },
        if (newFilter.sector != 'ALL') "resSector": newFilter.sector,
        if (newFilter.gender != 'ALL') "resGender": newFilter.gender,
        if (newFilter.civilStatus != 'ALL') "resCivil": newFilter.civilStatus,
        if (currentBarangay.isNotEmpty) "barangay": currentBarangay,
      };

      final response = await apiClient.dio.get(
        AppConstants.dashboardEndpoint,
        queryParameters: queryParams,
      );

      if (response.data["success"] == true) {
        final data = response.data["data"] as Map<String, dynamic>? ?? {};
        final analytics = data['analytics'] as Map<String, dynamic>? ?? {};

        if (mounted) {
          setState(() {
            _filteredDemographics = DemographicAnalytics.fromJson(
              analytics['demographics'] ?? {},
            );
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("[RESIDENTS_FILTER_ERROR] $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDemographics =
        _filteredDemographics ?? widget.demographics;
    final points = activeDemographics.chart;

    final computedTotal = points.fold<int>(0, (sum, p) => sum + p.count);
    final total = activeDemographics.totalCount > 0
        ? activeDemographics.totalCount
        : computedTotal;

    final sectorConfig = _sectorConfigs[_filter.sector] ??
        _sectorConfigs['ALL']!;
    final themeColor = sectorConfig['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: AppColors.getCardShadow(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  LucideIcons.users,
                  size: 15,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RESIDENT ANALYTICS",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.getTextPrimary(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Approved onboarded and verified citizen demographics",
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

          const SizedBox(height: 8),

          // Subtitle Scope Info
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
              children: [
                const TextSpan(
                  text: "Analyzing ",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextSpan(
                  text: sectorConfig['label'],
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: _isLoading
                      ? " (Loading...)"
                      : " ($total registered residents)",
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Filter Toolbar Row matching Daily Requests & Payments layout
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date Range Button
                InkWell(
                  onTap: () {
                    ResidentFilterModal.show(
                      context,
                      currentFilter: _filter,
                      onApply: _handleApplyFilter,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceElevated(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.calendar,
                          size: 12,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _filter.isAllTime
                              ? "All-Time"
                              : _displayDateFormat.format(_filter.startDate),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        if (!_filter.isAllTime) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              "to",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.getTextSecondary(context),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const Icon(
                            LucideIcons.calendar,
                            size: 12,
                            color: Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _displayDateFormat.format(_filter.endDate),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Sector Dropdown / Trigger Badge
                InkWell(
                  onTap: () {
                    ResidentFilterModal.show(
                      context,
                      currentFilter: _filter,
                      onApply: _handleApplyFilter,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceElevated(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          sectorConfig['label'].toString().toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: themeColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 12,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sparkline Chart (140dp) with Area Gradient (Matching Daily Requests proportions)
          SizedBox(
            height: 140,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF3B82F6),
                    ),
                  )
                : points.isEmpty
                    ? Center(
                        child: Text(
                          "No resident registration activity in this period",
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 2,
                            getDrawingHorizontalLine: (val) => FlLine(
                              color: Colors.white.withValues(alpha: 0.05),
                              strokeWidth: 1,
                              dashArray: [3, 3],
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final idx = spot.spotIndex;
                                  final date = (idx >= 0 && idx < points.length)
                                      ? points[idx].date
                                      : '';
                                  return LineTooltipItem(
                                    "$date\n+${spot.y.toInt()} Registered",
                                    GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 20,
                                interval: points.length > 5
                                    ? (points.length / 3).floorToDouble()
                                    : 1,
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
                              spots: points
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => FlSpot(
                                      e.key.toDouble(),
                                      e.value.count.toDouble(),
                                    ),
                                  )
                                  .toList(),
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: const Color(0xFF3B82F6),
                              barWidth: 2.6,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.35),
                                    const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),

          const SizedBox(height: 14),

          // Bottom Action Button: VIEW RESIDENTS DIRECTORY (100% Matches Payments & Daily Requests)
          InkWell(
            onTap: () => ResidentsDirectoryModal.show(
              context,
              initialFilter: _filter,
              selectedBarangay: ref.read(selectedBarangayProvider),
              initialTotalCount: total,
            ),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.users,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "VIEW RESIDENTS DIRECTORY",
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
