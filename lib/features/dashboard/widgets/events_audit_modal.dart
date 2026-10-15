import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/event_item_model.dart';
import 'event_detail_bottom_sheet.dart';
import 'event_filter_modal.dart';

class EventsAuditModal extends ConsumerStatefulWidget {
  final List<EventItemModel>? fallbackEvents;
  final EventFilterCriteria initialFilter;

  const EventsAuditModal({
    super.key,
    this.fallbackEvents,
    this.initialFilter = const EventFilterCriteria(),
  });

  static Future<void> show(
    BuildContext context, {
    List<EventItemModel>? fallbackEvents,
    EventFilterCriteria initialFilter = const EventFilterCriteria(),
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EventsAuditModal(
        fallbackEvents: fallbackEvents,
        initialFilter: initialFilter,
      ),
    );
  }

  @override
  ConsumerState<EventsAuditModal> createState() => _EventsAuditModalState();
}

class _EventsAuditModalState extends ConsumerState<EventsAuditModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  late EventFilterCriteria _filterState;
  final List<EventItemModel> _events = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _errorMessage;

  EventStats _stats = const EventStats();

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

  // 400ms Debounce search
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
      _events.clear();
    });
    await _fetchEvents(page: 1);
  }

  Future<void> _loadInitialPage() async {
    await _fetchEvents(page: 1);
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchEvents(page: _currentPage + 1);
  }

  Future<void> _fetchEvents({required int page}) async {
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

      if (_filterState.timeframe != 'ALL') {
        queryParams['timeframe'] = _filterState.timeframe;
      }

      if (_filterState.category != 'ALL') {
        queryParams['category'] = _filterState.category;
      }

      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        queryParams['search'] = query;
      }

      final response = await apiClient.dio.get(
        AppConstants.eventsEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (response.data != null && response.data['success'] == true) {
        final parsed = PaginatedEventsResponse.fromJson(response.data);

        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _hasMore = parsed.hasMore;
          _stats = parsed.stats;
          _totalCount = parsed.totalCount;

          if (page == 1) {
            _events.clear();
          }
          _events.addAll(parsed.events);
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      } else {
        throw Exception(
          response.data?['error'] ?? "Failed to fetch municipal events.",
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;

      if (page == 1 &&
          widget.fallbackEvents != null &&
          widget.fallbackEvents!.isNotEmpty) {
        _useFallbackData();
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = e.message ?? "Network error fetching events.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (page == 1 &&
          widget.fallbackEvents != null &&
          widget.fallbackEvents!.isNotEmpty) {
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
    final list = widget.fallbackEvents ?? [];
    final search = _searchController.text.trim().toLowerCase();

    final filtered = list.where((item) {
      if (_filterState.timeframe != 'ALL') {
        final tf = _filterState.timeframe.toUpperCase();
        if (tf == 'LIVE' && !item.isLiveNow) return false;
        if (tf == 'UPCOMING' && !item.isUpcoming) return false;
        if (tf == 'ENDED' && !item.isEnded) return false;
      }
      if (_filterState.category != 'ALL' &&
          item.category.toUpperCase() != _filterState.category.toUpperCase()) {
        return false;
      }
      if (search.isNotEmpty) {
        final matchTitle = item.title.toLowerCase().contains(search);
        final matchVenue = item.venueName.toLowerCase().contains(search);
        final matchDesc = item.description.toLowerCase().contains(search);
        if (!matchTitle && !matchVenue && !matchDesc) return false;
      }
      return true;
    }).toList();

    final liveCount = list.where((e) => e.isLiveNow).length;
    final upcomingCount = list.where((e) => e.isUpcoming).length;
    final festivalCount = list.where((e) {
      final c = e.category.toLowerCase();
      return c.contains('festival') || c.contains('fiesta');
    }).length;

    setState(() {
      _events.clear();
      _events.addAll(filtered);
      _totalCount = filtered.length;
      _stats = EventStats(
        totalEvents: list.length,
        happeningNow: liveCount,
        upcomingEvents: upcomingCount,
        festivals: festivalCount,
      );
      _hasMore = false;
      _isLoading = false;
      _isLoadingMore = false;
      _errorMessage = null;
    });
  }

  void _openFilterModal() {
    EventFilterModal.show(
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
    final isDark = AppColors.isDark(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
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
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF8B5CF6),
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
                                "MUNICIPAL EVENTS",
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
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$_totalCount",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Official Festivals, Sports & Civic Gatherings",
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

          // 4 Executive KPI Cards (MayorEventsCards.tsx 100% parity)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: "TOTAL EVENTS",
                    count: _stats.totalEvents,
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildKpiCard(
                    title: "LIVE NOW",
                    count: _stats.happeningNow,
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildKpiCard(
                    title: "UPCOMING",
                    count: _stats.upcomingEvents,
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildKpiCard(
                    title: "FESTIVALS",
                    count: _stats.festivals,
                    icon: Icons.star_rounded,
                    color: const Color(0xFFEC4899),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Search Bar (400ms debounce) + Filter Button
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
                        hintText: "Search event, venue or activity...",
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
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.18)
                          : AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _filterState.isFiltered ? const Color(0xFF8B5CF6) : AppColors.getBorder(context),
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
                          color: _filterState.isFiltered ? const Color(0xFF8B5CF6) : AppColors.getTextSecondary(context),
                        ),
                        if (_filterState.isFiltered) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
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

          // Horizontal Quick Timeframe Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildTimeframeChip('ALL', 'All Events'),
                const SizedBox(width: 6),
                _buildTimeframeChip('LIVE', '🔴 Live Now'),
                const SizedBox(width: 6),
                _buildTimeframeChip('UPCOMING', '🕒 Upcoming'),
                const SizedBox(width: 6),
                _buildTimeframeChip('ENDED', '📜 Ended / Past'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Events Directory List View (Infinite Scroll)
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF8B5CF6),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: isDark ? [] : AppColors.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  "$count",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              color: AppColors.getTextSecondary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeChip(String value, String label) {
    final isSelected = _filterState.timeframe.toUpperCase() == value.toUpperCase();
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterState = _filterState.copyWith(timeframe: value);
        });
        _resetAndReload();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.15)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : AppColors.getBorder(context),
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
                ? (isDark ? Colors.white : const Color(0xFF8B5CF6))
                : AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
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
                "Unable to load events",
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
                  backgroundColor: const Color(0xFF8B5CF6),
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

    if (_events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_busy_rounded, color: Color(0xFF8B5CF6), size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                "No events found",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Try adjusting your timeframe, category or search query.",
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
      itemCount: _events.length + (_hasMore ? 1 : (_events.isNotEmpty ? 1 : 0)),
      itemBuilder: (context, index) {
        if (index == _events.length) {
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
                      "Loading next 15 events...",
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
                  "— End of Municipal Events Directory (${_events.length} loaded) —",
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

        final item = _events[index];
        return _buildEventRow(item);
      },
    );
  }

  Widget _buildEventRow(EventItemModel item) {
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: () => EventDetailBottomSheet.show(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: isDark ? [] : AppColors.getCardShadow(context),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Thumbnail preview or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 52,
                height: 52,
                color: isDark ? AppColors.surfaceElevated : const Color(0xFFE2E8F0),
                child: (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty)
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Center(
                          child: Icon(
                            Icons.calendar_month_rounded,
                            size: 22,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.calendar_month_rounded,
                          size: 22,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Middle: Title + Venue + Schedule
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.15 : 0.10),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.20),
                          ),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                      if (item.barangay.isNotEmpty &&
                          item.barangay.toLowerCase() != 'whole municipality') ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "• ${item.barangay}",
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextPrimary(context),
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${item.venueName} • ${item.formattedDateRange}",
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: AppColors.getTextSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right: Status indicator
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                      item.statusLabel,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: item.statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.getTextSecondary(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
