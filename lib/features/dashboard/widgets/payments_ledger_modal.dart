import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/payment_ledger_model.dart';
import 'collections_filter_modal.dart';

class PaymentsLedgerModal extends ConsumerStatefulWidget {
  final CollectionsFilterCriteria initialFilter;
  final String selectedBarangay;
  final double? initialTotalRevenue;
  final List<dynamic>? fallbackPayments;

  const PaymentsLedgerModal({
    super.key,
    required this.initialFilter,
    required this.selectedBarangay,
    this.initialTotalRevenue,
    this.fallbackPayments,
  });

  static void show(
    BuildContext context, {
    required CollectionsFilterCriteria initialFilter,
    required String selectedBarangay,
    double? initialTotalRevenue,
    List<dynamic>? fallbackPayments,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentsLedgerModal(
        initialFilter: initialFilter,
        selectedBarangay: selectedBarangay,
        initialTotalRevenue: initialTotalRevenue,
        fallbackPayments: fallbackPayments,
      ),
    );
  }

  @override
  ConsumerState<PaymentsLedgerModal> createState() =>
      _PaymentsLedgerModalState();
}

class _PaymentsLedgerModalState extends ConsumerState<PaymentsLedgerModal> {
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

  // Cancellation token for live search/filter
  CancelToken? _cancelToken;

  // Active filters (inherited from parent card)
  late String _activeMethod;
  late DateTime _startDate;
  late DateTime _endDate;
  String _searchQuery = "";

