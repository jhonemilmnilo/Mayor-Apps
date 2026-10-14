import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/department_compliance_model.dart';
import '../providers/dashboard_provider.dart';
import 'all_departments_compliance_modal.dart';
import 'compliance_filter_modal.dart';

class DepartmentComplianceLeaderboardCard extends ConsumerStatefulWidget {
  final List<DepartmentComplianceModel> leaderboard;
  final int maxItems;

  const DepartmentComplianceLeaderboardCard({
    super.key,
    required this.leaderboard,
    this.maxItems = 5,
  });

  @override
  ConsumerState<DepartmentComplianceLeaderboardCard> createState() =>
      _DepartmentComplianceLeaderboardCardState();
}

class _DepartmentComplianceLeaderboardCardState
    extends ConsumerState<DepartmentComplianceLeaderboardCard> {
  late ComplianceFilterCriteria _filter;
  final DateFormat _displayDateFormat = DateFormat('MM/dd/yyyy');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  bool _isLoading = false;

  List<DepartmentComplianceModel>? _filteredLeaderboard;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = ComplianceFilterCriteria(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      activePreset: '30D',
    );
  }

  Future<List<DepartmentComplianceModel>> _fetchFilteredLeaderboard(
      ComplianceFilterCriteria newFilter) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final currentBarangay = ref.read(selectedBarangayProvider);

      final isAll = newFilter.activePreset == 'ALL';
      final formattedStart = _apiDateFormat.format(newFilter.startDate);
      final formattedEnd = _apiDateFormat.format(newFilter.endDate);

      final queryParams = <String, dynamic>{
        "artaFrom": isAll ? "ALL" : formattedStart,
        "artaTo": isAll ? "ALL" : formattedEnd,
        if (currentBarangay.isNotEmpty) "barangay": currentBarangay,
      };

      final response = await apiClient.dio.get(
        AppConstants.dashboardEndpoint,
        queryParameters: queryParams,
      );

      if (response.data["success"] == true) {
        final data = response.data["data"] as Map<String, dynamic>? ?? {};
        final list = data['departmentLeaderboard'] as List<dynamic>? ?? [];
        return list
            .map((item) => DepartmentComplianceModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint("[COMPLIANCE_FILTER_API_ERROR] $e");
    }
    return _filteredLeaderboard ?? widget.leaderboard;
  }

  Future<void> _handleApplyFilter(ComplianceFilterCriteria newFilter) async {
    setState(() {
      _filter = newFilter;
      _isLoading = true;
    });

    final updated = await _fetchFilteredLeaderboard(newFilter);

    if (mounted) {
      setState(() {
        _filteredLeaderboard = updated;
        _isLoading = false;
      });
    }
  }

  void _openDateFilterModal() {
    ComplianceFilterModal.show(
      context,
      currentFilter: _filter,
      onApply: _handleApplyFilter,
    );
  }

  void _openAllDepartmentsModal() {
    final currentList = _filteredLeaderboard ?? widget.leaderboard;

    AllDepartmentsComplianceModal.show(
      context,
      initialLeaderboard: currentList,
      initialFilter: _filter,
      onFetchFiltered: _fetchFilteredLeaderboard,
      onFilterApplied: (newFilter, updatedList) {
        if (mounted) {
          setState(() {
            _filter = newFilter;
            _filteredLeaderboard = updatedList;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentTeal = Color(0xFF14B8A6); // Teal 500

    final currentList = _filteredLeaderboard ?? widget.leaderboard;
    final totalCount = currentList.length;
    // Always restrict the card itself to exactly maxItems (5 items)
    final displayedList = currentList.take(widget.maxItems).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accentTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.balance_rounded,
                  color: accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DEPARTMENT COMPLIANCE",
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: accentTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "RA 11032 Anti-Red Tape Authority (ARTA) SLA",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Date Filter Bar (Self-contained in the section like Collections Ledger)
          InkWell(
            onTap: _openDateFilterModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentTeal.withValues(alpha: 0.25), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 14, color: accentTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _filter.activePreset == 'ALL'
                          ? "All Time Records"
                          : "${_displayDateFormat.format(_filter.startDate)} - ${_displayDateFormat.format(_filter.endDate)}",
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_filter.activePreset != null && _filter.activePreset != 'CUSTOM') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: accentTeal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        _filter.activePreset!,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: accentTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Leaderboard List or Loading
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: CircularProgressIndicator(
                  color: accentTeal,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (displayedList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 32,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No departmental compliance data recorded yet",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final dept = displayedList[index];
                final rank = index + 1;

                Color rankBadgeBg;
                Color rankTextColor;
                if (rank == 1) {
                  rankBadgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.2);
                  rankTextColor = const Color(0xFFF59E0B);
                } else if (rank == 2) {
                  rankBadgeBg = const Color(0xFF94A3B8).withValues(alpha: 0.2);
                  rankTextColor = const Color(0xFFE2E8F0);
                } else if (rank == 3) {
                  rankBadgeBg = const Color(0xFFB45309).withValues(alpha: 0.2);
                  rankTextColor = const Color(0xFFD97706);
                } else {
                  rankBadgeBg = Colors.white.withValues(alpha: 0.05);
                  rankTextColor = AppColors.textSecondary;
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank Badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: rankBadgeBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: rankTextColor.withValues(alpha: 0.4), width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "#$rank",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: rankTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Department Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    dept.officeName,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white12, width: 0.6),
                                  ),
                                  child: Text(
                                    dept.officeCode,
                                    style: GoogleFonts.inter(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "Done: ${dept.completed}",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Pending: ${dept.pending}",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (dept.overdue > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    "Overdue: ${dept.overdue}",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFF43F5E),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Rate & Status Pill
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${dept.complianceRate.toStringAsFixed(dept.complianceRate.truncateToDouble() == dept.complianceRate ? 0 : 1)}%",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: dept.statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: dept.statusColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              dept.statusLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: dept.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          // "VIEW ALL DEPARTMENTS" Modal Opener Button
          const SizedBox(height: 12),
          InkWell(
            onTap: _openAllDepartmentsModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: accentTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentTeal.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "VIEW ALL DEPARTMENTS ($totalCount)",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: accentTeal,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.arrowUpRight,
                    color: accentTeal,
                    size: 14,
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
