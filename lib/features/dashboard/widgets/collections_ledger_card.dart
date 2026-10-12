import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import 'service_legends_modal.dart';
import 'payments_ledger_modal.dart';
import 'collections_filter_modal.dart';

class CollectionsLedgerCard extends ConsumerStatefulWidget {
  final RevenueAnalytics revenue;
  final List<dynamic> payments;

  const CollectionsLedgerCard({
    super.key,
    required this.revenue,
    this.payments = const [],
  });

  @override
  ConsumerState<CollectionsLedgerCard> createState() => _CollectionsLedgerCardState();
}

class _CollectionsLedgerCardState extends ConsumerState<CollectionsLedgerCard> {
  late CollectionsFilterCriteria _filter;
  final DateFormat _displayDateFormat = DateFormat('MM/dd/yyyy');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  bool _isLoading = false;

  // Holds server-fetched filtered collections if available
  RevenueAnalytics? _filteredRevenue;
  List<dynamic>? _filteredPaymentsList;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = CollectionsFilterCriteria(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      paymentMethod: 'ALL',
      activePreset: '30D',
    );
  }

  Future<void> _handleApplyFilter(CollectionsFilterCriteria newFilter) async {
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
        "payFrom": formattedStart,
        "payTo": formattedEnd,
        "from": formattedStart,
        "to": formattedEnd,
        "startDate": formattedStart,
        "endDate": formattedEnd,
        if (newFilter.paymentMethod != 'ALL') "payMethod": newFilter.paymentMethod,
        if (currentBarangay.isNotEmpty) "barangay": currentBarangay,
      };

      final response = await apiClient.dio.get(
        AppConstants.dashboardEndpoint,
        queryParameters: queryParams,
      );

      if (response.data["success"] == true) {
        final data = response.data["data"] as Map<String, dynamic>? ?? {};
        final analytics = data['analytics'] as Map<String, dynamic>? ?? {};
        final recentFeeds = data['recentFeeds'] as Map<String, dynamic>? ?? {};

        if (mounted) {
          setState(() {
            _filteredRevenue = RevenueAnalytics.fromJson(analytics['revenue'] ?? {});
            _filteredPaymentsList = recentFeeds['payments'] as List? ?? [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("[COLLECTIONS_FILTER_API_ERROR] $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _parseFlexibleDate(String raw) {
    if (raw.isEmpty) return null;
    DateTime? parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;

    final currentYear = DateTime.now().year;
    final formats = [
      'MMM d, yyyy',
      'MMM dd, yyyy',
      'MMM d',
      'MMM dd',
      'MM/dd/yyyy',
      'MM-dd-yyyy',
      'MM/dd',
      'yyyy/MM/dd',
    ];

    for (var f in formats) {
      try {
        final d = DateFormat(f).parse(raw);
        if (d.year == 1970) {
          return DateTime(currentYear, d.month, d.day);
        }
        return d;
      } catch (_) {}
    }
    return null;
  }

  Color _getServiceColor(String serviceKey) {
    final normalized = serviceKey.toUpperCase().replaceAll(' ', '_');
    for (var cfg in kMunicipalServices) {
      if (normalized.contains(cfg.key) || cfg.key.contains(normalized)) {
        return cfg.color;
      }
    }
    return const Color(0xFF10B981); // Default Emerald
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    final activeRevenue = _filteredRevenue ?? widget.revenue;
    final activePayments = _filteredPaymentsList ?? widget.payments;

    final startNormalized = DateTime(_filter.startDate.year, _filter.startDate.month, _filter.startDate.day);
    final endNormalized = DateTime(_filter.endDate.year, _filter.endDate.month, _filter.endDate.day);
    final totalDays = (endNormalized.difference(startNormalized).inDays + 1).clamp(1, 400);

    // Build timeline daily dates
    final List<DateTime> timelineDates = [];
    final labelFormat = DateFormat('MMM d');
    for (int i = 0; i < totalDays; i++) {
      timelineDates.add(startNormalized.add(Duration(days: i)));
    }

    // Map service category -> (dateKey -> amount)
    final Map<String, Map<String, double>> serviceDailyMap = {};
    double totalAggregated = 0.0;

    // 1. Gather points directly from activeRevenue.chart categories (Server calculated)
    if (activeRevenue.chart.isNotEmpty) {
      for (var p in activeRevenue.chart) {
        final parsed = _parseFlexibleDate(p.date);
        if (parsed != null) {
          final dateKey = DateFormat('yyyy-MM-dd').format(parsed);

          if ((parsed.isAfter(startNormalized) || parsed.isAtSameMomentAs(startNormalized)) &&
              (parsed.isBefore(endNormalized.add(const Duration(days: 1))))) {
            totalAggregated += p.total;

            if (p.categories.isNotEmpty) {
              p.categories.forEach((catKey, catAmt) {
                if (catAmt > 0) {
                  serviceDailyMap.putIfAbsent(catKey, () => {});
                  serviceDailyMap[catKey]![dateKey] = (serviceDailyMap[catKey]![dateKey] ?? 0.0) + catAmt;
                }
              });
            } else if (p.total > 0) {
              serviceDailyMap.putIfAbsent('COLLECTIONS', () => {});
              serviceDailyMap['COLLECTIONS']![dateKey] = (serviceDailyMap['COLLECTIONS']![dateKey] ?? 0.0) + p.total;
            }
          }
        }
      }
    }

    // 2. Also incorporate activePayments if serviceDailyMap is still empty
    if (serviceDailyMap.isEmpty && activePayments.isNotEmpty) {
      for (var pay in activePayments) {
        if (pay is Map<String, dynamic>) {
          final rawDate = pay['createdAt'] ?? pay['date'];
          final amount = (pay['amount'] as num?)?.toDouble() ?? 0.0;
          final serviceType = (pay['serviceType'] ?? pay['category'] ?? pay['purpose'] ?? 'COLLECTIONS').toString();

          if (rawDate != null && amount > 0) {
            final parsed = _parseFlexibleDate(rawDate.toString());
            if (parsed != null) {
              final dateKey = DateFormat('yyyy-MM-dd').format(parsed);

              if ((parsed.isAfter(startNormalized) || parsed.isAtSameMomentAs(startNormalized)) &&
                  (parsed.isBefore(endNormalized.add(const Duration(days: 1))))) {
                serviceDailyMap.putIfAbsent(serviceType, () => {});
                serviceDailyMap[serviceType]![dateKey] = (serviceDailyMap[serviceType]![dateKey] ?? 0.0) + amount;
              }
            }
          }
        }
      }
    }

    // 3. Ensure totalAggregated is accurate matching server
    if (activeRevenue.totalAmount > 0) {
      totalAggregated = activeRevenue.totalAmount;
    }

    // Compute dynamic Max Y
    double maxY = 1000.0;
    serviceDailyMap.forEach((_, dateAmounts) {
      for (var amt in dateAmounts.values) {
        if (amt > maxY) maxY = amt;
      }
    });
    maxY = (maxY * 1.3).clamp(1000.0, double.infinity);

    // Build Multi-Line LineChartBarData list
    final List<LineChartBarData> lineBars = [];
    if (serviceDailyMap.isEmpty) {
      // Default baseline line
      lineBars.add(
        LineChartBarData(
          spots: List.generate(totalDays, (idx) => FlSpot(idx.toDouble(), 0.0)),
          isCurved: true,
          color: const Color(0xFF10B981),
          barWidth: 2.2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 2.5,
              color: Colors.white,
              strokeWidth: 1.2,
              strokeColor: const Color(0xFF10B981),
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    } else {
      serviceDailyMap.forEach((serviceKey, dateAmounts) {
        final serviceColor = _getServiceColor(serviceKey);
        final spots = <FlSpot>[];

        for (int i = 0; i < totalDays; i++) {
          final dateKey = DateFormat('yyyy-MM-dd').format(timelineDates[i]);
          final amount = dateAmounts[dateKey] ?? 0.0;
          spots.add(FlSpot(i.toDouble(), amount));
        }

        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: serviceColor,
            barWidth: 2.4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // If it's a peak, draw a bigger glowing circle
                final isPeak = spot.y > 0;
                return FlDotCirclePainter(
                  radius: isPeak ? 3.5 : 2.0,
                  color: isPeak ? Colors.white : serviceColor.withValues(alpha: 0.4),
                  strokeWidth: isPeak ? 2.0 : 1.0,
                  strokeColor: serviceColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: spots.any((s) => s.y > 0),
              color: serviceColor.withValues(alpha: 0.06),
            ),
          ),
        );
      });
    }

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
          // Header Row: 📈 COLLECTIONS LEDGER + [FILTER] + [LEGEND]
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
              Row(
                children: [
                  // Filter Trigger Button
                  InkWell(
                    onTap: () {
                      CollectionsFilterModal.show(
                        context,
                        currentFilter: _filter,
                        onApply: _handleApplyFilter,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.filter, size: 11.5, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            "FILTER",
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Legend Trigger Button
                  InkWell(
                    onTap: () => ServiceLegendsModal.show(
                      context,
                      payments: activePayments,
                      totalRevenue: totalAggregated,
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
                          const Icon(LucideIcons.tags, size: 11.5, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
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
            ],
          ),

          const SizedBox(height: 6),

          // Total Revenue Subtitle matching Web: "Total Revenue: ₱93,900.54"
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              children: [
                const TextSpan(
                  text: "Total Revenue: ",
                  style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
                TextSpan(
                  text: _isLoading ? "Calculating..." : currencyFormat.format(totalAggregated),
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          // Active Filter Badge Bar Matching Web: 09/01/2026 to 09/30/2026 + ALL METHODS...
          InkWell(
            onTap: () {
              CollectionsFilterModal.show(
                context,
                currentFilter: _filter,
                onApply: _handleApplyFilter,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    "${_displayDateFormat.format(_filter.startDate)} to ${_displayDateFormat.format(_filter.endDate)}",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 12, color: AppColors.border),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _filter.paymentMethod == 'ALL' ? "ALL METHODS..." : _filter.paymentMethod,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(LucideIcons.chevronDown, size: 12, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 125dp FlChart Multi-Line View or In-Card Loading
          SizedBox(
            height: 125,
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Fetching revenue breakdown...",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
                              final dateStr = (idx >= 0 && idx < timelineDates.length)
                                  ? labelFormat.format(timelineDates[idx])
                                  : '';
                              return LineTooltipItem(
                                "$dateStr\n${currencyFormat.format(spot.y)}",
                                GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
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
                                return Text("₱0",
                                    style: GoogleFonts.inter(fontSize: 8, color: AppColors.textSecondary));
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
                            reservedSize: 20,
                            interval: 1,
                            getTitlesWidget: (val, _) {
                              final idx = val.toInt();
                              final total = timelineDates.length;
                              if (total == 0) return const SizedBox.shrink();

                              bool shouldShow = false;
                              if (total <= 7) {
                                shouldShow = true;
                              } else {
                                final step = (total - 1) / 4.0;
                                final samples = [
                                  0,
                                  (step * 1).round(),
                                  (step * 2).round(),
                                  (step * 3).round(),
                                  total - 1,
                                ];
                                shouldShow = samples.contains(idx);
                              }

                              if (shouldShow && idx >= 0 && idx < total) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    labelFormat.format(timelineDates[idx]),
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
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
                      lineBarsData: lineBars,
                    ),
                  ),
          ),

          const SizedBox(height: 14),

          // Bottom Action Button: GO TO PAYMENTS LEDGER
          InkWell(
            onTap: () => PaymentsLedgerModal.show(
              context,
              payments: activePayments,
              totalRevenue: totalAggregated,
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
