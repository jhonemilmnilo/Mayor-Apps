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
        final rawList = res.data['spots'] as List? ?? [];
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
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: Colors.white24,
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
                          Text(
                            "TOURISM GALLERY DIRECTORY",
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -0.2,
                              color: Colors.white,
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
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Search tourist spot, category, or barangay...",
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 12.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 16),
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

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),

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
                color: AppColors.textSecondary,
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
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
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
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.landscape_rounded, color: AppColors.textSecondary, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              "No Tourist Spots Found",
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              "Try searching for another keyword or landmark.",
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
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

  Widget _buildSpotCard(TourismSpotItemModel spot, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetailSheet(spot),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Banner if available
            if (spot.imageUrl != null && spot.imageUrl!.isNotEmpty)
              SizedBox(
                height: 130,
                width: double.infinity,
                child: Image.network(
                  spot.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(spot, accentColor),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 130,
                      color: AppColors.surfaceElevated,
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spot.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
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

  Widget _buildImagePlaceholder(TourismSpotItemModel spot, Color accentColor) {
    return Container(
      height: 70,
      width: double.infinity,
      color: AppColors.surfaceElevated,
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
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color: Colors.white24,
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
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Brgy. ${spot.barangay}",
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    spot.name,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (spot.description.isNotEmpty) ...[
                    Text(
                      spot.description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Info items
                  _buildInfoTile(
                    icon: Icons.location_on_outlined,
                    label: "Location / Address",
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
                    const SizedBox(height: 10),
                    _buildInfoTile(
                      icon: Icons.confirmation_number_outlined,
                      label: "Entrance / Admission Fee",
                      value: spot.entranceFee!,
                    ),
                  ],

                  if (spot.bestTimeToVisit != null && spot.bestTimeToVisit!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildInfoTile(
                      icon: Icons.access_time_rounded,
                      label: "Best Time to Visit",
                      value: spot.bestTimeToVisit!,
                    ),
                  ],

                  if (spot.contactNumber != null && spot.contactNumber!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildInfoTile(
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
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
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

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
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
          Icon(icon, size: 18, color: const Color(0xFF10B981)),
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
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
              onPressed: onCopy,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
