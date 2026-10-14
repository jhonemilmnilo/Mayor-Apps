import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/activity_log_model.dart';

class ActivityLogsAuditModal extends ConsumerStatefulWidget {
  const ActivityLogsAuditModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ActivityLogsAuditModal(),
    );
  }

  @override
  ConsumerState<ActivityLogsAuditModal> createState() => _ActivityLogsAuditModalState();
}

class _ActivityLogsAuditModalState extends ConsumerState<ActivityLogsAuditModal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  final List<ActivityLogItemModel> _logs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _errorMessage;

  String _selectedType = 'ALL'; // 'ALL', 'RESIDENT', 'REPORT', 'PAYMENT', 'TRANSACTION'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchLogs(page: 1);
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
          _logs.clear();
        });
        _fetchLogs(page: 1);
      }
    });
  }

  void _onTypeFilterChanged(String type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      _currentPage = 1;
      _hasMore = true;
      _logs.clear();
    });
    _fetchLogs(page: 1);
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);
    await _fetchLogs(page: _currentPage + 1);
  }

  Future<void> _fetchLogs({required int page}) async {
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
        'limit': 20,
      };

      if (_selectedType != 'ALL') {
        queryParams['type'] = _selectedType;
      }

      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final res = await apiClient.dio.get(
        AppConstants.activityLogsEndpoint,
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      if (res.data != null && res.data['success'] == true) {
        final rawList = res.data['logs'] as List? ?? [];
        final totalCount = (res.data['totalCount'] as num?)?.toInt() ?? 0;
        final hasMore = res.data['hasMore'] == true;

        if (!mounted) return;

        setState(() {
          _currentPage = page;
          _totalCount = totalCount;
          _hasMore = hasMore;
          if (page == 1) _logs.clear();
          _logs.addAll(rawList.map((e) => ActivityLogItemModel.fromJson(e)).toList());
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        throw Exception(res.data?['error'] ?? "Failed to load activity logs.");
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

  void _showDetailSheet(ActivityLogItemModel log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActivityDetailSheet(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentRose = Color(0xFFF43F5E); // Rose 500

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
                    color: accentRose.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: accentRose,
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
                            "ACTIVITY AUDIT LEDGER",
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
                              color: accentRose.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "$_totalCount",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: accentRose,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Unified Real-Time Municipal Event Stream",
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
                  hintText: "Search citizen name, service, or category...",
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

          const SizedBox(height: 10),

          // Stream Type Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: "ALL",
                    isSelected: _selectedType == 'ALL',
                    chipColor: accentRose,
                    onTap: () => _onTypeFilterChanged('ALL'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: "RESIDENTS",
                    icon: Icons.person_add_rounded,
                    isSelected: _selectedType == 'RESIDENT',
                    chipColor: const Color(0xFF3B82F6),
                    onTap: () => _onTypeFilterChanged('RESIDENT'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: "REPORTS",
                    icon: Icons.warning_amber_rounded,
                    isSelected: _selectedType == 'REPORT',
                    chipColor: const Color(0xFFF59E0B),
                    onTap: () => _onTypeFilterChanged('REPORT'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: "PAYMENTS",
                    icon: Icons.check_circle_outline_rounded,
                    isSelected: _selectedType == 'PAYMENT',
                    chipColor: const Color(0xFF10B981),
                    onTap: () => _onTypeFilterChanged('PAYMENT'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: "TRANSACTIONS",
                    icon: Icons.description_outlined,
                    isSelected: _selectedType == 'TRANSACTION',
                    chipColor: const Color(0xFFA855F7),
                    onTap: () => _onTypeFilterChanged('TRANSACTION'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),

          // Body Content
          Expanded(
            child: _buildBodyContent(accentRose),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color chipColor,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.16) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? chipColor.withValues(alpha: 0.6) : AppColors.border,
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
                color: isSelected ? chipColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? chipColor : AppColors.textSecondary,
                letterSpacing: 0.2,
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
                color: Color(0xFFF43F5E),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Loading activity stream...",
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
                "Failed to load activities",
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
                onPressed: () => _fetchLogs(page: 1),
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

    if (_logs.isEmpty) {
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
              child: const Icon(Icons.history_rounded, color: AppColors.textSecondary, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              "No Activities Found",
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              "Try searching for another keyword or change the category.",
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _logs.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == _logs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFF43F5E),
                ),
              ),
            ),
          );
        }

        final log = _logs[index];
        return _buildLogRow(log);
      },
    );
  }

  Widget _buildLogRow(ActivityLogItemModel log) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _showDetailSheet(log),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Node
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: log.typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: log.typeColor.withValues(alpha: 0.35)),
                ),
                child: Icon(log.typeIcon, size: 17, color: log.typeColor),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: log.typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.typeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: log.typeColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          log.time,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 12.5, height: 1.35),
                        children: [
                          TextSpan(
                            text: "${log.maskedUser} ",
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          TextSpan(
                            text: "${log.action} ",
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary.withValues(alpha: 0.9),
                            ),
                          ),
                          TextSpan(
                            text: log.details,
                            style: TextStyle(fontWeight: FontWeight.w800, color: log.typeColor),
                          ),
                        ],
                      ),
                    ),
                    if (log.barangay.isNotEmpty && log.barangay != 'Mapandan') ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            "Brgy. ${log.barangay}",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityDetailSheet extends StatelessWidget {
  final ActivityLogItemModel log;

  const _ActivityDetailSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Badge & Type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: log.typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log.typeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: log.typeColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                log.time,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            log.maskedUser,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${log.action} ${log.details}",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: log.typeColor,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Metadata Rows
          _buildDetailRow(
            icon: Icons.fingerprint_rounded,
            label: "Reference Stream ID",
            value: log.id,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.location_on_outlined,
            label: "Jurisdiction Barangay",
            value: log.barangay,
          ),
          if (log.createdAt != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.access_time_rounded,
              label: "Timestamp (PHT)",
              value: log.createdAt!.toLocal().toString().split('.').first,
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
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
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
