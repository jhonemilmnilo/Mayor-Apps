import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';

class ProjectFilterCriteria {
  final String status; // 'ALL', 'Ongoing', 'Completed', 'Planned', 'On Hold'
  final String category; // 'ALL' or specific category

  bool get isFiltered => status != 'ALL' || category != 'ALL';

  int get activeFilterCount {
    int count = 0;
    if (status != 'ALL') count++;
    if (category != 'ALL') count++;
    return count;
  }

  const ProjectFilterCriteria({
    this.status = 'ALL',
    this.category = 'ALL',
  });

  ProjectFilterCriteria copyWith({
    String? status,
    String? category,
  }) {
    return ProjectFilterCriteria(
      status: status ?? this.status,
      category: category ?? this.category,
    );
  }
}

class ProjectFilterModal extends StatefulWidget {
  final ProjectFilterCriteria initialFilter;
  final Function(ProjectFilterCriteria) onApply;

  const ProjectFilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required ProjectFilterCriteria currentFilter,
    required Function(ProjectFilterCriteria) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProjectFilterModal(
        initialFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ProjectFilterModal> createState() => _ProjectFilterModalState();
}

class _ProjectFilterModalState extends State<ProjectFilterModal> {
  late String _status;
  late String _category;

  final List<Map<String, dynamic>> _statusOptions = const [
    {'key': 'ALL', 'label': 'All Statuses', 'color': Color(0xFF8B5CF6)},
    {'key': 'Ongoing', 'label': 'Ongoing', 'color': Color(0xFF3B82F6)},
    {'key': 'Completed', 'label': 'Completed', 'color': Color(0xFF10B981)},
    {'key': 'Planned', 'label': 'Planned', 'color': Color(0xFFF59E0B)},
    {'key': 'On Hold', 'label': 'On Hold', 'color': Color(0xFFEF4444)},
  ];

  final List<String> _categoryOptions = const [
    'ALL',
    'Infrastructure',
    'Roads & Bridges',
    'Public Facilities',
    'Education',
    'Health',
    'Environment',
    'Agriculture',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.initialFilter.status;
    _category = widget.initialFilter.category;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.slidersHorizontal,
                        size: 15,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PROJECT CRITERIA & FILTERS",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "Refine by Status & Sector Category",
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 18, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          // Scrollable Filter Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Status Filter Chips
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.checkCircle2,
                        size: 13,
                        color: Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "PROJECT STATUS",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statusOptions.map((opt) {
                      final isSelected = _status == opt['key'];
                      final color = opt['color'] as Color;
                      return InkWell(
                        onTap: () => setState(() => _status = opt['key']),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? color : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                opt['label'],
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 22),

                  // Section 2: Sector Category Chips
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.tag,
                        size: 13,
                        color: Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "SECTOR & CATEGORY",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryOptions.map((cat) {
                      final isSelected = _category == cat;
                      return InkWell(
                        onTap: () => setState(() => _category = cat),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF8B5CF6)
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            cat == 'ALL' ? 'All Sectors' : cat,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _status = 'ALL';
                        _category = 'ALL';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Reset Filters",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        ProjectFilterCriteria(
                          status: _status,
                          category: _category,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.check, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          "Apply Filters",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
