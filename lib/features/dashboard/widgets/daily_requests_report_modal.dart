import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/daily_request_report_model.dart';
import 'request_filter_modal.dart';

class DailyRequestsReportModal extends ConsumerStatefulWidget {
  final RequestFilterCriteria initialFilter;
  final String selectedBarangay;
  final int? initialTotalCount;
  final List<dynamic>? fallbackTransactions;

  const DailyRequestsReportModal({
    super.key,
    required this.initialFilter,
    required this.selectedBarangay,
    this.initialTotalCount,
    this.fallbackTransactions,
  });

  static void show(
    BuildContext context, {
    required RequestFilterCriteria initialFilter,
    required String selectedBarangay,
    int? initialTotalCount,
    List<dynamic>? fallbackTransactions,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DailyRequestsReportModal(
        initialFilter: initialFilter,
        selectedBarangay: selectedBarangay,
        initialTotalCount: initialTotalCount,
        fallbackTransactions: fallbackTransactions,
      ),
    );
  }

  @override
  ConsumerState<DailyRequestsReportModal> createState() =>
      _DailyRequestsReportModalState();
}

class _DailyRequestsReportModalState
    extends ConsumerState<DailyRequestsReportModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('MMM d, yyyy • h:mm a');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

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

  // Active filters (inherited from parent card)
  late String _activeStatus;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _activeCategory;
  String _searchQuery = "";

  // Data
  final List<DailyRequestItem> _transactions = [];
  DailyRequestReportStats? _stats;
  int _totalCount = 0;

  static const List<Map<String, dynamic>> kDailyRequestStatuses = [
    {'key': 'ALL', 'label': 'All Statuses', 'color': Color(0xFF8B5CF6)},
    {'key': 'FOR_REQUESTING', 'label': 'FOR REQUESTING', 'color': Color(0xFFF59E0B)},
    {'key': 'FOR_INSPECTION', 'label': 'FOR INSPECTION', 'color': Color(0xFFF59E0B)},
    {'key': 'FOR_REVISION', 'label': 'FOR REVISION', 'color': Color(0xFFF59E0B)},
    {'key': 'FOR_PROCESSING', 'label': 'FOR PROCESSING', 'color': Color(0xFF0EA5E9)},
    {'key': 'FOR_PAYMENT', 'label': 'FOR PAYMENT', 'color': Color(0xFF0EA5E9)},
    {'key': 'FOR_COMPLIANCE', 'label': 'FOR COMPLIANCE', 'color': Color(0xFF0EA5E9)},
    {'key': 'RELEASED', 'label': 'RELEASED', 'color': Color(0xFF10B981)},
    {'key': 'REJECTED', 'label': 'REJECTED', 'color': Color(0xFFF43F5E)},
  ];

  @override
  void initState() {
    super.initState();
    final rawStatus = widget.initialFilter.status.toUpperCase();
    if (rawStatus == 'REQUESTS' || rawStatus.isEmpty) {
      _activeStatus = 'ALL';
    } else {
      _activeStatus = rawStatus;
    }

    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
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
      _transactions.clear();
    });
    await _fetchRequests(page: 1);
  }

  Future<void> _loadInitialPage() async {
    await _fetchRequests(page: 1);
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchRequests(page: _currentPage + 1);
  }

  Future<void> _fetchRequests({required int page}) async {
    try {
      final apiClient = ref.read(apiClientProvider);

      if (page == 1) {
        _cancelToken?.cancel("New search or filter request");
        _cancelToken = CancelToken();
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': _pageSize,
        'from': _apiDateFormat.format(_startDate),
        'to': _apiDateFormat.format(_endDate),
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
        AppConstants.requestsEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (response.data != null && response.data['success'] == true) {
        final parsed = PaginatedDailyRequestsResponse.fromJson(response.data);

        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _hasMore = parsed.hasMore;
          _stats = parsed.stats;
          _totalCount = parsed.totalCount;

          if (page == 1) {
            _transactions.clear();
          }
          _transactions.addAll(parsed.transactions);
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      } else {
        throw Exception(
          response.data?['error'] ?? "Failed to fetch municipal requests report.",
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;
      if (page == 1 &&
          widget.fallbackTransactions != null &&
          widget.fallbackTransactions!.isNotEmpty) {
        _useFallbackData();
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage =
              e.response?.data?['error'] ??
              "Unable to connect to municipal requests server.";
        });
      }
    } catch (err) {
      if (!mounted) return;
      if (page == 1 &&
          widget.fallbackTransactions != null &&
          widget.fallbackTransactions!.isNotEmpty) {
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
    final raw = widget.fallbackTransactions ?? [];
    final fallbackList = raw.map((item) {
      final map = item is Map<String, dynamic> ? item : <String, dynamic>{};
      return DailyRequestItem(
        id: map['id']?.toString() ?? 'fb-id',
        createdAt: map['createdAt']?.toString() ?? DateTime.now().toString(),
        status: (map['status'] ?? 'PENDING').toString().toUpperCase(),
        residentName:
            map['residentName']?.toString() ??
            map['userName']?.toString() ??
            'Citizen Resident',
        serviceType: map['serviceType']?.toString() ?? 'Municipal Request',
        serviceCategory: map['serviceCategory']?.toString() ?? 'GENERAL',
        paymentMethod: map['paymentMethod']?.toString(),
        paymentStatus: map['paymentStatus']?.toString(),
        amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    setState(() {
      _transactions.clear();
      _transactions.addAll(fallbackList);
      _totalCount = fallbackList.length;
      _hasMore = false;
      _isLoading = false;
      _isLoadingMore = false;
      _stats = DailyRequestReportStats(
        total: fallbackList.length,
        pending: fallbackList.where((t) => t.status != 'RELEASED' && t.status != 'REJECTED').length,
        released: fallbackList.where((t) => t.status == 'RELEASED').length,
        rejected: fallbackList.where((t) => t.status == 'REJECTED').length,
        revenue: fallbackList.fold(0.0, (sum, t) => sum + t.amountPaid),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
                color: Colors.white.withValues(alpha: 0.2),
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

          // Main Paginated Requests List
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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.fileText,
                  size: 18,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DAILY REQUESTS AUDIT & LOGS",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _isLoading
                        ? "Connecting to municipal records..."
                        : "$_totalCount Registered Service Records",
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              LucideIcons.x,
              size: 20,
              color: AppColors.textSecondary,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsRow() {
    final total = _stats?.total ?? widget.initialTotalCount ?? 0;
    final pending = _stats?.pending ?? 0;
    final released = _stats?.released ?? 0;
    final rejected = _stats?.rejected ?? 0;
    final revenue = _stats?.revenue ?? 0.0;

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
            title: "RELEASED",
            value: "$released",
            icon: LucideIcons.checkCircle2,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "REJECTED",
            value: "$rejected",
            icon: LucideIcons.xCircle,
            color: const Color(0xFFF43F5E),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "COLLECTIONS",
            value: _currencyFormat.format(revenue),
            icon: LucideIcons.wallet,
            color: const Color(0xFF3B82F6),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 11, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          // Search Input
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search resident, service, or ref ID...",
                hintStyle: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged("");
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Status Filter Chips (100% Web Parity: 9 canonical statuses)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kDailyRequestStatuses.map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildStatusChip(
                    opt['key'] as String,
                    opt['label'] as String,
                    opt['color'] as Color,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String statusKey, String label, Color accentColor) {
    final isSelected = _activeStatus == statusKey;
    return InkWell(
      onTap: () {
        if (_activeStatus != statusKey) {
          setState(() {
            _activeStatus = statusKey;
          });
          _resetAndReload();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : AppColors.textSecondary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScopeBadge() {
    final bgy = widget.selectedBarangay.isEmpty
        ? "Municipality-Wide"
        : widget.selectedBarangay;
    final dateRangeStr =
        "${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}";

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
                  color: Color(0xFF38BDF8),
                ),
                const SizedBox(width: 5),
                Text(
                  bgy,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 11,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  dateRangeStr,
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
            CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
            SizedBox(height: 12),
            Text(
              "Loading municipal daily request logs...",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _transactions.isEmpty) {
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
                  backgroundColor: const Color(0xFF3B82F6),
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

    if (_transactions.isEmpty) {
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
              "No daily request logs found",
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
      itemCount: _transactions.length + (_hasMore ? 1 : 1),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _transactions.length) {
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
                        color: Color(0xFF3B82F6),
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
                  "— End of Municipal Request Logs (${_transactions.length} items) —",
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

        final item = _transactions[index];
        return _buildRequestTile(item, index + 1);
      },
    );
  }

  Widget _buildRequestTile(DailyRequestItem item, int indexNumber) {
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(item.createdAt).toLocal();
    } catch (_) {}

    final dateStr = parsedDate != null
        ? _displayDateFormat.format(parsedDate)
        : item.createdAt;

    final statusStyle = _getStatusVisual(item.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "$indexNumber",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Resident Name & Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        item.residentName,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.amountPaid > 0
                          ? _currencyFormat.format(item.amountPaid)
                          : "₱0.00",
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: item.amountPaid > 0
                            ? const Color(0xFF10B981)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Service & Status Badges Row
                Row(
                  children: [
                    // Service Type Chip
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.serviceType.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF60A5FA),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Payment Method Tag (if present)
                    if (item.paymentMethod != null && item.paymentMethod!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.paymentMethod!,
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusStyle.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: statusStyle.color.withValues(alpha: 0.25),
                        ),
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
                const SizedBox(height: 6),

                // Subtitle: Ref ID & Timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ref: ${item.id.substring(0, item.id.length > 8 ? 8 : item.id.length)}",
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusVisual _getStatusVisual(String status) {
    switch (status) {
      case "RELEASED":
        return _StatusVisual("RELEASED", const Color(0xFF10B981));
      case "REJECTED":
        return _StatusVisual("REJECTED", const Color(0xFFF43F5E));
      case "FOR_INSPECTION":
        return _StatusVisual("INSPECTION", const Color(0xFFF59E0B));
      case "FOR_REVISION":
        return _StatusVisual("REVISION", const Color(0xFFF59E0B));
      case "FOR_REQUESTING":
        return _StatusVisual("REQUESTING", const Color(0xFFF59E0B));
      case "FOR_PROCESSING":
        return _StatusVisual("PROCESSING", const Color(0xFF0EA5E9));
      case "FOR_PAYMENT":
        return _StatusVisual("FOR PAYMENT", const Color(0xFF0EA5E9));
      case "FOR_COMPLIANCE":
        return _StatusVisual("COMPLIANCE", const Color(0xFF0EA5E9));
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
