import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';

class EventFilterCriteria {
  final String timeframe; // 'ALL', 'LIVE', 'UPCOMING', 'ENDED'
  final String category; // 'ALL' or specific category

  bool get isFiltered => timeframe != 'ALL' || category != 'ALL';

  int get activeFilterCount {
    int count = 0;
    if (timeframe != 'ALL') count++;
    if (category != 'ALL') count++;
    return count;
  }

  const EventFilterCriteria({
    this.timeframe = 'ALL',
    this.category = 'ALL',
  });

  EventFilterCriteria copyWith({
    String? timeframe,
    String? category,
  }) {
    return EventFilterCriteria(
      timeframe: timeframe ?? this.timeframe,
      category: category ?? this.category,
    );
  }
}

class EventFilterModal extends StatefulWidget {
  final EventFilterCriteria initialFilter;
  final ValueChanged<EventFilterCriteria> onApply;

  const EventFilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<EventFilterCriteria?> show(
    BuildContext context, {
    required EventFilterCriteria initialFilter,
    required ValueChanged<EventFilterCriteria> onApply,
  }) {
    return showModalBottomSheet<EventFilterCriteria>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EventFilterModal(
        initialFilter: initialFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<EventFilterModal> createState() => _EventFilterModalState();
}

class _EventFilterModalState extends State<EventFilterModal> {
  late String _timeframe;
  late String _category;

  final List<Map<String, dynamic>> _timeframeOptions = const [
    {'key': 'ALL', 'label': 'All Events', 'color': Color(0xFF8B5CF6)},
    {'key': 'LIVE', 'label': '🔴 Live Now', 'color': Color(0xFF10B981)},
    {'key': 'UPCOMING', 'label': '🕒 Upcoming', 'color': Color(0xFF3B82F6)},
    {'key': 'ENDED', 'label': '📜 Past / Ended', 'color': Color(0xFF94A3B8)},
  ];

  final List<String> _categoryOptions = const [
    'ALL',
    'Community',
    'Sports',
    'Festival',
    'Cultural & Fiesta',
    'Sports & Youth Development',
  ];

  @override
  void initState() {
    super.initState();
    _timeframe = widget.initialFilter.timeframe;
    _category = widget.initialFilter.category;
  }

  void _resetFilters() {
    setState(() {
      _timeframe = 'ALL';
      _category = 'ALL';
    });
  }

  void _applyFilters() {
    final newState = EventFilterCriteria(
      timeframe: _timeframe,
      category: _category,
    );
    widget.onApply(newState);
    Navigator.of(context).pop(newState);
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = _timeframe != 'ALL' || _category != 'ALL';
    final isDark = AppColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.getBorder(context), width: 1.5),
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
                color: (AppColors.isDark(context) ? Colors.white : Colors.black).withValues(alpha: 0.2),
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
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MUNICIPAL EVENT FILTERS",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.2,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    Text(
                      "Filter by Timeframe & Activity Category",
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

          const SizedBox(height: 20),

          // Section 1: Event Timeframe Lifecycle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "EVENT TIMEFRAME",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              if (_timeframe != 'ALL')
                GestureDetector(
                  onTap: () => setState(() => _timeframe = 'ALL'),
                  child: Text(
                    "Reset",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeframeOptions.map((opt) {
              final isSelected = _timeframe.toUpperCase() == opt['key'].toString().toUpperCase();
              final color = opt['color'] as Color;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _timeframe = opt['key'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.2)
                        : (isDark ? AppColors.surfaceElevated.withValues(alpha: 0.5) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : AppColors.getBorder(context),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    opt['label'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? (isDark ? Colors.white : AppColors.lightTextPrimary) : AppColors.getTextSecondary(context),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Section 2: Event Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "EVENT CATEGORY",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.getTextSecondary(context),
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
                      color: const Color(0xFF8B5CF6),
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
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                        : (isDark ? AppColors.surfaceElevated.withValues(alpha: 0.5) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF8B5CF6) : AppColors.getBorder(context),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    c == 'ALL' ? 'All Categories' : c,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? (isDark ? Colors.white : AppColors.lightTextPrimary) : AppColors.getTextSecondary(context),
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
                      foregroundColor: AppColors.getTextSecondary(context),
                      side: BorderSide(color: AppColors.getBorder(context)),
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
                    backgroundColor: const Color(0xFF8B5CF6),
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
