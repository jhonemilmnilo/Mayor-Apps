import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/admin_service_model.dart';

class TourismDirectoryModal extends ConsumerStatefulWidget {
  const TourismDirectoryModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TourismDirectoryModal(),
    );
  }

  @override
  ConsumerState<TourismDirectoryModal> createState() => _TourismDirectoryModalState();
}

class _TourismDirectoryModalState extends ConsumerState<TourismDirectoryModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  final List<TourismSpotItemModel> _spots = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _errorMessage;
  String _selectedStatus = 'ALL'; // 'ALL', 'PUBLISHED', 'DRAFT'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchSpots(page: 1);
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
          _spots.clear();
        });
        _fetchSpots(page: 1);
      }
    });
  }

  void _onStatusFilterChanged(String status) {
    if (_selectedStatus == status) return;
    setState(() {
      _selectedStatus = status;
      _currentPage = 1;
      _hasMore = true;
      _spots.clear();
    });
    _fetchSpots(page: 1);
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);
    await _fetchSpots(page: _currentPage + 1);
  }

  Future<void> _fetchSpots({required int page}) async {
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
      };

      if (_selectedStatus != 'ALL') {
        queryParams['status'] = _selectedStatus;
      }

      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final res = await apiClient.dio.get(
        AppConstants.tourismEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (res.data != null && res.data['success'] == true) {
        final rawList = (res.data['tourismSpots'] ?? res.data['spots']) as List? ?? [];
        final totalCount = (res.data['totalCount'] as num?)?.toInt() ?? 0;
        final hasMore = res.data['hasMore'] == true;

        if (!mounted) return;

        setState(() {
          _currentPage = page;
          _totalCount = totalCount;
          _hasMore = hasMore;
          if (page == 1) _spots.clear();
          _spots.addAll(rawList.map((e) => TourismSpotItemModel.fromJson(e)).toList());
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        throw Exception(res.data?['error'] ?? "Failed to load tourism spots.");
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

  void _showDetailSheet(TourismSpotItemModel spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TourismDetailSheet(spot: spot),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF10B981); // Emerald

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
                color: (AppColors.isDark(context) ? Colors.white : Colors.black).withValues(alpha: 0.2),
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
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.landscape_rounded,
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
                                "TOURISM GALLERY",
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
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
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Municipal Attractions, Heritage Sites & Landmarks",
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

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Search tourist spot, category, or barangay...",
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.getTextSecondary(context).withValues(alpha: 0.7),
                    fontSize: 12.5,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.getTextSecondary(context),
                    size: 19,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Status Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusFilterChip(
                    label: "ALL SPOTS",
                    count: _selectedStatus == 'ALL' ? _totalCount : null,
                    isSelected: _selectedStatus == 'ALL',
                    chipColor: accentColor,
                    onTap: () => _onStatusFilterChanged('ALL'),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip(
                    label: "PUBLISHED",
                    icon: Icons.check_circle_rounded,
                    count: _selectedStatus == 'PUBLISHED' ? _totalCount : null,
                    isSelected: _selectedStatus == 'PUBLISHED',
                    chipColor: const Color(0xFF10B981),
                    onTap: () => _onStatusFilterChanged('PUBLISHED'),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusFilterChip(
                    label: "DRAFT / UNPUBLISHED",
                    icon: Icons.edit_note_rounded,
                    count: _selectedStatus == 'DRAFT' ? _totalCount : null,
                    isSelected: _selectedStatus == 'DRAFT',
                    chipColor: Colors.amber,
                    onTap: () => _onStatusFilterChanged('DRAFT'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.getBorder(context)),

          // Body Content
          Expanded(
            child: _buildBodyContent(accentColor),
          ),
        ],
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
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Loading tourism spots...",
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
                "Failed to load spots",
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
                onPressed: () => _fetchSpots(page: 1),
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

    if (_spots.isEmpty) {
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
              child: Icon(Icons.landscape_rounded, color: AppColors.getTextSecondary(context), size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              "No Tourist Spots Found",
              style: GoogleFonts.inter(color: AppColors.getTextPrimary(context), fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              "Try searching for another keyword or landmark.",
              style: GoogleFonts.inter(color: AppColors.getTextSecondary(context), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _spots.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _spots.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          );
        }

        final spot = _spots[index];
        return _buildSpotCard(spot, accentColor);
      },
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required bool isSelected,
    required Color chipColor,
    required VoidCallback onTap,
    IconData? icon,
    int? count,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.16)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? chipColor.withValues(alpha: 0.6)
                : AppColors.getBorder(context),
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? chipColor : AppColors.getTextSecondary(context),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? chipColor : AppColors.getTextSecondary(context),
                letterSpacing: 0.2,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? chipColor : AppColors.getBorder(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "$count",
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.black : AppColors.getTextSecondary(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpotCard(TourismSpotItemModel spot, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !spot.isPublished
              ? Colors.amber.withValues(alpha: 0.35)
              : AppColors.getBorder(context),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetailSheet(spot),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Banner with Floating Status Badge
            Stack(
              children: [
                if (spot.imageUrl != null && spot.imageUrl!.isNotEmpty)
                  SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Image.network(
                      spot.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImagePlaceholder(spot, accentColor),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 130,
                          color: AppColors.getSurfaceElevated(context),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  _buildImagePlaceholder(spot, accentColor),

                // Top-right floating status indicator pill
                Positioned(
                  top: 9,
                  right: 9,
                  child: _buildCardStatusBadge(spot.isPublished),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          spot.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (!spot.isPublished) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_note_rounded, size: 12, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(
                                "DRAFT",
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (spot.entranceFee != null && spot.entranceFee!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.confirmation_number_outlined, size: 11, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                spot.entranceFee!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    spot.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spot.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.getTextSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (spot.bestTimeToVisit != null && spot.bestTimeToVisit!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          "Best time: ${spot.bestTimeToVisit}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "VIEW DETAILS",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: accentColor),
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

  Widget _buildCardStatusBadge(bool isPublished) {
    if (isPublished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "PUBLISHED",
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_note_rounded, size: 12, color: Colors.amber),
            const SizedBox(width: 3),
            Text(
              "DRAFT",
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildImagePlaceholder(TourismSpotItemModel spot, Color accentColor) {
    return Container(
      height: 70,
      width: double.infinity,
      color: AppColors.getSurfaceElevated(context),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          color: accentColor.withValues(alpha: 0.4),
          size: 32,
        ),
      ),
    );
  }
}

class _TourismDetailSheet extends StatelessWidget {
  final TourismSpotItemModel spot;

  const _TourismDetailSheet({required this.spot});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF10B981);

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
                  // Image if available
                  if (spot.imageUrl != null && spot.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: Image.network(
                          spot.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Badge & Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          spot.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceElevated(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          spot.barangay.isNotEmpty && spot.barangay != 'Mapandan'
                              ? "Brgy. ${spot.barangay}"
                              : "Mapandan",
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: spot.isPublished
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: spot.isPublished
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : Colors.amber.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              spot.isPublished
                                  ? Icons.check_circle_rounded
                                  : Icons.edit_note_rounded,
                              size: 13,
                              color: spot.isPublished
                                  ? const Color(0xFF10B981)
                                  : Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              spot.isPublished ? "PUBLISHED" : "DRAFT",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: spot.isPublished
                                  ? const Color(0xFF10B981)
                                  : Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (!spot.isPublished) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Executive Note: This spot is currently saved as DRAFT and is not yet published to the public citizen portal.",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.amber.shade200,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  Text(
                    spot.name,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (spot.description.isNotEmpty) ...[
                    Text(
                      spot.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.getTextSecondary(context),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  Divider(height: 1, color: AppColors.getBorder(context)),
                  const SizedBox(height: 14),

                  // Compact Plain Text Info Rows (no cards)
                  _buildInfoRow(
                    context: context,
                    icon: Icons.location_on_outlined,
                    label: "Location",
                    value: spot.address,
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: spot.address));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Address copied to clipboard!"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  if (spot.entranceFee != null && spot.entranceFee!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.confirmation_number_outlined,
                      label: "Entrance Fee",
                      value: spot.entranceFee!,
                    ),
                  ],

                  if (spot.bestTimeToVisit != null && spot.bestTimeToVisit!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.access_time_rounded,
                      label: "Best Time to Visit",
                      value: spot.bestTimeToVisit!,
                    ),
                  ],

                  if (spot.contactNumber != null && spot.contactNumber!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.phone_outlined,
                      label: "Contact Inquiry",
                      value: spot.contactNumber!,
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: spot.contactNumber!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Contact number copied to clipboard!"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],

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
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.getBorder(context)),
                  ),
                ),
                child: Text(
                  "CLOSE",
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

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: const Color(0xFF10B981)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 12.5, height: 1.4),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Icons.copy_rounded,
                  size: 13,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

