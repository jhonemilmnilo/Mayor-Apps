import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'citizen_report_filter_modal.dart';
import 'citizen_reports_modal.dart';

/// Interactive Citizen Reports Overview Card matching Web ReportsOverviewCard.tsx 100%.
/// Displays top 5 recent community incident reports with a compact, ultra-clean layout,
/// Collections-Ledger style date range filter bar with modal trigger, and full-width
/// "VIEW ALL CITIZEN REPORTS" action button in vivid Amber.
class CivicReportsCard extends ConsumerStatefulWidget {
  final List<dynamic> reports;

  const CivicReportsCard({super.key, required this.reports});

  @override
  ConsumerState<CivicReportsCard> createState() => _CivicReportsCardState();
}

class _CivicReportsCardState extends ConsumerState<CivicReportsCard> {
  CitizenReportFilterCriteria _filter = const CitizenReportFilterCriteria();
  bool _isLoading = false;

  List<dynamic>? _filteredReports;
  int? _totalCount;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleApplyFilter(CitizenReportFilterCriteria newFilter) async {
    setState(() {
      _filter = newFilter;
      _isLoading = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final currentBarangay = ref.read(selectedBarangayProvider);

      final queryParams = <String, dynamic>{
        'page': 1,
        'limit': 3,
      };

      if (newFilter.status != 'ALL') {
        queryParams['status'] = newFilter.status;
      }

      if (newFilter.category != 'ALL') {
        queryParams['category'] = newFilter.category;
      }

      if (currentBarangay.isNotEmpty &&
          currentBarangay.toLowerCase() != 'all' &&
          currentBarangay.toLowerCase() != 'mapandan') {
        queryParams['barangay'] = currentBarangay;
      }

      final response = await apiClient.dio.get(
        AppConstants.reportsEndpoint,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['success'] == true) {
        final reports = response.data['reports'] as List<dynamic>? ?? [];
        final total = (response.data['totalCount'] as num?)?.toInt() ?? reports.length;

        if (mounted) {
          setState(() {
            _filteredReports = reports;
            _totalCount = total;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("[CITIZEN_REPORTS_CARD_FILTER_ERROR] $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openFilterModal() {
    CitizenReportFilterModal.show(
      context,
      currentFilter: _filter,
      onApply: _handleApplyFilter,
    );
  }

  String _formatTimeAgo(dynamic rawDate) {
    if (rawDate == null) return "Recently";
    DateTime? date;
    if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate);
    }
    if (date == null) return rawDate.toString();

    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return DateFormat('MMM d').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "COMPLETED":
        return const Color(0xFF10B981);
      case "REJECTED":
        return const Color(0xFFEF4444);
      case "IN_PROGRESS":
        return const Color(0xFF0EA5E9);
      case "SEEN":
        return const Color(0xFF3B82F6);
      case "PENDING":
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeReports = _filteredReports ?? widget.reports;
    final totalReportsTracked = _totalCount ?? activeReports.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: AppColors.getCardShadow(context),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Left Icon + Title + Subtitle (Right icon removed)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  LucideIcons.alertTriangle,
                  size: 15,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CITIZEN REPORTS OVERVIEW",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.getTextPrimary(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "3 most recent community reports",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Active Filter Pill Bar (strictly Status & Category, NO date range)
          GestureDetector(
            onTap: _openFilterModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _filter.isFiltered
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                    : AppColors.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _filter.isFiltered
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.slidersHorizontal,
                    size: 13,
                    color: _filter.isFiltered ? const Color(0xFFF59E0B) : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _filter.isFiltered
                          ? "${_filter.category != 'ALL' ? _filter.category.toUpperCase() : 'ALL CATEGORIES'} • ${_filter.status != 'ALL' ? _filter.status.toUpperCase() : 'ALL STATUSES'}"
                          : "ALL STATUSES • ALL CATEGORIES",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: _filter.isFiltered ? const Color(0xFFF59E0B) : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_filter.isFiltered)
                    GestureDetector(
                      onTap: () {
                        _handleApplyFilter(const CitizenReportFilterCriteria());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    )
                  else
                    const Icon(
                      LucideIcons.chevronDown,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Incident List Stream
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            )
          else if (activeReports.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.checkCircle2,
                      size: 26,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "No community incident grievances found",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...activeReports.take(3).map((r) {
              final category = (r is Map ? r['category'] : null)?.toString() ?? "General Grievance";
              final reporter = (r is Map
                      ? (r['reporterName'] ?? r['user']?['name'])
                      : null)?.toString() ??
                  "Citizen Resident";
              final desc = (r is Map ? r['description'] : null)?.toString() ?? "";
              final rawDate = r is Map ? (r['createdAt'] ?? r['date']) : null;
              final dateStr = _formatTimeAgo(rawDate);
              final status = (r is Map ? r['status'] : null)?.toString().toUpperCase() ?? "PENDING";
              final barangay = (r is Map
                      ? (r['barangayName'] ?? r['barangay']?['name'])
                      : null)?.toString() ??
                  "Mapandan";

              final statusColor = _getStatusColor(status);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceElevated(context),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Reporter Name + Date beside it + Status badge on the right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  reporter,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "• $dateStr",
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Category Pill & Barangay (NO image icon or image count)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 10,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  barangay,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        desc,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            }),

          const SizedBox(height: 6),

          // Bottom Action Button: VIEW ALL CITIZEN REPORTS
          InkWell(
            onTap: () => CitizenReportsModal.show(
              context,
              initialFilter: _filter,
              selectedBarangay: ref.read(selectedBarangayProvider),
              initialTotalCount: totalReportsTracked,
              fallbackReports: activeReports,
            ),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.arrowRight,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "VIEW ALL CITIZEN REPORTS",
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
