import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/admin_service_model.dart';

class ArtaComplianceModal extends ConsumerStatefulWidget {
  final AdminServicesCounts? summaryCounts;

  const ArtaComplianceModal({super.key, this.summaryCounts});

  static Future<void> show(BuildContext context, {AdminServicesCounts? summaryCounts}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ArtaComplianceModal(summaryCounts: summaryCounts),
    );
  }

  @override
  ConsumerState<ArtaComplianceModal> createState() => _ArtaComplianceModalState();
}

class _ArtaComplianceModalState extends ConsumerState<ArtaComplianceModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  final List<ArtaItemModel> _requests = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _errorMessage;

  // Active Date Range Filter (Default: Last 30 Days like Web ARTA Dashboard)
  late DateTime _startDate;
  late DateTime _endDate;
  String _activeDatePreset = '30D'; // 30D, 7D, MONTH, ALL, CUSTOM

  // Active SLA Filter Chip (ALL, PENDING, BREACHED, COMPLIANT)
  String _selectedSlaFilter = 'ALL';

  // Live KPI Summary stats from API
  int _kpiTotal = 0;
  double _kpiComplianceRate = 100.0;
  int _kpiCompleted = 0;
  int _kpiPending = 0;
  int _kpiOverdue = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _startDate = now.subtract(const Duration(days: 30));

    if (widget.summaryCounts != null) {
      _kpiTotal = widget.summaryCounts!.arta;
      _kpiComplianceRate = widget.summaryCounts!.artaComplianceRate;
      _kpiOverdue = widget.summaryCounts!.artaOverdue;
    }

    _scrollController.addListener(_onScroll);
    _fetchArtaRequests(page: 1);
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
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

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _currentPage = 1;
          _hasMore = true;
          _requests.clear();
        });
        _fetchArtaRequests(page: 1);
      }
    });
  }

  void _onFilterChanged(String filter) {
    if (_selectedSlaFilter == filter) return;
    setState(() {
      _selectedSlaFilter = filter;
      _currentPage = 1;
      _hasMore = true;
      _requests.clear();
    });
    _fetchArtaRequests(page: 1);
  }

  void _applyDatePreset(String presetKey) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (presetKey) {
      case '7D':
        start = now.subtract(const Duration(days: 7));
        break;
      case '30D':
        start = now.subtract(const Duration(days: 30));
        break;
      case 'MONTH':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'ALL':
        start = DateTime(2023, 1, 1);
        break;
      default:
        start = _startDate;
        end = _endDate;
    }

    setState(() {
      _activeDatePreset = presetKey;
      _startDate = start;
      _endDate = end;
      _currentPage = 1;
      _hasMore = true;
      _requests.clear();
    });
    _fetchArtaRequests(page: 1);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        final isDark = AppColors.isDark(context);
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF3B82F6),
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceElevated,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF3B82F6),
                    onPrimary: Colors.white,
                    surface: AppColors.lightSurface,
                    onSurface: AppColors.lightTextPrimary,
                  ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.getSurface(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _activeDatePreset = 'CUSTOM';
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _currentPage = 1;
        _hasMore = true;
        _requests.clear();
      });
      _fetchArtaRequests(page: 1);
    }
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);
    await _fetchArtaRequests(page: _currentPage + 1);
  }

  Future<void> _fetchArtaRequests({required int page}) async {
    try {
      final apiClient = ref.read(apiClientProvider);

      if (page == 1) {
        _cancelToken?.cancel();
        _cancelToken = CancelToken();
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': 15,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
      };

      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (_selectedSlaFilter != 'ALL') {
        queryParams['slaStatus'] = _selectedSlaFilter;
      }

      final res = await apiClient.dio.get(
        AppConstants.artaEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (res.data != null && res.data['success'] == true) {
        final rawList = res.data['requests'] as List? ?? [];
        final totalCount = (res.data['totalCount'] as num?)?.toInt() ?? 0;
        final hasMore = res.data['hasMore'] == true;

        if (!mounted) return;

        setState(() {
          _currentPage = page;
          _totalCount = totalCount;
          _hasMore = hasMore;
          if (page == 1) _requests.clear();
          _requests.addAll(rawList.map((e) => ArtaItemModel.fromJson(e)).toList());

          // Update dynamic KPI summaries from live API
          if (res.data['stats'] != null) {
            final stats = res.data['stats'];
            _kpiTotal = (stats['totalRequests'] as num?)?.toInt() ?? totalCount;
            _kpiComplianceRate = (stats['complianceRate'] as num?)?.toDouble() ?? 100.0;
            _kpiCompleted = (stats['completed'] as num?)?.toInt() ?? 0;
            _kpiPending = (stats['pendingClock'] as num?)?.toInt() ?? 0;
            _kpiOverdue = (stats['overdueBreaches'] as num?)?.toInt() ?? 0;
          }

          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        throw Exception(res.data?['error'] ?? "Failed to load ARTA requests.");
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = e.message ?? "Network error.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _showDetailSheet(ArtaItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ArtaDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF3B82F6); // Executive ARTA Blue

    final dateRangeLabel = "${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}";

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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

          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "ARTA COMPLIANCE",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: -0.2,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$_totalCount",
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Anti-Red Tape Act • Statutory SLA Real-Time Audit",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: AppColors.getTextSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: AppColors.getTextSecondary(context), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Date Range Picker Bar (Like Collections Ledger)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text(
                          dateRangeLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.getTextSecondary(context)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Preset Quick Pills
                  _buildDatePresetPill("30D", "30 Days"),
                  const SizedBox(width: 4),
                  _buildDatePresetPill("7D", "7 Days"),
                  const SizedBox(width: 4),
                  _buildDatePresetPill("MONTH", "Month"),
                ],
              ),
            ),
          ),

          // Top 4 Metrics Strip (Interactive tap to filter)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricMiniCard(
                    label: "COMPLIANCE",
                    value: "${_kpiComplianceRate.toStringAsFixed(1)}%",
                    color: const Color(0xFF10B981),
                    icon: Icons.check_circle_outline_rounded,
                    isActive: _selectedSlaFilter == 'COMPLIANT',
                    onTap: () => _onFilterChanged('COMPLIANT'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricMiniCard(
                    label: "TOTAL AUDIT",
                    value: "$_kpiTotal",
                    color: accentColor,
                    icon: Icons.assignment_outlined,
                    isActive: _selectedSlaFilter == 'ALL',
                    onTap: () => _onFilterChanged('ALL'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricMiniCard(
                    label: "PENDING",
                    value: "$_kpiPending",
                    color: const Color(0xFF3B82F6),
                    icon: Icons.schedule_rounded,
                    isActive: _selectedSlaFilter == 'PENDING',
                    onTap: () => _onFilterChanged('PENDING'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricMiniCard(
                    label: "OVERDUE",
                    value: "$_kpiOverdue",
                    color: _kpiOverdue > 0 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                    icon: Icons.warning_amber_rounded,
                    isActive: _selectedSlaFilter == 'BREACHED',
                    onTap: () => _onFilterChanged('BREACHED'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(
                  color: AppColors.getTextPrimary(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Search ref #, service, office code, or applicant...",
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.getTextSecondary(context).withValues(alpha: 0.7),
                    fontSize: 11.5,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.getTextSecondary(context),
                    size: 18,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: AppColors.getTextSecondary(context), size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip("ALL", "All Requests ($_kpiTotal)"),
                const SizedBox(width: 8),
                _buildFilterChip("PENDING", "Pending Clock ($_kpiPending)", color: const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildFilterChip("BREACHED", "Breached SLA ($_kpiOverdue)", color: const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _buildFilterChip("COMPLIANT", "Compliant Requests ($_kpiCompleted)", color: const Color(0xFF10B981)),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: AppColors.getBorder(context)),

          // Body Content
          Expanded(
            child: _buildBodyContent(accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePresetPill(String presetKey, String label) {
    final isSelected = _activeDatePreset == presetKey;
    return InkWell(
      onTap: () => _applyDatePreset(presetKey),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : AppColors.getSurfaceElevated(context),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricMiniCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.25),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, {Color? color}) {
    final isSelected = _selectedSlaFilter == value;
    final activeColor = color ?? const Color(0xFF3B82F6);

    return InkWell(
      onTap: () => _onFilterChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.getBorder(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? (AppColors.isDark(context) ? Colors.white : activeColor) : AppColors.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(Color accentColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Auditing statutory ARTA requests...",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.getTextSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.8), size: 40),
              const SizedBox(height: 12),
              Text(
                "Audit Load Failed",
                style: GoogleFonts.inter(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.getTextSecondary(context), fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchArtaRequests(page: 1),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Icon(Icons.shield_outlined, color: AppColors.getTextSecondary(context), size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              "No ARTA Requests Found",
              style: GoogleFonts.inter(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              "No requests match status: $_selectedSlaFilter in the selected date range.",
              style: GoogleFonts.inter(color: AppColors.getTextSecondary(context), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _requests.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _requests.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          );
        }

        final item = _requests[index];
        return _buildArtaCard(item);
      },
    );
  }

  Widget _buildArtaCard(ArtaItemModel item) {
    final statusColor = item.slaColor;

    String statusBadgeLabel;
    IconData statusBadgeIcon;

    if (item.slaStatus == 'BREACHED') {
      statusBadgeLabel = "BREACHED SLA";
      statusBadgeIcon = Icons.warning_rounded;
    } else if (item.slaStatus == 'PENDING') {
      statusBadgeLabel = "PENDING CLOCK";
      statusBadgeIcon = Icons.schedule_rounded;
    } else {
      statusBadgeLabel = "COMPLIANT";
      statusBadgeIcon = Icons.check_circle_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: AppColors.getCardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailSheet(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Office, SLA Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.officeCode,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            statusBadgeIcon,
                            size: 11,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusBadgeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Service Name
                Text(
                  item.serviceName,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),

                const SizedBox(height: 6),

                // Applicant & Transaction type
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 13, color: AppColors.getTextSecondary(context)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item.applicantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.getTextSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.isDark(context)
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.transactionType,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: AppColors.getBorder(context)),
                const SizedBox(height: 10),

                // Bottom row: Submitted date & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Filed: ${item.submittedAt.split('T').first}",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "AUDIT SLA",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF3B82F6),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF3B82F6)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtaDetailSheet extends StatelessWidget {
  final ArtaItemModel item;

  const _ArtaDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.slaColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
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

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Office Pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          "SLA: ${item.slaStatus}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "OFFICE: ${item.officeCode}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ref No
                  Text(
                    item.referenceNo,
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Service Name
                  Text(
                    item.serviceName,
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Info Tiles
                  _buildDetailTile(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    label: "Applicant Full Name",
                    value: item.applicantName,
                  ),
                  const SizedBox(height: 10),

                  _buildDetailTile(
                    context: context,
                    icon: Icons.category_outlined,
                    label: "Transaction Type & Charter Standard",
                    value: "${item.transactionType} Transaction (SLA Max Limit)",
                  ),
                  const SizedBox(height: 10),

                  _buildDetailTile(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    label: "Date & Time Filed",
                    value: item.submittedAt.replaceAll('T', ' ').split('.').first,
                  ),
                  const SizedBox(height: 10),

                  if (item.deadlineAt != null) ...[
                    _buildDetailTile(
                      context: context,
                      icon: Icons.alarm_outlined,
                      label: "Statutory SLA Deadline",
                      value: item.deadlineAt!.replaceAll('T', ' ').split('.').first,
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (item.completedAt != null) ...[
                    _buildDetailTile(
                      context: context,
                      icon: Icons.check_circle_outline,
                      label: "Resolution / Completed At",
                      value: item.completedAt!.replaceAll('T', ' ').split('.').first,
                    ),
                    const SizedBox(height: 10),
                  ],

                  _buildDetailTile(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    label: "Current Workflow Status",
                    value: item.status,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getSurfaceElevated(context),
                  foregroundColor: AppColors.getTextPrimary(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.getBorder(context)),
                  ),
                ),
                child: Text(
                  "CLOSE AUDIT",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 16, color: AppColors.getTextSecondary(context)),
              onPressed: onCopy,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
