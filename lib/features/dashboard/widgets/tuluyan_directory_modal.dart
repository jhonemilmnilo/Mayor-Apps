import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/admin_service_model.dart';

class TuluyanDirectoryModal extends ConsumerStatefulWidget {
  const TuluyanDirectoryModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TuluyanDirectoryModal(),
    );
  }

  @override
  ConsumerState<TuluyanDirectoryModal> createState() => _TuluyanDirectoryModalState();
}

class _TuluyanDirectoryModalState extends ConsumerState<TuluyanDirectoryModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  final List<AccommodationItemModel> _accommodations = [];
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
    _fetchAccommodations(page: 1);
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
          _accommodations.clear();
        });
        _fetchAccommodations(page: 1);
      }
    });
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);
    await _fetchAccommodations(page: _currentPage + 1);
  }

  Future<void> _fetchAccommodations({required int page}) async {
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
        AppConstants.tuluyanEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (res.data != null && res.data['success'] == true) {
        final rawList = res.data['accommodations'] as List? ?? [];
        final totalCount = (res.data['totalCount'] as num?)?.toInt() ?? 0;
        final hasMore = res.data['hasMore'] == true;

        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _totalCount = totalCount;
          _hasMore = hasMore;
          if (page == 1) _accommodations.clear();
          _accommodations.addAll(rawList.map((e) => AccommodationItemModel.fromJson(e)).toList());
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        throw Exception(res.data?['error'] ?? "Failed to load accommodations.");
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

  void _showDetailSheet(AccommodationItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TuluyanDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hotel_rounded, color: Color(0xFF0EA5E9), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "TULUYAN HUB DIRECTORY",
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
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$_totalCount",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0EA5E9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Municipal Lodgings, Staycations & Accommodations",
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search lodging, resort or location...",
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _currentPage = 1;
                              _hasMore = true;
                              _accommodations.clear();
                            });
                            _fetchAccommodations(page: 1);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(child: _buildListContent()),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
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
              Text("Unable to load accommodations", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => _fetchAccommodations(page: 1),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
                child: const Text("Retry", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_accommodations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hotel_class_rounded, color: Color(0xFF0EA5E9), size: 36),
            const SizedBox(height: 10),
            Text("No accommodations found", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _accommodations.length + (_hasMore ? 1 : (_accommodations.isNotEmpty ? 1 : 0)),
      itemBuilder: (context, index) {
        if (index == _accommodations.length) {
          if (_hasMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9), strokeWidth: 2)),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "— End of Tuluyan Directory (${_accommodations.length} loaded) —",
                  style: GoogleFonts.inter(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                ),
              ),
            );
          }
        }

        final item = _accommodations[index];
        return GestureDetector(
          onTap: () => _showDetailSheet(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: AppColors.surfaceElevated,
                    child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Center(
                              child: Icon(Icons.hotel_rounded, size: 20, color: Color(0xFF0EA5E9)),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.hotel_rounded, size: 20, color: Color(0xFF0EA5E9)),
                          ),
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
                            child: Text(
                              item.name,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w900, color: const Color(0xFF0EA5E9)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${item.address} • ${item.barangay}",
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.priceRange != null && item.priceRange!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          "Rate: ${item.priceRange}",
                          style: GoogleFonts.inter(fontSize: 9.5, fontStyle: FontStyle.italic, color: const Color(0xFF10B981)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TuluyanDetailSheet extends StatelessWidget {
  final AccommodationItemModel item;
  const _TuluyanDetailSheet({required this.item});

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: "${item.name}, ${item.address}"));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0EA5E9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text("Address copied to clipboard!", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(item.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          Text(item.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text("${item.type} • ${item.barangay}", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0EA5E9), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(item.description.isNotEmpty ? item.description : "Official lodging and accommodation facility in Mapandan.", style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ACCOMMODATION DETAILS", style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(item.address, style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                if (item.priceRange != null) ...[
                  const SizedBox(height: 4),
                  Text("Estimated Rate: ${item.priceRange}", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981))),
                ],
                if (item.amenities != null) ...[
                  const SizedBox(height: 4),
                  Text("Amenities: ${item.amenities}", style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                ],
                if (item.contactNumber != null) ...[
                  const SizedBox(height: 4),
                  Text("Contact: ${item.contactNumber}", style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _copyAddress(context),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text("COPY ADDRESS & LOCATION"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
