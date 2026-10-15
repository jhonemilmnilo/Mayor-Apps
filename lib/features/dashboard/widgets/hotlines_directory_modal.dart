import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/admin_service_model.dart';

class HotlinesDirectoryModal extends ConsumerStatefulWidget {
  const HotlinesDirectoryModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const HotlinesDirectoryModal(),
    );
  }

  @override
  ConsumerState<HotlinesDirectoryModal> createState() => _HotlinesDirectoryModalState();
}

class _HotlinesDirectoryModalState extends ConsumerState<HotlinesDirectoryModal> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  String _selectedCategory = 'ALL';
  final List<HotlineItemModel> _hotlines = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _categories = const [
    'ALL',
    'Emergency',
    'Medical',
    'Police',
    'Fire',
    'Disaster',
    'Utilities',
  ];

  @override
  void initState() {
    super.initState();
    _fetchHotlines();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _fetchHotlines();
    });
  }

  Future<void> _fetchHotlines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      _cancelToken?.cancel();
      _cancelToken = CancelToken();

      final queryParams = <String, dynamic>{};
      if (_selectedCategory != 'ALL') {
        queryParams['category'] = _selectedCategory;
      }
      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final res = await apiClient.dio.get(
        AppConstants.hotlinesEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (res.data != null && res.data['success'] == true) {
        final rawList = res.data['hotlines'] as List? ?? [];
        if (!mounted) return;
        setState(() {
          _hotlines.clear();
          _hotlines.addAll(rawList.map((e) => HotlineItemModel.fromJson(e)).toList());
          _isLoading = false;
        });
      } else {
        throw Exception(res.data?['error'] ?? "Failed to load hotlines.");
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? "Network error loading hotlines.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _copyNumber(String name, String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          "$name hotline ($number) copied!",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_rounded,
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
                          Text(
                            "EMERGENCY HOTLINES",
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
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${_hotlines.length}",
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
                        "Official 24/7 Police, Fire, Rescue & Public Safety Contacts",
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(context),
                ),
                decoration: InputDecoration(
                  hintText: "Search agency, department or phone...",
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
                            _fetchHotlines();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Horizontal Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _categories.map((c) {
                final isSelected = _selectedCategory.toUpperCase() == c.toUpperCase();
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = c);
                    _fetchHotlines();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                          : AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF8B5CF6) : AppColors.getBorder(context),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      c == 'ALL' ? 'All Hotlines' : c,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.getTextPrimary(context) : AppColors.getTextSecondary(context),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // List View
          Expanded(
            child: _buildListContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
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
                "Unable to load hotlines",
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(context)),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _fetchHotlines,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                child: const Text("Retry", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_hotlines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_disabled_rounded, color: Color(0xFF8B5CF6), size: 36),
            const SizedBox(height: 10),
            Text(
              "No hotlines found",
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.getTextPrimary(context)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _hotlines.length,
      itemBuilder: (context, index) {
        final item = _hotlines[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.getBorder(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.call_rounded, size: 18, color: Color(0xFF8B5CF6)),
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
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            item.category.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.primaryNumber,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    if (item.address != null && item.address!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.address!,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: AppColors.getTextSecondary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Copy button
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF8B5CF6)),
                onPressed: () => _copyNumber(item.name, item.primaryNumber),
                tooltip: "Copy number",
              ),
            ],
          ),
        );
      },
    );
  }
}
