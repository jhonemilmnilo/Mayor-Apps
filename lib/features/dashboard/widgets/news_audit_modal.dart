import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/news_item_model.dart';
import 'news_detail_bottom_sheet.dart';
import 'news_filter_modal.dart';

class NewsAuditModal extends ConsumerStatefulWidget {
  final List<NewsItemModel>? fallbackNews;
  final NewsFilterCriteria initialFilter;

  const NewsAuditModal({
    super.key,
    this.fallbackNews,
    this.initialFilter = const NewsFilterCriteria(),
  });

  static Future<void> show(
    BuildContext context, {
    List<NewsItemModel>? fallbackNews,
    NewsFilterCriteria initialFilter = const NewsFilterCriteria(),
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewsAuditModal(
        fallbackNews: fallbackNews,
        initialFilter: initialFilter,
      ),
    );
  }

  @override
  ConsumerState<NewsAuditModal> createState() => _NewsAuditModalState();
}

class _NewsAuditModalState extends ConsumerState<NewsAuditModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  late NewsFilterCriteria _filterState;
  final List<NewsItemModel> _news = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _errorMessage;

  NewsStats _stats = const NewsStats();

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
      _news.clear();
    });
    await _fetchNews(page: 1);
  }

  Future<void> _loadInitialPage() async {
    await _fetchNews(page: 1);
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchNews(page: _currentPage + 1);
  }

  Future<void> _fetchNews({required int page}) async {
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

      if (_filterState.status != 'ALL') {
        queryParams['status'] = _filterState.status;
      }

      if (_filterState.category != 'ALL') {
        queryParams['category'] = _filterState.category;
      }

      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        queryParams['search'] = query;
      }

      final response = await apiClient.dio.get(
        AppConstants.newsEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (response.data != null && response.data['success'] == true) {
        final parsed = PaginatedNewsResponse.fromJson(response.data);

        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _hasMore = parsed.hasMore;
          _stats = parsed.stats;
          _totalCount = parsed.totalCount;

          if (page == 1) {
            _news.clear();
          }
          _news.addAll(parsed.news);
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      } else {
        throw Exception(
          response.data?['error'] ?? "Failed to fetch municipal news.",
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;

      if (page == 1 &&
          widget.fallbackNews != null &&
          widget.fallbackNews!.isNotEmpty) {
        _useFallbackData();
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = e.message ?? "Network error fetching news.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (page == 1 &&
          widget.fallbackNews != null &&
          widget.fallbackNews!.isNotEmpty) {
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
    final list = widget.fallbackNews ?? [];
    final search = _searchController.text.trim().toLowerCase();

    final filtered = list.where((item) {
      if (_filterState.status != 'ALL') {
        final targetPub = _filterState.status.toUpperCase() == 'PUBLISHED';
        if (item.isPublished != targetPub) return false;
      }
      if (_filterState.category != 'ALL' &&
          item.category.toUpperCase() != _filterState.category.toUpperCase()) {
        return false;
      }
      if (search.isNotEmpty) {
        final matchTitle = item.title.toLowerCase().contains(search);
        final matchContent = item.content.toLowerCase().contains(search);
        final matchAuthor = item.author.toLowerCase().contains(search);
        if (!matchTitle && !matchContent && !matchAuthor) return false;
      }
      return true;
    }).toList();

    final announcementCount = list.where((a) {
      final cat = a.category.toLowerCase();
      return cat.contains('announcement') || cat.contains('advisory');
    }).length;

    final localNewsCount = list.where((a) {
      final cat = a.category.toLowerCase();
      return cat.contains('local') || cat.contains('community');
    }).length;

    setState(() {
      _news.clear();
      _news.addAll(filtered);
      _totalCount = filtered.length;
      _stats = NewsStats(
        totalArticles: list.length,
        announcements: announcementCount,
        localNews: localNewsCount,
      );
      _hasMore = false;
      _isLoading = false;
      _isLoadingMore = false;
      _errorMessage = null;
    });
  }

  void _openFilterModal() {
    NewsFilterModal.show(
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
                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.newspaper_rounded,
                    color: Color(0xFF3B82F6),
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
                            "MUNICIPAL NEWS DIRECTORY",
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
                              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$_totalCount",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Official Press Releases & Municipal News Feed",
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

          // 3 Executive KPI Cards (MayorNewsCards.tsx 100% parity)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: "TOTAL ARTICLES",
                    count: _stats.totalArticles,
                    icon: Icons.newspaper_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: "ANNOUNCEMENTS",
                    count: _stats.announcements,
                    icon: Icons.campaign_rounded,
                    color: AppColors.accentAmber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    title: "LOCAL NEWS",
                    count: _stats.localNews,
                    icon: Icons.auto_stories_rounded,
                    color: AppColors.accentGreen,
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
                        hintText: "Search title, author or details...",
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
                          ? const Color(0xFF2563EB).withValues(alpha: 0.18)
                          : AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _filterState.isFiltered ? const Color(0xFF3B82F6) : AppColors.getBorder(context),
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
                          color: _filterState.isFiltered ? const Color(0xFF3B82F6) : AppColors.getTextSecondary(context),
                        ),
                        if (_filterState.isFiltered) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
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

          // Horizontal Quick Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildCategoryChip('ALL', 'All Categories'),
                const SizedBox(width: 6),
                _buildCategoryChip('Local News', 'Local News'),
                const SizedBox(width: 6),
                _buildCategoryChip('Announcement', 'Announcements'),
                const SizedBox(width: 6),
                _buildCategoryChip('Agriculture & Livelihood', 'Agriculture & Livelihood'),
                const SizedBox(width: 6),
                _buildCategoryChip('Public Advisory', 'Public Advisory'),
                const SizedBox(width: 6),
                _buildCategoryChip('Health & Wellness', 'Health & Wellness'),
              ],
            ),
          ),

          // Status Filter active indicator if status != 'ALL'
          if (_filterState.status != 'ALL') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (_filterState.status == 'PUBLISHED'
                              ? AppColors.accentGreen
                              : AppColors.accentAmber)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_filterState.status == 'PUBLISHED'
                                ? AppColors.accentGreen
                                : AppColors.accentAmber)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "STATUS: ${_filterState.status}",
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _filterState.status == 'PUBLISHED'
                                ? AppColors.accentGreen
                                : AppColors.accentAmber,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _filterState = _filterState.copyWith(status: 'ALL');
                            });
                            _resetAndReload();
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // News Directory List View (Infinite Scroll)
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF3B82F6),
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "$count",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.getTextPrimary(context),
                    ),
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

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _filterState.category.toUpperCase() == value.toUpperCase();
    final isDark = AppColors.isDark(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterState = _filterState.copyWith(category: value);
        });
        _resetAndReload();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.15)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : AppColors.getBorder(context),
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
                ? (isDark ? Colors.white : const Color(0xFF2563EB))
                : AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
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
                "Unable to load news articles",
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
                  backgroundColor: const Color(0xFF2563EB),
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

    if (_news.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.newspaper_outlined, color: Color(0xFF3B82F6), size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                "No news articles found",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Try adjusting your search or category/status filters.",
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
      itemCount: _news.length + (_hasMore ? 1 : (_news.isNotEmpty ? 1 : 0)),
      itemBuilder: (context, index) {
        if (index == _news.length) {
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
                      "Loading next 15 articles...",
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
                  "— End of Municipal News Directory (${_news.length} loaded) —",
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

        final item = _news[index];
        return _buildNewsRow(item);
      },
    );
  }

  Widget _buildNewsRow(NewsItemModel item) {
    final isDark = AppColors.isDark(context);
    return GestureDetector(
      onTap: () => NewsDetailBottomSheet.show(context, item),
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
            // Thumbnail with multi-image badge
            Stack(
              clipBehavior: Clip.none,
              children: [
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
                                Icons.newspaper_rounded,
                                size: 22,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.newspaper_rounded,
                              size: 22,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                  ),
                ),
                if (item.hasGallery)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_rounded, size: 9, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            "${item.totalMediaCount}",
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Title + Category + Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.10),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.25 : 0.20),
                          ),
                        ),
                        child: Text(
                          item.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF3B82F6),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${item.author} • ${item.formattedDate}",
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status Badge Dot
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
                      item.statusText,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextSecondary(context),
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
