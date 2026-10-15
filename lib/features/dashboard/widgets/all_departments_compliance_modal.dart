import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../models/department_compliance_model.dart';
import 'compliance_filter_modal.dart';

class AllDepartmentsComplianceModal extends StatefulWidget {
  final List<DepartmentComplianceModel> initialLeaderboard;
  final ComplianceFilterCriteria initialFilter;
  final Function(ComplianceFilterCriteria newFilter, List<DepartmentComplianceModel> updatedList)? onFilterApplied;
  final Future<List<DepartmentComplianceModel>> Function(ComplianceFilterCriteria filter) onFetchFiltered;

  const AllDepartmentsComplianceModal({
    super.key,
    required this.initialLeaderboard,
    required this.initialFilter,
    required this.onFetchFiltered,
    this.onFilterApplied,
  });

  static void show(
    BuildContext context, {
    required List<DepartmentComplianceModel> initialLeaderboard,
    required ComplianceFilterCriteria initialFilter,
    required Future<List<DepartmentComplianceModel>> Function(ComplianceFilterCriteria filter) onFetchFiltered,
    Function(ComplianceFilterCriteria newFilter, List<DepartmentComplianceModel> updatedList)? onFilterApplied,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AllDepartmentsComplianceModal(
        initialLeaderboard: initialLeaderboard,
        initialFilter: initialFilter,
        onFetchFiltered: onFetchFiltered,
        onFilterApplied: onFilterApplied,
      ),
    );
  }

  @override
  State<AllDepartmentsComplianceModal> createState() => _AllDepartmentsComplianceModalState();
}

class _AllDepartmentsComplianceModalState extends State<AllDepartmentsComplianceModal> {
  late ComplianceFilterCriteria _currentFilter;
  late List<DepartmentComplianceModel> _leaderboard;
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  bool _isLoading = false;
  String _searchQuery = "";

  static const Color _accentTeal = Color(0xFF14B8A6);

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _leaderboard = List.from(widget.initialLeaderboard);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterModal() async {
    ComplianceFilterModal.show(
      context,
      currentFilter: _currentFilter,
      onApply: (newFilter) async {
        setState(() {
          _currentFilter = newFilter;
          _isLoading = true;
        });

        try {
          final updated = await widget.onFetchFiltered(newFilter);
          if (mounted) {
            setState(() {
              _leaderboard = updated;
              _isLoading = false;
            });
            widget.onFilterApplied?.call(newFilter, updated);
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
    );
  }

  List<DepartmentComplianceModel> get _filteredList {
    if (_searchQuery.trim().isEmpty) return _leaderboard;
    final q = _searchQuery.toLowerCase();
    return _leaderboard.where((d) {
      return d.officeName.toLowerCase().contains(q) ||
          d.officeCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredList;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.isDark(context) ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accentTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.balance_rounded, size: 18, color: _accentTeal),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ALL DEPARTMENTS COMPLIANCE",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.2,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        Text(
                          "Statutory ARTA SLA Leaderboard",
                          style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.getTextSecondary(context)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, size: 20, color: AppColors.getTextSecondary(context)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Divider(color: AppColors.getBorder(context), height: 1),

          // Date Filter Toolbar & Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                // Date Range Button (Click opens Date Picker & Presets Modal)
                InkWell(
                  onTap: _openFilterModal,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentTeal.withValues(alpha: 0.35)),
                      boxShadow: AppColors.getCardShadow(context),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 14, color: _accentTeal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentFilter.activePreset == 'ALL'
                                ? "All Time Records"
                                : "${_dateFormat.format(_currentFilter.startDate)}  —  ${_dateFormat.format(_currentFilter.endDate)}",
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                        ),
                        if (_currentFilter.activePreset != null && _currentFilter.activePreset != 'CUSTOM') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accentTeal.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _currentFilter.activePreset!,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: _accentTeal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Icon(LucideIcons.chevronDown, size: 14, color: AppColors.getTextSecondary(context)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.getTextPrimary(context)),
                  decoration: InputDecoration(
                    hintText: "Search department or code...",
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.getTextSecondary(context)),
                    prefixIcon: Icon(LucideIcons.search, size: 14, color: AppColors.getTextSecondary(context)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(LucideIcons.x, size: 14, color: AppColors.getTextSecondary(context)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.getSurface(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.getBorder(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.getBorder(context)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _accentTeal, width: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Department List or Loading / Empty View
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _accentTeal,
                      strokeWidth: 2.5,
                    ),
                  )
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 36, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? "No department matching '$_searchQuery'"
                                  : "No compliance records for this timeline",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final dept = list[index];
                          final rank = index + 1;
                          final isDark = AppColors.isDark(context);

                          Color rankBadgeBg;
                          Color rankTextColor;
                          if (rank == 1) {
                            rankBadgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.2);
                            rankTextColor = const Color(0xFFF59E0B);
                          } else if (rank == 2) {
                            rankBadgeBg = const Color(0xFF94A3B8).withValues(alpha: 0.2);
                            rankTextColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569);
                          } else if (rank == 3) {
                            rankBadgeBg = const Color(0xFFB45309).withValues(alpha: 0.2);
                            rankTextColor = const Color(0xFFD97706);
                          } else {
                            rankBadgeBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04);
                            rankTextColor = AppColors.getTextSecondary(context);
                          }

                          return Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: AppColors.getSurface(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.getBorder(context),
                                width: 1,
                              ),
                              boxShadow: isDark ? [] : AppColors.getCardShadow(context),
                            ),
                            child: Row(
                              children: [
                                // Rank Badge
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: rankBadgeBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: rankTextColor.withValues(alpha: 0.4), width: 1),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "#$rank",
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
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
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.getTextPrimary(context),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppColors.getBorder(context), width: 0.6),
                                            ),
                                            child: Text(
                                              dept.officeCode,
                                              style: GoogleFonts.inter(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.getTextSecondary(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Text(
                                            "Done: ${dept.completed}",
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.getTextSecondary(context),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Pending: ${dept.pending}",
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.getTextSecondary(context),
                                            ),
                                          ),
                                          if (dept.overdue > 0) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              "Overdue: ${dept.overdue}",
                                              style: GoogleFonts.inter(
                                                fontSize: 10.5,
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
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.getTextPrimary(context),
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
          ),
        ],
      ),
    );
  }
}
