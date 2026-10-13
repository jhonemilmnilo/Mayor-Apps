import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/project_item_model.dart';
import '../providers/dashboard_provider.dart';
import 'project_details_bottom_sheet.dart';
import 'project_filter_modal.dart';
import 'projects_audit_modal.dart';

/// Interactive LGU Projects Overview Card matching Web LGUProjectsCard.tsx 100%.
/// Displays top 3 recent municipal capital infrastructure projects, color-tiered progress bars,
/// Collections-Ledger style date range filter bar with modal trigger, and full-width
/// "VIEW ALL PROJECTS" action button in vivid Purple.
class ProjectsInfrastructureCard extends ConsumerStatefulWidget {
  final List<ProjectItemModel> projects;

  const ProjectsInfrastructureCard({super.key, required this.projects});

  @override
  ConsumerState<ProjectsInfrastructureCard> createState() =>
      _ProjectsInfrastructureCardState();
}

class _ProjectsInfrastructureCardState
    extends ConsumerState<ProjectsInfrastructureCard> {
  late ProjectFilterCriteria _filter;
  final DateFormat _displayDateFormat = DateFormat('MM/dd/yyyy');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  bool _isLoading = false;

  List<ProjectItemModel>? _filteredProjects;
  int? _totalCount;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = ProjectFilterCriteria(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      status: 'ALL',
      category: 'ALL',
      activePreset: 'ALL',
    );
  }

  Future<void> _handleApplyFilter(ProjectFilterCriteria newFilter) async {
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

      if (!newFilter.isAllTime) {
        queryParams['from'] = _apiDateFormat.format(newFilter.startDate);
        queryParams['to'] = _apiDateFormat.format(newFilter.endDate);
      }

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
        AppConstants.projectsEndpoint,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['success'] == true) {
        final parsed = PaginatedProjectsResponse.fromJson(response.data);

        if (mounted) {
          setState(() {
            _filteredProjects = parsed.projects;
            _totalCount = parsed.totalCount;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("[PROJECTS_CARD_FILTER_ERROR] $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openFilterModal() {
    ProjectFilterModal.show(
      context,
      currentFilter: _filter,
      onApply: _handleApplyFilter,
    );
  }

  Color _getStatusColor(String status) {
    final st = status.toLowerCase();
    if (st.contains('completed')) return const Color(0xFF10B981);
    if (st.contains('ongoing') || st.contains('progress')) return const Color(0xFF3B82F6);
    if (st.contains('planned') || st.contains('planning')) return const Color(0xFFF59E0B);
    if (st.contains('hold') || st.contains('suspended')) return const Color(0xFFEF4444);
    return const Color(0xFF8B5CF6);
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return const Color(0xFF10B981);
    if (progress >= 25) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final activeProjects = _filteredProjects ?? widget.projects;
    final totalTracked = _totalCount ?? activeProjects.length;

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
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  LucideIcons.hardHat,
                  size: 15,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LGU PROJECTS",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "$totalTracked active infrastructure projects",
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

          // Active Date Range Filter Bar (Exact Match with Collections Ledger & Citizen Reports)
          InkWell(
            onTap: _openFilterModal,
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
                  const Icon(
                    LucideIcons.calendar,
                    size: 12,
                    color: Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _filter.isAllTime
                        ? "ALL TIME HISTORICAL"
                        : "${_displayDateFormat.format(_filter.startDate)} to ${_displayDateFormat.format(_filter.endDate)}",
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
                      _filter.category != 'ALL'
                          ? _filter.category.toUpperCase()
                          : (_filter.status != 'ALL'
                              ? _filter.status.toUpperCase()
                              : "ALL CATEGORIES & STATUSES..."),
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // List of Display Projects (Top 3)
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
            )
          else if (activeProjects.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.hardHat,
                      size: 26,
                      color: Color(0xFF8B5CF6),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "No active infrastructure projects found",
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
            ...activeProjects.take(3).map((item) {
              final statusColor = _getStatusColor(item.status);
              final progressColor = _getProgressColor(item.progress);

              return InkWell(
                onTap: () => ProjectDetailsBottomSheet.show(context, item),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Title + Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              item.status,
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

                      // Second Row: Location & Category with MapPin
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 10,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              "${item.location} · ${item.category}",
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

                      const SizedBox(height: 7),

                      // Third Row: Progress Bar matching Web
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                height: 4.5,
                                color: Colors.white.withValues(alpha: 0.08),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: (item.progress / 100).clamp(0.0, 1.0),
                                  child: Container(color: progressColor),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${item.progress.toInt()}%",
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: progressColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 6),

          // Bottom Action Button: VIEW ALL PROJECTS (Matching Web)
          InkWell(
            onTap: () => ProjectsAuditModal.show(
              context,
              initialFilter: _filter,
              selectedBarangay: ref.read(selectedBarangayProvider),
              initialTotalCount: totalTracked,
              fallbackProjects: activeProjects,
            ),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
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
                    "VIEW ALL PROJECTS",
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
