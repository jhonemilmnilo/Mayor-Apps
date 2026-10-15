import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';

class AnnouncementFilterState {
  final String priority;
  final String category;

  const AnnouncementFilterState({
    this.priority = 'All',
    this.category = 'All',
  });

  bool get isFiltered => priority != 'All' || category != 'All';

  int get activeFilterCount {
    int count = 0;
    if (priority != 'All') count++;
    if (category != 'All') count++;
    return count;
  }

  AnnouncementFilterState copyWith({
    String? priority,
    String? category,
  }) {
    return AnnouncementFilterState(
      priority: priority ?? this.priority,
      category: category ?? this.category,
    );
  }
}

class AnnouncementFilterModal extends StatefulWidget {
  final AnnouncementFilterState initialFilter;
  final ValueChanged<AnnouncementFilterState> onApply;

  const AnnouncementFilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<AnnouncementFilterState?> show(
    BuildContext context, {
    required AnnouncementFilterState initialFilter,
    required ValueChanged<AnnouncementFilterState> onApply,
  }) {
    return showModalBottomSheet<AnnouncementFilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnnouncementFilterModal(
        initialFilter: initialFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<AnnouncementFilterModal> createState() => _AnnouncementFilterModalState();
}

class _AnnouncementFilterModalState extends State<AnnouncementFilterModal> {
  late String _selectedPriority;
  late String _selectedCategory;

  final List<String> _priorities = const [
    'All',
    'Critical',
    'High',
    'Urgent',
    'Important',
    'Normal',
    'Low',
  ];

  final List<String> _categories = const [
    'All',
    'General',
    'Emergency',
    'Public Service',
    'Weather',
    'Health',
    'Utility',
    'Community Clean-up',
    'MDRRMO',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.initialFilter.priority;
    _selectedCategory = widget.initialFilter.category;
  }

  void _resetFilters() {
    setState(() {
      _selectedPriority = 'All';
      _selectedCategory = 'All';
    });
  }

  void _applyFilters() {
    final newState = AnnouncementFilterState(
      priority: _selectedPriority,
      category: _selectedCategory,
    );
    widget.onApply(newState);
    Navigator.of(context).pop(newState);
  }

  Color _getPriorityColor(String priority) {
    final p = priority.toUpperCase();
    if (p == 'CRITICAL' || p == 'URGENT') return const Color(0xFFEF4444);
    if (p == 'HIGH' || p == 'IMPORTANT') return const Color(0xFFF59E0B);
    if (p == 'NORMAL') return const Color(0xFF3B82F6);
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = _selectedPriority != 'All' || _selectedCategory != 'All';
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
          // Drag Handle
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
                  color: AppColors.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.accentAmber,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ANNOUNCEMENT FILTERS",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.2,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    Text(
                      "Filter by Category Type and Priority Level",
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

          // Section 1: Priority
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PRIORITY LEVEL",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              if (_selectedPriority != 'All')
                GestureDetector(
                  onTap: () => setState(() => _selectedPriority = 'All'),
                  child: Text(
                    "Reset",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentAmber,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _priorities.map((p) {
              final isSelected = _selectedPriority.toUpperCase() == p.toUpperCase();
              final pColor = _getPriorityColor(p);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPriority = p;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? pColor.withValues(alpha: 0.2)
                        : (isDark ? AppColors.surfaceElevated.withValues(alpha: 0.5) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? pColor : AppColors.getBorder(context),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p != 'All') ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: pColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        p == 'All' ? 'All Priorities' : p,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? (isDark ? Colors.white : AppColors.lightTextPrimary) : AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Section 2: Category / Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ANNOUNCEMENT TYPE / CATEGORY",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              if (_selectedCategory != 'All')
                GestureDetector(
                  onTap: () => setState(() => _selectedCategory = 'All'),
                  child: Text(
                    "Reset",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentAmber,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((c) {
              final isSelected = _selectedCategory.toUpperCase() == c.toUpperCase();

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = c;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentAmber.withValues(alpha: 0.2)
                        : (isDark ? AppColors.surfaceElevated.withValues(alpha: 0.5) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.accentAmber : AppColors.getBorder(context),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    c == 'All' ? 'All Types' : c,
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
                    backgroundColor: AppColors.accentAmber,
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
