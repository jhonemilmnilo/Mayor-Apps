import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';

class NewsFilterCriteria {
  final String status; // 'ALL', 'PUBLISHED', 'DRAFT'
  final String category; // 'ALL' or specific category

  bool get isFiltered => status != 'ALL' || category != 'ALL';

  int get activeFilterCount {
    int count = 0;
    if (status != 'ALL') count++;
    if (category != 'ALL') count++;
    return count;
  }

  const NewsFilterCriteria({
    this.status = 'ALL',
    this.category = 'ALL',
  });

  NewsFilterCriteria copyWith({
    String? status,
    String? category,
  }) {
    return NewsFilterCriteria(
      status: status ?? this.status,
      category: category ?? this.category,
    );
  }
}

class NewsFilterModal extends StatefulWidget {
  final NewsFilterCriteria initialFilter;
  final ValueChanged<NewsFilterCriteria> onApply;

  const NewsFilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<NewsFilterCriteria?> show(
    BuildContext context, {
    required NewsFilterCriteria initialFilter,
    required ValueChanged<NewsFilterCriteria> onApply,
  }) {
    return showModalBottomSheet<NewsFilterCriteria>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewsFilterModal(
        initialFilter: initialFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<NewsFilterModal> createState() => _NewsFilterModalState();
}

class _NewsFilterModalState extends State<NewsFilterModal> {
  late String _status;
  late String _category;

  final List<Map<String, dynamic>> _statusOptions = const [
    {'key': 'ALL', 'label': 'All Statuses', 'color': Color(0xFF3B82F6)},
    {'key': 'PUBLISHED', 'label': 'PUBLISHED', 'color': Color(0xFF10B981)},
    {'key': 'DRAFT', 'label': 'DRAFT', 'color': Color(0xFFF59E0B)},
  ];

  final List<String> _categoryOptions = const [
    'ALL',
    'Local News',
    'Announcement',
    'Agriculture & Livelihood',
    'Public Advisory',
    'Health & Wellness',
    'Sports & Culture',
    'Disaster Advisory',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.initialFilter.status;
    _category = widget.initialFilter.category;
  }

  void _resetFilters() {
    setState(() {
      _status = 'ALL';
      _category = 'ALL';
    });
  }

  void _applyFilters() {
    final newState = NewsFilterCriteria(
      status: _status,
      category: _category,
    );
    widget.onApply(newState);
    Navigator.of(context).pop(newState);
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = _status != 'ALL' || _category != 'ALL';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF3B82F6),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "NEWS ARTICLE FILTERS",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Filter by Category & Publication Status",
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

          const SizedBox(height: 20),

          // Section 1: Publication Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PUBLICATION STATUS",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_status != 'ALL')
                GestureDetector(
                  onTap: () => setState(() => _status = 'ALL'),
                  child: Text(
                    "Reset",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusOptions.map((opt) {
              final isSelected = _status.toUpperCase() == opt['key'].toString().toUpperCase();
              final color = opt['color'] as Color;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _status = opt['key'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.2)
                        : AppColors.surfaceElevated.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (opt['key'] != 'ALL') ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        opt['label'],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Section 2: News Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "NEWS CATEGORY",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_category != 'ALL')
                GestureDetector(
                  onTap: () => setState(() => _category = 'ALL'),
                  child: Text(
                    "Reset",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categoryOptions.map((c) {
              final isSelected = _category.toUpperCase() == c.toUpperCase();

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _category = c;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2563EB).withValues(alpha: 0.2)
                        : AppColors.surfaceElevated.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3B82F6) : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    c == 'ALL' ? 'All Categories' : c,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 26),

          // Actions
          Row(
            children: [
              if (isFiltered)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Reset",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (isFiltered) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Apply Filters",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
