import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/citizen_report_model.dart';
import 'citizen_report_filter_modal.dart';

class CitizenReportsModal extends ConsumerStatefulWidget {
  final CitizenReportFilterCriteria initialFilter;
  final String selectedBarangay;
  final int? initialTotalCount;
  final List<dynamic>? fallbackReports;

  const CitizenReportsModal({
    super.key,
    required this.initialFilter,
    required this.selectedBarangay,
    this.initialTotalCount,
    this.fallbackReports,
  });

  static void show(
    BuildContext context, {
    required CitizenReportFilterCriteria initialFilter,
    required String selectedBarangay,
    int? initialTotalCount,
    List<dynamic>? fallbackReports,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CitizenReportsModal(
        initialFilter: initialFilter,
        selectedBarangay: selectedBarangay,
        initialTotalCount: initialTotalCount,
        fallbackReports: fallbackReports,
      ),
    );
  }

  @override
  ConsumerState<CitizenReportsModal> createState() =>
      _CitizenReportsModalState();
}

class _CitizenReportsModalState extends ConsumerState<CitizenReportsModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _displayDateFormat = DateFormat('MMM d, yyyy • h:mm a');

  Timer? _debounceTimer;

  // Pagination & State
  static const int _pageSize = 15;
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  // Cancellation token for active queries
  CancelToken? _cancelToken;

  // Active filters
  late String _activeStatus;
  late String _activeCategory;
  String _searchQuery = "";

  // Data
  final List<CitizenReportItem> _reports = [];
  CitizenReportStats? _stats;
  int _totalCount = 0;

  static const List<Map<String, dynamic>> kReportStatuses = [
    {'key': 'ALL', 'label': 'All Statuses', 'color': Color(0xFF8B5CF6)},
    {'key': 'PENDING', 'label': 'PENDING', 'color': Color(0xFFF59E0B)},
    {'key': 'SEEN', 'label': 'SEEN', 'color': Color(0xFF3B82F6)},
    {'key': 'IN_PROGRESS', 'label': 'IN PROGRESS', 'color': Color(0xFF0EA5E9)},
    {'key': 'COMPLETED', 'label': 'COMPLETED', 'color': Color(0xFF10B981)},
    {'key': 'REJECTED', 'label': 'REJECTED', 'color': Color(0xFFEF4444)},
  ];

  @override
  void initState() {
    super.initState();
    final rawStatus = widget.initialFilter.status.toUpperCase();
    _activeStatus = rawStatus.isEmpty ? 'ALL' : rawStatus;
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
      _reports.clear();
    });
    await _fetchReports(page: 1);
  }

  Future<void> _loadInitialPage() async {
    await _fetchReports(page: 1);
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchReports(page: _currentPage + 1);
  }

  Future<void> _fetchReports({required int page}) async {
    try {
      final apiClient = ref.read(apiClientProvider);

      if (page == 1) {
        _cancelToken?.cancel("New search or filter report request");
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
        AppConstants.reportsEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (response.data != null && response.data['success'] == true) {
        final parsed = PaginatedCitizenReportsResponse.fromJson(response.data);

        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _hasMore = parsed.hasMore;
          _stats = parsed.stats;
          _totalCount = parsed.totalCount;

          if (page == 1) {
            _reports.clear();
          }
          _reports.addAll(parsed.reports);
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      } else {
        throw Exception(
          response.data?['error'] ?? "Failed to fetch citizen incident reports.",
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;
      if (page == 1 &&
          widget.fallbackReports != null &&
          widget.fallbackReports!.isNotEmpty) {
        _useFallbackData();
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage =
              e.response?.data?['error'] ??
              "Unable to connect to municipal citizen reports server.";
        });
      }
    } catch (err) {
      if (!mounted) return;
      if (page == 1 &&
          widget.fallbackReports != null &&
          widget.fallbackReports!.isNotEmpty) {
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
    final raw = widget.fallbackReports ?? [];
    final fallbackList = raw.map((item) {
      final map = item is Map<String, dynamic> ? item : <String, dynamic>{};
      return CitizenReportItem(
        id: map['id']?.toString() ?? 'fb-report-id',
        category: map['category']?.toString() ?? 'General Grievance',
        description: map['description']?.toString() ?? '',
        status: (map['status'] ?? 'PENDING').toString().toUpperCase(),
        images: (map['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        address: map['address']?.toString(),
        adminComment: map['adminComment']?.toString(),
        createdAt: map['createdAt']?.toString() ?? DateTime.now().toString(),
        reporterName: map['reporterName']?.toString() ?? 'Citizen Resident',
        reporterEmail: map['reporterEmail']?.toString(),
        barangayName: map['barangayName']?.toString() ?? 'Mapandan',
      );
    }).toList();

    setState(() {
      _reports.clear();
      _reports.addAll(fallbackList);
      _totalCount = fallbackList.length;
      _hasMore = false;
      _isLoading = false;
      _isLoadingMore = false;
      _stats = CitizenReportStats(
        total: fallbackList.length,
        pending: fallbackList.where((r) => r.status == 'PENDING' || r.status == 'SEEN').length,
        inProgress: fallbackList.where((r) => r.status == 'IN_PROGRESS').length,
        completed: fallbackList.where((r) => r.status == 'COMPLETED').length,
        rejected: fallbackList.where((r) => r.status == 'REJECTED').length,
      );
    });
  }

  void _openFilterModal() {
    CitizenReportFilterModal.show(
      context,
      currentFilter: CitizenReportFilterCriteria(
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

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.isDark(context) ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          _buildHeader(),

          // 5 Executive KPI Metric Cards
          _buildKpiMetricsRow(),

          const SizedBox(height: 10),

          // Search & Quick Status Filter Toolbar
          _buildSearchAndFilterToolbar(),

          const SizedBox(height: 6),

          // Active Scope Badge
          _buildActiveScopeBadge(),

          const SizedBox(height: 8),

          // Main Paginated Reports List
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  LucideIcons.alertTriangle,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CITIZEN REPORTS AUDIT & LOGS",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  Text(
                    _isLoading
                        ? "Connecting to civic records..."
                        : "$_totalCount Verified Community Incidents",
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _openFilterModal,
                icon: Stack(
                  children: [
                    const Icon(
                      LucideIcons.slidersHorizontal,
                      size: 19,
                      color: Color(0xFFF59E0B),
                    ),
                    if (_activeStatus != 'ALL' || _activeCategory != 'ALL')
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
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
    final pending = _stats?.pending ?? 0;
    final inProgress = _stats?.inProgress ?? 0;
    final completed = _stats?.completed ?? 0;
    final rejected = _stats?.rejected ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildKpiCard(
            title: "TOTAL",
            value: "$total",
            icon: LucideIcons.layers,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "PENDING",
            value: "$pending",
            icon: LucideIcons.clock,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "IN PROGRESS",
            value: "$inProgress",
            icon: LucideIcons.refreshCw,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "RESOLVED",
            value: "$completed",
            icon: LucideIcons.checkCircle2,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "REJECTED",
            value: "$rejected",
            icon: LucideIcons.xCircle,
            color: const Color(0xFFEF4444),
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
    return Container(
      constraints: const BoxConstraints(minWidth: 95),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: AppColors.getCardShadow(context),
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
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextSecondary(context),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterToolbar() {
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
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(color: AppColors.getTextPrimary(context), fontSize: 12),
              decoration: InputDecoration(
                hintText: "Search by grievance, reporter, category...",
                hintStyle: GoogleFonts.inter(
                  color: AppColors.getTextSecondary(context),
                  fontSize: 11.5,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 15,
                  color: Color(0xFFF59E0B),
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
              children: kReportStatuses.map((opt) {
                final isSelected = _activeStatus == opt['key'];
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
                        color: isSelected ? color.withValues(alpha: 0.2) : AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? color : AppColors.getBorder(context),
                        ),
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
                              color: isSelected ? (AppColors.isDark(context) ? Colors.white : color) : AppColors.getTextSecondary(context),
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
    final bgy = widget.selectedBarangay.isEmpty
        ? "Municipality-Wide"
        : widget.selectedBarangay;
    final categoryStr = _activeCategory == 'ALL'
        ? "All Categories"
        : _activeCategory.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 11,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 5),
                Text(
                  bgy,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(
                  LucideIcons.tag,
                  size: 11,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  categoryStr,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
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
            CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
            SizedBox(height: 12),
            Text(
              "Loading citizen grievance logs...",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _reports.isEmpty) {
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
                  backgroundColor: const Color(0xFFF59E0B),
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

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.fileSearch,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              "No citizen incident reports found",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Try adjusting your search or active filter range.",
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _reports.length + (_hasMore ? 1 : 1),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _reports.length) {
          if (_hasMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Loading next 15 records...",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
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
                  "— End of Citizen Reports Audit (${_reports.length} items) —",
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          }
        }

        final item = _reports[index];
        return _buildReportTile(item, index + 1);
      },
    );
  }

  Widget _buildReportTile(CitizenReportItem item, int indexNumber) {
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(item.createdAt).toLocal();
    } catch (_) {}

    final dateStr = parsedDate != null
        ? _displayDateFormat.format(parsedDate)
        : item.createdAt;

    final statusStyle = _getStatusVisual(item.status);

    return InkWell(
      onTap: () => _showReportDetailSheet(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: AppColors.getCardShadow(context),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Index Badge
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.isDark(context)
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "$indexNumber",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Reporter & Date & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.reporterName,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.getTextPrimary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "• $dateStr",
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusStyle.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: statusStyle.color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          statusStyle.label,
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: statusStyle.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Category & Barangay Pills
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF59E0B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.isDark(context)
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.mapPin, size: 9, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  item.barangayName,
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
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
                      ),
                    ],
                  ),

                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDetailSheet(CitizenReportItem report) {
    final statusStyle = _getStatusVisual(report.status);
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(report.createdAt).toLocal();
    } catch (_) {}
    final formattedDate = parsedDate != null
        ? _displayDateFormat.format(parsedDate)
        : report.createdAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: AppColors.getBackground(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.isDark(context) ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.alertCircle,
                            size: 15,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "INCIDENT INSPECTION",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: AppColors.getTextPrimary(context),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              "Executive civic grievance investigation dossier",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.x, size: 18, color: AppColors.getTextSecondary(context)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              Divider(color: AppColors.getBorder(context), height: 1),

              // Detail Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Category Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              report.category.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusStyle.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusStyle.color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              statusStyle.label,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: statusStyle.color,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Location & Date Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Barangay ${report.barangayName}",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.getTextPrimary(context),
                                        ),
                                      ),
                                      if (report.address != null && report.address!.isNotEmpty)
                                        Text(
                                          report.address!,
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            color: AppColors.getTextSecondary(context),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Divider(color: AppColors.getBorder(context), height: 1),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(LucideIcons.calendar, size: 13, color: AppColors.getTextSecondary(context)),
                                    const SizedBox(width: 6),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                                if (report.latitude != null && report.longitude != null)
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.compass, size: 13, color: Color(0xFF38BDF8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${report.latitude!.toStringAsFixed(4)}, ${report.longitude!.toStringAsFixed(4)}",
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF38BDF8),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Reporter Information Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.isDark(context)
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(LucideIcons.user, size: 16, color: AppColors.getTextPrimary(context)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    report.reporterName,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                  Text(
                                    report.reporterEmail ?? "Verified Citizen Account",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        "INCIDENT STATEMENT & GRIEVANCE",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceElevated(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: Text(
                          report.description.isNotEmpty
                              ? report.description
                              : "No detailed description was provided by the citizen.",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Attached Evidence Photos
                      Text(
                        "PHOTOGRAPHIC EVIDENCE GALLERY (${report.images.length})",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (report.images.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.getSurface(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.getBorder(context)),
                          ),
                          child: Center(
                            child: Text(
                              "No attached photographic evidence for this report.",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppColors.getTextSecondary(context),
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: report.images.length,
                            separatorBuilder: (context, _) => const SizedBox(width: 8),
                            itemBuilder: (context, imgIdx) {
                              final imgUrl = report.images[imgIdx];
                              return InkWell(
                                onTap: () => _showFullImageViewer(imgUrl),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 130,
                                  decoration: BoxDecoration(
                                    color: AppColors.getSurface(context),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.getBorder(context)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    imgUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                    errorBuilder: (ctx, error, stackTrace) {
                                      return Container(
                                        color: AppColors.getSurfaceElevated(context),
                                        child: Center(
                                          child: Icon(
                                            LucideIcons.imageOff,
                                            size: 20,
                                            color: AppColors.getTextSecondary(context),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Administrative Resolution & Response
                      Text(
                        "ADMINISTRATIVE RESOLUTION NOTES",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: report.adminComment != null
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: report.adminComment != null
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : AppColors.getBorder(context),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              report.adminComment != null
                                  ? LucideIcons.shieldCheck
                                  : LucideIcons.info,
                              size: 16,
                              color: report.adminComment != null
                                  ? const Color(0xFF10B981)
                                  : AppColors.getTextSecondary(context),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                report.adminComment ??
                                    "No municipal administrative notes logged yet.",
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  height: 1.4,
                                  color: report.adminComment != null
                                      ? AppColors.getTextPrimary(context)
                                      : AppColors.getTextSecondary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullImageViewer(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(24),
                      color: AppColors.surface,
                      child: const Text(
                        "Unable to load full resolution photograph",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.x, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _StatusVisual _getStatusVisual(String status) {
    switch (status) {
      case "COMPLETED":
        return _StatusVisual("COMPLETED", const Color(0xFF10B981));
      case "REJECTED":
        return _StatusVisual("REJECTED", const Color(0xFFEF4444));
      case "IN_PROGRESS":
        return _StatusVisual("IN PROGRESS", const Color(0xFF0EA5E9));
      case "SEEN":
        return _StatusVisual("SEEN", const Color(0xFF3B82F6));
      case "PENDING":
        return _StatusVisual("PENDING", const Color(0xFFF59E0B));
      default:
        return _StatusVisual(status.replaceAll("_", " "), AppColors.textSecondary);
    }
  }
}

class _StatusVisual {
  final String label;
  final Color color;
  _StatusVisual(this.label, this.color);
}
