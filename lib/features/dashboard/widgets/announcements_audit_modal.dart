import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/announcement_item_model.dart';
import 'announcement_detail_bottom_sheet.dart';
import 'announcement_filter_modal.dart';

class AnnouncementsAuditModal extends ConsumerStatefulWidget {
  final List<AnnouncementItemModel>? fallbackAnnouncements;
  final AnnouncementFilterState initialFilter;

  const AnnouncementsAuditModal({
    super.key,
    this.fallbackAnnouncements,
    this.initialFilter = const AnnouncementFilterState(),
  });

  static Future<void> show(
    BuildContext context, {
    List<AnnouncementItemModel>? fallbackAnnouncements,
    AnnouncementFilterState initialFilter = const AnnouncementFilterState(),
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnnouncementsAuditModal(
        fallbackAnnouncements: fallbackAnnouncements,
        initialFilter: initialFilter,
      ),
    );
  }

  @override
  ConsumerState<AnnouncementsAuditModal> createState() =>
      _AnnouncementsAuditModalState();
}

class _AnnouncementsAuditModalState
    extends ConsumerState<AnnouncementsAuditModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  late AnnouncementFilterState _filterState;
  final List<AnnouncementItemModel> _announcements = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _errorMessage;

  AnnouncementStats _stats = const AnnouncementStats();

  @override
  void initState() {
    super.initState();
    _filterState = widget.initialFilter;
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

  // 400ms Debounce search as requested
  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
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
      _announcements.clear();
    });
    await _fetchAnnouncements(page: 1);
  }

  Future<void> _loadInitialPage() async {
    await _fetchAnnouncements(page: 1);
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchAnnouncements(page: _currentPage + 1);
  }

  Future<void> _fetchAnnouncements({required int page}) async {
    try {
      final apiClient = ref.read(apiClientProvider);

      if (page == 1) {
        _cancelToken?.cancel("New search or filter request");
        _cancelToken = CancelToken();
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': 15,
      };

      if (_filterState.priority != 'All') {
        queryParams['priority'] = _filterState.priority;
      }

      if (_filterState.category != 'All') {
        queryParams['category'] = _filterState.category;
      }

      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        queryParams['search'] = query;
      }

      final response = await apiClient.dio.get(
        AppConstants.announcementsEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (response.data != null && response.data['success'] == true) {
        final parsed = AnnouncementQueryResponse.fromJson(response.data);

        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _hasMore = parsed.hasMore;
          _stats = parsed.stats;
          _totalCount = parsed.totalCount;

          if (page == 1) {
            _announcements.clear();
          }
          _announcements.addAll(parsed.announcements);
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      } else {
        throw Exception(
          response.data?['error'] ?? "Failed to fetch notices.",
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;

      if (page == 1 &&
          widget.fallbackAnnouncements != null &&
          widget.fallbackAnnouncements!.isNotEmpty) {
        _useFallbackData();
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = e.message ?? "Network error fetching notices.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (page == 1 &&
          widget.fallbackAnnouncements != null &&
          widget.fallbackAnnouncements!.isNotEmpty) {
        _useFallbackData();
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _useFallbackData() {
    final list = widget.fallbackAnnouncements ?? [];
    final search = _searchController.text.trim().toLowerCase();

    final filtered = list.where((a) {
      if (_filterState.priority != 'All' &&
          a.priority.toUpperCase() != _filterState.priority.toUpperCase()) {
        return false;
      }
      if (_filterState.category != 'All' &&
          a.category.toUpperCase() != _filterState.category.toUpperCase()) {
        return false;
      }
      if (search.isNotEmpty) {
        final matchTitle = a.title.toLowerCase().contains(search);
        final matchContent = a.content.toLowerCase().contains(search);
        if (!matchTitle && !matchContent) return false;
      }
      return true;
    }).toList();

    final pinnedCount = list.where((a) => a.isPinned && a.isActive).length;
    final criticalCount = list.where((a) {
      final p = a.priority.toUpperCase();
      return (p == 'CRITICAL' || p == 'URGENT' || p == 'HIGH') && a.isActive;
    }).length;

    setState(() {
      _announcements.clear();
      _announcements.addAll(filtered);
      _totalCount = filtered.length;
      _stats = AnnouncementStats(
        totalNotices: list.length,
        pinnedBriefs: pinnedCount,
        criticalAlerts: criticalCount,
      );
      _hasMore = false;
      _isLoading = false;
      _isLoadingMore = false;
      _errorMessage = null;
    });
  }

  void _openFilterModal() {
    AnnouncementFilterModal.show(
      context,
      initialFilter: _filterState,
      onApply: (newFilter) {
        setState(() {
          _filterState = newFilter;
        });
        _resetAndReload();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.92;
    final isDark = AppColors.isDark(context);

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.getBorder(context), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.accentAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: AppColors.accentAmber,
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
                          Text(
                            "ANNOUNCEMENTS DIRECTORY",
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -0.2,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$_totalCount",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accentAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Official Executive Notices & Community Advisories",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.getTextSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: AppColors.getTextSecondary(context), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // 3 Executive KPI Cards (MayorAnnouncementCards.tsx 100% parity)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: "TOTAL NOTICES",
                    count: _stats.totalNotices,
                    icon: Icons.campaign_rounded,
                    color: AppColors.accentAmber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: "PINNED BRIEFS",
                    count: _stats.pinnedBriefs,
                    icon: Icons.push_pin_rounded,
                    color: const Color(0xFFF97316),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: "CRITICAL ALERTS",
                    count: _stats.criticalAlerts,
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Search Bar (with 400ms debounce) + Filter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.getBorder(context)),
                      boxShadow: isDark ? [] : AppColors.getCardShadow(context),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(context),
                      ),
                      decoration: InputDecoration(
                        hintText: "Search title or details...",
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.getTextSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.getTextSecondary(context), size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, size: 16, color: AppColors.getTextSecondary(context)),
                                onPressed: () {
                                  _searchController.clear();
                                  _resetAndReload();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter Trigger Button
                GestureDetector(
                  onTap: _openFilterModal,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _filterState.isFiltered
                          ? AppColors.accentAmber.withValues(alpha: 0.18)
                          : AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _filterState.isFiltered ? AppColors.accentAmber : AppColors.getBorder(context),
                        width: _filterState.isFiltered ? 1.5 : 1,
                      ),
                      boxShadow: (!isDark && !_filterState.isFiltered) ? AppColors.getCardShadow(context) : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: _filterState.isFiltered ? AppColors.accentAmber : AppColors.getTextSecondary(context),
                        ),
                        if (_filterState.isFiltered) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.accentAmber,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${_filterState.activeFilterCount}",
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Horizontal Priority Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildPriorityChip('All', 'All Priorities'),
                const SizedBox(width: 6),
                _buildPriorityChip('Critical', 'Critical'),
                const SizedBox(width: 6),
                _buildPriorityChip('High', 'High'),
                const SizedBox(width: 6),
                _buildPriorityChip('Urgent', 'Urgent'),
                const SizedBox(width: 6),
                _buildPriorityChip('Important', 'Important'),
                const SizedBox(width: 6),
                _buildPriorityChip('Normal', 'Normal'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Announcements List View (Infinite Scroll)
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accentAmber,
              onRefresh: _resetAndReload,
              child: _buildListContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: isDark ? [] : AppColors.getCardShadow(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppColors.getTextSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "$count",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label) {
    final isSelected = _filterState.priority.toUpperCase() == value.toUpperCase();
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterState = _filterState.copyWith(priority: value);
        });
        _resetAndReload();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentAmber.withValues(alpha: isDark ? 0.2 : 0.15)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accentAmber : AppColors.getBorder(context),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: (!isSelected && !isDark) ? AppColors.getCardShadow(context) : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (isDark ? Colors.white : AppColors.accentAmber)
                : AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentAmber),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 36),
              const SizedBox(height: 10),
              Text(
                "Unable to load notices",
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(context)),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.getTextSecondary(context)),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _resetAndReload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentAmber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign_outlined, color: AppColors.accentAmber, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                "No announcements found",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Try adjusting your search or priority/category filters.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _announcements.length + (_hasMore ? 1 : (_announcements.isNotEmpty ? 1 : 0)),
      itemBuilder: (context, index) {
        if (index == _announcements.length) {
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
                        color: AppColors.accentAmber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Loading next 15 notices...",
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "— End of Announcements Directory (${_announcements.length} loaded) —",
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

        final item = _announcements[index];
        return _buildAnnouncementRow(item);
      },
    );
  }

  Widget _buildAnnouncementRow(AnnouncementItemModel item) {
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: () => AnnouncementDetailBottomSheet.show(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: isDark ? [] : AppColors.getCardShadow(context),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.priorityBadgeBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: item.priorityColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                item.priority.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                  color: item.priorityColor,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Title + Category + Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isPinned) ...[
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 11,
                          color: Color(0xFFF97316),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${item.category} · ${item.formattedDate}",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status Indicator (Active / Expired)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: item.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.statusText,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
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
}