  // Data
  final List<PaymentLedgerItem> _payments = [];
  PaymentLedgerStats? _stats;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _activeMethod = widget.initialFilter.paymentMethod;
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;

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
      _payments.clear();
    });
    await _fetchPayments(page: 1);
  }

  Future<void> _loadInitialPage() async {
    await _fetchPayments(page: 1);
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchPayments(page: _currentPage + 1);
  }

  Future<void> _fetchPayments({required int page}) async {
    try {
      final apiClient = ref.read(apiClientProvider);

      if (page == 1) {
        _cancelToken?.cancel("New search or filter request");
        _cancelToken = CancelToken();
      }

      final queryParams = {
        'page': page,
        'limit': _pageSize,
        'from': _apiDateFormat.format(_startDate),
        'to': _apiDateFormat.format(_endDate),
      };

      if (_activeMethod != 'ALL') {
        queryParams['method'] = _activeMethod;
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
        AppConstants.paymentsEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (response.data != null && response.data['success'] == true) {
        final parsed = PaginatedPaymentsResponse.fromJson(response.data);

        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _hasMore = parsed.hasMore;
          _stats = parsed.stats;
          _totalCount = parsed.totalCount;

          if (page == 1) {
            _payments.clear();
          }
          _payments.addAll(parsed.payments);
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      } else {
        throw Exception(
          response.data?['error'] ?? "Failed to fetch municipal payments.",
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;
      // Fallback gracefully to passed payments if offline or initial server error
      if (page == 1 &&
          widget.fallbackPayments != null &&
          widget.fallbackPayments!.isNotEmpty) {
        _useFallbackData();
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage =
              e.response?.data?['error'] ??
              "Unable to connect to municipal payments ledger.";
        });
      }
    } catch (err) {
      if (!mounted) return;
      if (page == 1 &&
          widget.fallbackPayments != null &&
          widget.fallbackPayments!.isNotEmpty) {
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
    final raw = widget.fallbackPayments ?? [];
    final fallbackList = raw.map((item) {
      final map = item is Map<String, dynamic> ? item : <String, dynamic>{};
      return PaymentLedgerItem(
        id: map['id']?.toString() ?? 'fb-id',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        method: (map['method'] ?? 'CASH').toString().toUpperCase(),
        status: (map['status'] ?? 'PAID').toString().toUpperCase(),
        orNumber: map['orNumber']?.toString(),
        createdAt: map['createdAt']?.toString() ?? DateTime.now().toString(),
        serviceType: map['serviceType']?.toString() ?? 'Municipal Fee',
        serviceCategory: map['category']?.toString() ?? 'GENERAL',
        payerName:
            map['payerName']?.toString() ??
            map['residentName']?.toString() ??
            'Citizen Payer',
      );
    }).toList();

    setState(() {
      _payments.clear();
      _payments.addAll(fallbackList);
      _totalCount = fallbackList.length;
      _hasMore = false;
      _isLoading = false;
      _isLoadingMore = false;
      _stats = PaymentLedgerStats(
        totalCount: fallbackList.length,
        totalRevenue: widget.initialTotalRevenue ?? 0.0,
        paidCount: fallbackList.where((p) => p.status == 'PAID').length,
        pendingCount: fallbackList.where((p) => p.status == 'PENDING').length,
        avgPayment: fallbackList.isNotEmpty
            ? (widget.initialTotalRevenue ?? 0.0) / fallbackList.length
            : 0.0,
      );
    });
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

          // 3 Executive KPI Cards (Exact Web Match)
          _buildKpiMetricsRow(),

          const SizedBox(height: 10),

          // Search & Filter Toolbar
          _buildSearchAndFilterToolbar(),

          const SizedBox(height: 6),

          // Active Scope Badge (Inherited filter details)
          _buildActiveScopeBadge(),

          const SizedBox(height: 8),

          // Main Paginated Ledger List
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
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.receipt,
                    size: 18,
                    color: Color(0xFF10B981),
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
                          "MUNICIPAL PAYMENTS",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                      Text(
                        _isLoading
                            ? "Connecting to municipal records..."
                            : "$_totalCount Registered Payment Records",
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
    );
  }

  Widget _buildKpiMetricsRow() {
    final totalRev =
        _stats?.totalRevenue ?? widget.initialTotalRevenue ?? 0.0;
    final paidCount = _stats?.paidCount ?? 0;
    final pendingCount = _stats?.pendingCount ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Total Collected
          Expanded(
            flex: 4,
            child: _buildKpiCard(
              title: "TOTAL COLLECTED",
              value: _currencyFormat.format(totalRev),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          // Paid Transactions
          Expanded(
            flex: 3,
            child: _buildKpiCard(
              title: "PAID",
              value: "$paidCount",
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 8),
          // Pending
          Expanded(
            flex: 3,
            child: _buildKpiCard(
              title: "PENDING",
              value: "$pendingCount",
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color color,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: isDark ? [] : AppColors.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextSecondary(context),
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color == AppColors.primary ? AppColors.getTextPrimary(context) : color,
              ),
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
          // Search Input
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.getTextPrimary(context)),
              decoration: InputDecoration(
                hintText: "Search resident, OR #, or reference...",
                hintStyle: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.getTextSecondary(context).withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 15,
                  color: AppColors.getTextSecondary(context),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          size: 14,
                          color: AppColors.getTextSecondary(context),
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

          // Method Selector Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMethodChip("ALL", "All Methods"),
                const SizedBox(width: 6),
                _buildMethodChip("CASH", "Cash"),
                const SizedBox(width: 6),
                _buildMethodChip("ONLINE", "Online / E-Pay"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(String methodKey, String label) {
    final isSelected = _activeMethod == methodKey;
    return InkWell(
      onTap: () {
        if (_activeMethod != methodKey) {
          setState(() {
            _activeMethod = methodKey;
          });
          _resetAndReload();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.getBorder(context),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
          ),
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
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.getBorder(context).withValues(alpha: 0.6)),
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
            CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              "Loading municipal ledger records...",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _payments.isEmpty) {
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
                  backgroundColor: AppColors.primary,
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

    if (_payments.isEmpty) {
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
              "No payment records found",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Try adjusting your search or active filter range.",
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
      itemCount: _payments.length + (_hasMore ? 1 : 1),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _payments.length) {
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
                        color: AppColors.primary,
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
                  "— End of Municipal Payment Records (${_payments.length} items) —",
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

        final item = _payments[index];
        return _buildPaymentTile(item, index + 1);
      },
    );
  }

  Widget _buildPaymentTile(PaymentLedgerItem item, int indexNumber) {
    final isPaid = item.status == "PAID";
    final isDark = AppColors.isDark(context);
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(item.createdAt).toLocal();
    } catch (_) {}

    final dateStr = parsedDate != null
        ? _displayDateFormat.format(parsedDate)
        : item.createdAt;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: isDark ? [] : AppColors.getCardShadow(context),
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
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
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

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Payer Name & Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        item.payerName,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.getTextPrimary(context),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currencyFormat.format(item.amount),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isPaid
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Service & Badges Row
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
                          color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.serviceType.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Method Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.method,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isPaid
                              ? const Color(0xFF10B981).withValues(alpha: 0.25)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        item.status,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: isPaid
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Subtitle: OR Number & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.orNumber != null && item.orNumber!.isNotEmpty
                          ? "OR: ${item.orNumber}"
                          : "Ref: ${item.id.substring(0, item.id.length > 8 ? 8 : item.id.length)}",
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: AppColors.getTextSecondary(context).withValues(alpha: 0.7),
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
}
