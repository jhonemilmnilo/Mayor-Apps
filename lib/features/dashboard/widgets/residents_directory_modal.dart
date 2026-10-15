import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/resident_directory_model.dart';
import 'resident_filter_modal.dart';

class ResidentsDirectoryModal extends ConsumerStatefulWidget {
  final ResidentFilterCriteria initialFilter;
  final String selectedBarangay;
  final int? initialTotalCount;

  const ResidentsDirectoryModal({
    super.key,
    required this.initialFilter,
    required this.selectedBarangay,
    this.initialTotalCount,
  });

  static void show(
    BuildContext context, {
    required ResidentFilterCriteria initialFilter,
    required String selectedBarangay,
    int? initialTotalCount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResidentsDirectoryModal(
        initialFilter: initialFilter,
        selectedBarangay: selectedBarangay,
        initialTotalCount: initialTotalCount,
      ),
    );
  }

  @override
  ConsumerState<ResidentsDirectoryModal> createState() =>
      _ResidentsDirectoryModalState();
}

class _ResidentsDirectoryModalState
    extends ConsumerState<ResidentsDirectoryModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('MMM d, yyyy');

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

  // Active filter criteria
  late ResidentFilterCriteria _currentFilter;
  late String _activeSector;
  String _searchQuery = "";

  // Data
  final List<ResidentDirectoryItem> _residents = [];
  ResidentReportStats? _stats;
  int _totalCount = 0;

  static const List<Map<String, dynamic>> kSectorChips = [
    {'key': 'ALL', 'label': 'All Citizens', 'color': Color(0xFF3B82F6)},
    {'key': 'SENIOR', 'label': 'Senior Citizens', 'color': Color(0xFFF59E0B)},
    {'key': 'PWD', 'label': 'PWD', 'color': Color(0xFF10B981)},
    {'key': 'SOLO_PARENT', 'label': 'Solo Parents', 'color': Color(0xFFEC4899)},
    {'key': 'FOUR_PS', 'label': '4Ps Beneficiaries', 'color': Color(0xFF8B5CF6)},
  ];

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _activeSector = widget.initialFilter.sector;

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
      _residents.clear();
    });
    await _fetchResidents(page: 1);
  }

  Future<void> _loadInitialPage() async {
    await _fetchResidents(page: 1);
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchResidents(page: _currentPage + 1);
  }

  Future<void> _fetchResidents({required int page}) async {
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

      if (!_currentFilter.isAllTime) {
        queryParams['from'] = _apiDateFormat.format(_currentFilter.startDate);
        queryParams['to'] = _apiDateFormat.format(_currentFilter.endDate);
      }

      if (_activeSector != 'ALL') {
        queryParams['sector'] = _activeSector;
      }

      if (_currentFilter.gender != 'ALL') {
        queryParams['gender'] = _currentFilter.gender;
      }

      if (_currentFilter.civilStatus != 'ALL') {
        queryParams['civilStatus'] = _currentFilter.civilStatus;
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
        AppConstants.residentsEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (response.data != null && response.data['success'] == true) {
        final parsed = PaginatedResidentsResponse.fromJson(response.data);

        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _hasMore = parsed.hasMore;
          _stats = parsed.stats;
          _totalCount = parsed.totalCount;

          if (page == 1) {
            _residents.clear();
          }
          _residents.addAll(parsed.residents);
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      } else {
        throw Exception(
          response.data?['error'] ?? "Failed to fetch municipal residents directory.",
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage =
            e.response?.data?['error'] ??
            "Unable to connect to municipal residents database.";
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = err.toString();
      });
    }
  }

  void _openFilterDialog() {
    ResidentFilterModal.show(
      context,
      currentFilter: _currentFilter.copyWith(sector: _activeSector),
      onApply: (newCriteria) {
        setState(() {
          _currentFilter = newCriteria;
          _activeSector = newCriteria.sector;
        });
        _resetAndReload();
      },
    );
  }

  void _showResidentDetails(ResidentDirectoryItem resident) {
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(resident.createdAt).toLocal();
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: AppColors.getBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.isDark(context) ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.user, size: 20, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resident.fullName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      Text(
                        "Barangay ${resident.barangay}",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF38BDF8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.getBorder(context), height: 1),
            const SizedBox(height: 16),

            // Sector badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSectorPill("SENIOR CITIZEN", resident.isSenior, const Color(0xFFF59E0B)),
                _buildSectorPill("PWD", resident.isPWD, const Color(0xFF10B981)),
                _buildSectorPill("SOLO PARENT", resident.isSoloParent, const Color(0xFFEC4899)),
                _buildSectorPill("4Ps BENEFICIARY", resident.is4Ps, const Color(0xFF8B5CF6)),
              ],
            ),

            const SizedBox(height: 18),

            // Key Info Cards
            _buildDetailItem(LucideIcons.venusAndMars, "Gender", resident.gender),
            _buildDetailItem(LucideIcons.heart, "Civil Status", resident.civilStatus),
            if (resident.contactNumber != null && resident.contactNumber!.isNotEmpty)
              _buildDetailItem(LucideIcons.phone, "Contact Number", resident.contactNumber!),
            if (resident.email != null && resident.email!.isNotEmpty)
              _buildDetailItem(LucideIcons.mail, "Email Address", resident.email!),
            _buildDetailItem(
              LucideIcons.calendar,
              "Registered On",
              parsedDate != null ? _displayDateFormat.format(parsedDate) : resident.createdAt,
            ),
            _buildDetailItem(LucideIcons.hash, "System ID", resident.id),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getSurfaceElevated(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  "CLOSE PROFILE",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorPill(String label, bool isPresent, Color color) {
    if (!isPresent) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.getTextSecondary(context)),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextSecondary(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(context),              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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

          // Main Paginated Residents List
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
                  LucideIcons.users,
                  size: 18,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MUNICIPAL RESIDENTS DIRECTORY",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: AppColors.getTextPrimary(context),                    ),
                  ),
                  Text(
                    _isLoading
                        ? "Connecting to citizen registry..."
                        : "$_totalCount Verified Municipal Residents",
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ],
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
    );
  }

  Widget _buildKpiMetricsRow() {
    final total = _stats?.total ?? widget.initialTotalCount ?? 0;
    final seniors = _stats?.seniors ?? 0;
    final pwd = _stats?.pwd ?? 0;
    final soloParents = _stats?.soloParents ?? 0;
    final fourPs = _stats?.fourPs ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildKpiCard(
            title: "TOTAL",
            value: "$total",
            icon: LucideIcons.layers,
            color: AppColors.getTextPrimary(context),          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "SENIORS",
            value: "$seniors",
            icon: LucideIcons.userCheck,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "PWD",
            value: "$pwd",
            icon: LucideIcons.accessibility,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "SOLO PARENTS",
            value: "$soloParents",
            icon: LucideIcons.heartHandshake,
            color: const Color(0xFFEC4899),
          ),
          const SizedBox(width: 8),
          _buildKpiCard(
            title: "4PS",
            value: "$fourPs",
            icon: LucideIcons.award,
            color: const Color(0xFF8B5CF6),
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
      constraints: const BoxConstraints(minWidth: 95),
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
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextSecondary(context),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 11, color: color),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              maxLines: 1,
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
          // Search Input & Filter Dialog Button
          Row(
            children: [
              Expanded(
                child: Container(
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
                      hintText: "Search resident name, barangay, or ID...",
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
              ),
              const SizedBox(width: 8),
              // Filter modal launcher button
              InkWell(
                onTap: _openFilterDialog,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (_currentFilter.gender != 'ALL' || _currentFilter.civilStatus != 'ALL')
                          ? const Color(0xFF3B82F6)
                          : AppColors.getBorder(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.slidersHorizontal,
                        size: 14,
                        color: (_currentFilter.gender != 'ALL' || _currentFilter.civilStatus != 'ALL')
                            ? const Color(0xFF60A5FA)
                            : AppColors.getTextSecondary(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "FILTERS",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: (_currentFilter.gender != 'ALL' || _currentFilter.civilStatus != 'ALL')
                              ? const Color(0xFF60A5FA)
                              : AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Special Sector Quick Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kSectorChips.map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildSectorChip(
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

  Widget _buildSectorChip(String sectorKey, String label, Color accentColor) {
    final isSelected = _activeSector == sectorKey;
    final isDark = AppColors.isDark(context);
    return InkWell(
      onTap: () {
        if (_activeSector != sectorKey) {
          setState(() {
            _activeSector = sectorKey;
          });
          _resetAndReload();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.2 : 0.12)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.getBorder(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : AppColors.getTextSecondary(context).withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? accentColor : AppColors.getTextSecondary(context),
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
    final dateRangeStr = _currentFilter.isAllTime
        ? "All-Time Registry"
        : "${DateFormat('MMM d').format(_currentFilter.startDate)} - ${DateFormat('MMM d').format(_currentFilter.endDate)}";
    final isDark = AppColors.isDark(context);

    final hasExtra = _currentFilter.gender != 'ALL' || _currentFilter.civilStatus != 'ALL';
    final extraText = [
      if (_currentFilter.gender != 'ALL') _currentFilter.gender,
      if (_currentFilter.civilStatus != 'ALL') _currentFilter.civilStatus,
    ].join(' • ');

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
                if (hasExtra) ...[
                  const SizedBox(width: 6),
                  Text(
                    "($extraText)",
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 11,
                  color: AppColors.getTextSecondary(context),
                ),
                const SizedBox(width: 5),
                Text(
                  dateRangeStr,
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
            const SizedBox(height: 12),
            Text(
              "Loading municipal resident registry...",
              style: TextStyle(color: AppColors.getTextSecondary(context), fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _residents.isEmpty) {
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
                  color: AppColors.getTextSecondary(context),
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

    if (_residents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.userX,
              size: 40,
              color: AppColors.getTextSecondary(context),
            ),
            const SizedBox(height: 10),
            Text(
              "No resident records found",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Try adjusting your search criteria or active filters.",
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
      itemCount: _residents.length + (_hasMore ? 1 : 1),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _residents.length) {
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
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Loading next 15 residents...",
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
                  "— End of Municipal Resident Registry (${_residents.length} citizens) —",
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

        final resident = _residents[index];
        return _buildResidentTile(resident, index + 1);
      },
    );
  }

  Widget _buildResidentTile(ResidentDirectoryItem resident, int indexNumber) {
    final isDark = AppColors.isDark(context);
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(resident.createdAt).toLocal();
    } catch (_) {}

    final dateStr = parsedDate != null
        ? _displayDateFormat.format(parsedDate)
        : resident.createdAt;

    return InkWell(
      onTap: () => _showResidentDetails(resident),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                  // Top Row: Full Name & Barangay
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          resident.fullName,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          resident.barangay,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF38BDF8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Demographics & Sector Tags
                  Row(
                    children: [
                      // Gender tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          resident.gender.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),

                      // Civil status tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          resident.civilStatus.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ),

                      const SizedBox(width: 5),

                      // Sector badges
                      if (resident.isSenior) ...[
                        _buildMiniSectorTag("SR", const Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                      ],
                      if (resident.isPWD) ...[
                        _buildMiniSectorTag("PWD", const Color(0xFF10B981)),
                        const SizedBox(width: 4),
                      ],
                      if (resident.isSoloParent) ...[
                        _buildMiniSectorTag("SOLO", const Color(0xFFEC4899)),
                        const SizedBox(width: 4),
                      ],
                      if (resident.is4Ps) ...[
                        _buildMiniSectorTag("4PS", const Color(0xFF8B5CF6)),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Subtitle: ID & Onboarded Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        resident.contactNumber != null && resident.contactNumber!.isNotEmpty
                            ? resident.contactNumber!
                            : "ID: ${resident.id.substring(0, resident.id.length > 8 ? 8 : resident.id.length)}",
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      Text(
                        "Onboarded $dateStr",
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
      ),
    );
  }

  Widget _buildMiniSectorTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}



