import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/project_item_model.dart';
import 'project_details_bottom_sheet.dart';
import 'project_filter_modal.dart';

class ProjectsAuditModal extends ConsumerStatefulWidget {
  final ProjectFilterCriteria initialFilter;
  final String selectedBarangay;
  final int? initialTotalCount;
  final List<ProjectItemModel>? fallbackProjects;

  const ProjectsAuditModal({
    super.key,
    required this.initialFilter,
    required this.selectedBarangay,
    this.initialTotalCount,
    this.fallbackProjects,
  });

  static void show(
    BuildContext context, {
    required ProjectFilterCriteria initialFilter,
    required String selectedBarangay,
    int? initialTotalCount,
    List<ProjectItemModel>? fallbackProjects,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProjectsAuditModal(
        initialFilter: initialFilter,
        selectedBarangay: selectedBarangay,
        initialTotalCount: initialTotalCount,
        fallbackProjects: fallbackProjects,
      ),
    );
  }

  @override
  ConsumerState<ProjectsAuditModal> createState() => _ProjectsAuditModalState();
}

class _ProjectsAuditModalState extends ConsumerState<ProjectsAuditModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounceTimer;

  // Pagination & State
  static const int _pageSize = 15;
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  // Cancellation token
  CancelToken? _cancelToken;

  // Active filters
  late String _activeStatus;
  late String _activeCategory;
  String _searchQuery = "";

  // Data
  final List<ProjectItemModel> _projects = [];
  ProjectStats? _stats;
  int _totalCount = 0;

  static const List<Map<String, dynamic>> kProjectStatuses = [
    {'key': 'ALL', 'label': 'All Statuses', 'color': Color(0xFF8B5CF6)},
    {'key': 'Ongoing', 'label': 'Ongoing', 'color': Color(0xFF3B82F6)},
    {'key': 'Completed', 'label': 'Completed', 'color': Color(0xFF10B981)},
    {'key': 'Planned', 'label': 'Planned', 'color': Color(0xFFF59E0B)},
    {'key': 'On Hold', 'label': 'On Hold', 'color': Color(0xFFEF4444)},
  ];

  @override
  void initState() {
    super.initState();
    _activeStatus = widget.initialFilter.status;
    _activeCategory = widget.initialFilter.category;

    _scrollController.addListener(_onScroll);
    _loadInitialPage();
  }

  @override
  void dispose() {
    _cancelToken?.cancel("Modal closed");
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadNextPage();
      }
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _searchQuery = val.trim();
        });
        _resetAndReload();
      }
    });
  }

  Future<void> _resetAndReload() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      _errorMessage = null;
      _projects.clear();
    });
    await _fetchProjects(page: 1);
  }

  Future<void> _loadInitialPage() async {
    await _fetchProjects(page: 1);
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchProjects(page: _currentPage + 1);
  }

  Future<void> _fetchProjects({required int page}) async {
    try {
      final apiClient = ref.read(apiClientProvider);

      if (page == 1) {
        _cancelToken?.cancel("New search or filter request");
        _cancelToken = CancelToken();
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': _pageSize,
      };

      if (_activeStatus != 'ALL') {
        queryParams['status'] = _activeStatus;
      }

      if (_activeCategory != 'ALL') {
        queryParams['category'] = _activeCategory;
      }

      final barangay = widget.selectedBarangay;
      if (barangay.isNotEmpty &&
          barangay.toLowerCase() != 'all' &&
          barangay.toLowerCase() != 'mapandan') {
        queryParams['barangay'] = barangay;
      }

      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      final response = await apiClient.dio.get(
        AppConstants.projectsEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (response.data != null && response.data['success'] == true) {
        final parsed = PaginatedProjectsResponse.fromJson(response.data);

        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _hasMore = parsed.hasMore;
          _stats = parsed.stats;
          _totalCount = parsed.totalCount;

          if (page == 1) {
            _projects.clear();
          }
          _projects.addAll(parsed.projects);
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      } else {
        throw Exception(
          response.data?['error'] ?? "Failed to fetch municipal projects.",
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;
      if (page == 1 &&
          widget.fallbackProjects != null &&
          widget.fallbackProjects!.isNotEmpty) {
        _useFallbackData();
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage =
              e.response?.data?['error'] ??
              "Unable to connect to municipal projects server.";
        });
      }
    } catch (err) {
      if (!mounted) return;
      if (page == 1 &&
          widget.fallbackProjects != null &&
          widget.fallbackProjects!.isNotEmpty) {
        _useFallbackData();
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = err.toString();
        });
      }
    }
  }

  void _useFallbackData() {
    final list = widget.fallbackProjects ?? [];
    setState(() {
      _projects.clear();
      _projects.addAll(list);
      _totalCount = list.length;
      _hasMore = false;
      _isLoading = false;
      _isLoadingMore = false;
      _stats = ProjectStats(
        total: list.length,
        ongoing: list.where((p) => p.status.toLowerCase() == 'ongoing' || p.status.toLowerCase() == 'in_progress').length,
        completed: list.where((p) => p.status.toLowerCase() == 'completed').length,
        planned: list.where((p) => p.status.toLowerCase() == 'planned').length,
        onHold: list.where((p) => p.status.toLowerCase() == 'on hold' || p.status.toLowerCase() == 'suspended').length,
      );
    });
  }

  void _openFilterModal() {
    ProjectFilterModal.show(
      context,
      currentFilter: ProjectFilterCriteria(
        status: _activeStatus,
        category: _activeCategory,
      ),
      onApply: (newFilter) {
        setState(() {
          _activeStatus = newFilter.status;
          _activeCategory = newFilter.category;
        });
        _resetAndReload();
      },
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
    final isDark = AppColors.isDark(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          _buildHeader(),

          // 4 Executive KPI Metric Cards matching Web
          _buildKpiMetricsRow(),

          const SizedBox(height: 10),

          // Search & Quick Status Filter Toolbar
          _buildSearchAndFilterToolbar(),

          const SizedBox(height: 6),

          // Active Scope Badge
          _buildActiveScopeBadge(),

          const SizedBox(height: 8),

          // Main Paginated Projects List
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.hardHat,
                    size: 18,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "LGU PROJECTS",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                      Text(
                        _isLoading
                            ? "Connecting to municipal capital records..."
                            : "$_totalCount Registered Infrastructure Projects",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: AppColors.getTextSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                onPressed: _openFilterModal,
                icon: Stack(
                  children: [
                    const Icon(
                      LucideIcons.slidersHorizontal,
                      size: 19,
                      color: Color(0xFF8B5CF6),
                    ),
                    if (_activeStatus != 'ALL' || _activeCategory != 'ALL')
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                splashRadius: 20,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  LucideIcons.x,
                  size: 20,
                  color: AppColors.getTextSecondary(context),
                ),
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsRow() {
    final total = _stats?.total ?? widget.initialTotalCount ?? 0;
    final ongoing = _stats?.ongoing ?? 0;
    final completed = _stats?.completed ?? 0;
    final planned = _stats?.planned ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildKpiCard(
            title: "TOTAL PROJECTS",
            value: "$total",
            icon: LucideIcons.folderKanban,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "ONGOING",
            value: "$ongoing",
            icon: LucideIcons.clock,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "COMPLETED",
            value: "$completed",
            icon: LucideIcons.checkCircle2,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "PLANNED",
            value: "$planned",
            icon: LucideIcons.pauseCircle,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 105),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: isDark ? [] : AppColors.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextSecondary(context),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterToolbar() {
    final isDark = AppColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search Field
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.getBorder(context)),
              boxShadow: isDark ? [] : AppColors.getCardShadow(context),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(color: AppColors.getTextPrimary(context), fontSize: 12),
              decoration: InputDecoration(
                hintText: "Search by title, location, contractor...",
                hintStyle: GoogleFonts.inter(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 11.5,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 15,
                  color: Color(0xFF8B5CF6),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(LucideIcons.x, size: 14, color: AppColors.getTextSecondary(context)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged("");
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Horizontal Quick Status Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kProjectStatuses.map((opt) {
                final isSelected = _activeStatus.toLowerCase() == opt['key'].toLowerCase();
                final color = opt['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _activeStatus = opt['key'];
                      });
                      _resetAndReload();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: isDark ? 0.2 : 0.12)
                            : AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? color : AppColors.getBorder(context),
                        ),
                        boxShadow: (!isSelected && !isDark) ? AppColors.getCardShadow(context) : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? color : AppColors.getTextSecondary(context).withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            opt['label'],
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? Colors.white : color)
                                  : AppColors.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveScopeBadge() {
    final isDark = AppColors.isDark(context);
    final bgy = widget.selectedBarangay.isEmpty
        ? "Municipality-Wide"
        : widget.selectedBarangay;
    final sectorStr = _activeCategory == 'ALL'
        ? "All Sectors"
        : _activeCategory.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.getBorder(context).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 11,
                  color: Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 5),
                Text(
                  bgy,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  LucideIcons.tag,
                  size: 11,
                  color: AppColors.getTextSecondary(context),
                ),
                const SizedBox(width: 5),
                Text(
                  sectorStr,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
            SizedBox(height: 12),
            Text(
              "Loading infrastructure capital records...",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.red, size: 36),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _resetAndReload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(LucideIcons.refreshCw, size: 14),
                label: const Text("Retry Connection"),
              ),
            ],
          ),
        ),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.fileSearch,
              size: 40,
              color: AppColors.getTextSecondary(context),
            ),
            const SizedBox(height: 10),
            Text(
              "No municipal infrastructure projects found",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Try adjusting your search query or status filter.",
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _projects.length + (_hasMore ? 1 : 1),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == _projects.length) {
          if (_hasMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Loading next 15 records...",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  "— End of Municipal Projects Directory (${_projects.length} items) —",
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.getTextSecondary(context).withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          }
        }

        final item = _projects[index];
        return _buildProjectAuditCard(item);
      },
    );
  }

  Widget _buildProjectAuditCard(ProjectItemModel item) {
    final isDark = AppColors.isDark(context);
    final statusColor = _getStatusColor(item.status);
    final progressColor = _getProgressColor(item.progress);

    return InkWell(
      onTap: () => ProjectDetailsBottomSheet.show(context, item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: isDark ? [] : AppColors.getCardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Title & Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: isDark ? 0.3 : 0.25)),
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

            const SizedBox(height: 6),

            // Row 2: Category & Location
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    item.category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.mapPin, size: 10, color: AppColors.getTextSecondary(context)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          item.location,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextSecondary(context),
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

            if (item.budget != null && item.budget!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(LucideIcons.banknote, size: 11, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    item.budget!.startsWith("₱") ? item.budget! : "₱${item.budget}",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  if (item.contractor != null && item.contractor!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text("•", style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 10)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.contractor!,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: AppColors.getTextSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Row 3: Progress Bar matching Web
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 5,
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
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
                    fontSize: 10,
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
  }
}
