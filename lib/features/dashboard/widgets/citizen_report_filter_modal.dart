import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';

class CitizenReportFilterCriteria {
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'ALL', 'PENDING', 'SEEN', 'IN_PROGRESS', 'COMPLETED', 'REJECTED'
  final String category; // 'ALL' or specific category
  final String? activePreset; // 'ALL', 'TODAY', '7D', '30D', 'MONTH', 'CUSTOM'

  bool get isAllTime => activePreset == 'ALL';

  const CitizenReportFilterCriteria({
    required this.startDate,
    required this.endDate,
    this.status = 'ALL',
    this.category = 'ALL',
    this.activePreset = '30D',
  });

  CitizenReportFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? category,
    String? activePreset,
  }) {
    return CitizenReportFilterCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      category: category ?? this.category,
      activePreset: activePreset ?? this.activePreset,
    );
  }
}

class CitizenReportFilterModal extends StatefulWidget {
  final CitizenReportFilterCriteria initialFilter;
  final Function(CitizenReportFilterCriteria) onApply;

  const CitizenReportFilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required CitizenReportFilterCriteria currentFilter,
    required Function(CitizenReportFilterCriteria) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CitizenReportFilterModal(
        initialFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<CitizenReportFilterModal> createState() =>
      _CitizenReportFilterModalState();
}

class _CitizenReportFilterModalState extends State<CitizenReportFilterModal> {
  late DateTime _startDate;
  late DateTime _endDate;
  late String _status;
  late String _category;
  String? _preset;

  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');

  final List<Map<String, dynamic>> _statusOptions = [
    {'key': 'ALL', 'label': 'All Statuses', 'color': Color(0xFF8B5CF6)},
    {'key': 'PENDING', 'label': 'PENDING', 'color': Color(0xFFF59E0B)},
    {'key': 'SEEN', 'label': 'SEEN', 'color': Color(0xFF3B82F6)},
    {'key': 'IN_PROGRESS', 'label': 'IN PROGRESS', 'color': Color(0xFF0EA5E9)},
    {'key': 'COMPLETED', 'label': 'COMPLETED', 'color': Color(0xFF10B981)},
    {'key': 'REJECTED', 'label': 'REJECTED', 'color': Color(0xFFEF4444)},
  ];

  final List<String> _categoryOptions = [
    'ALL',
    'Public Safety',
    'Road Damage',
    'Waste Management',
    'Noise Complaint',
    'Health & Sanitation',
    'Flooding & Drainage',
    'Streetlight / Electrical',
    'Animal Control',
    'General Grievance',
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _status = widget.initialFilter.status;
    _category = widget.initialFilter.category;
    _preset = widget.initialFilter.activePreset;
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    DateTime start = now;
    DateTime end = now;

    if (preset == 'ALL') {
      start = DateTime(2020, 1, 1);
      end = now;
    } else if (preset == 'TODAY') {
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (preset == '7D') {
      start = now.subtract(const Duration(days: 6));
      end = now;
    } else if (preset == '30D') {
      start = now.subtract(const Duration(days: 29));
      end = now;
    } else if (preset == 'MONTH') {
      start = DateTime(now.year, now.month, 1);
      end = now;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
      _preset = preset;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF59E0B),
              onPrimary: Colors.white,
              surface: AppColors.surfaceElevated,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _preset = 'CUSTOM';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.slidersHorizontal,
                        size: 15,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "REPORT CRITERIA & FILTERS",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "Refine civic incident logs & timeline streams",
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
                  // Section 1: Timeline Preset
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 13,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "TIMELINE PRESETS",
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
                    children: [
                      _buildPresetChip("ALL", "ALL TIME"),
                      _buildPresetChip("TODAY", "TODAY"),
                      _buildPresetChip("7D", "LAST 7 DAYS"),
                      _buildPresetChip("30D", "LAST 30 DAYS"),
                      _buildPresetChip("MONTH", "THIS MONTH"),
                      _buildPresetChip("CUSTOM", "CUSTOM RANGE"),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Section 2: Date Range Filter (Unified showDateRangePicker matching Collections Ledger)
                  Text(
                    "DATE RANGE FILTER",
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _preset == 'CUSTOM'
                              ? const Color(0xFFF59E0B)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.calendar,
                                      size: 12,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "START DATE",
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _preset == 'ALL'
                                      ? "All Time"
                                      : _dateFormat.format(_startDate),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: const Icon(
                              LucideIcons.arrowRight,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.calendar,
                                      size: 12,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "END DATE",
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _preset == 'ALL'
                                      ? "Today"
                                      : _dateFormat.format(_endDate),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Section 3: Status Filter Chips
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.checkCircle2,
                        size: 13,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "REPORT STATUS",
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
                              color: isSelected
                                  ? color
                                  : AppColors.border,
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

                  // Section 4: Incident Category Chips
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.tag,
                        size: 13,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "INCIDENT CATEGORY",
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
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            cat == 'ALL' ? 'All Categories' : cat,
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
                      final now = DateTime.now();
                      setState(() {
                        _startDate = DateTime(2020, 1, 1);
                        _endDate = now;
                        _status = 'ALL';
                        _category = 'ALL';
                        _preset = 'ALL';
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
                        CitizenReportFilterCriteria(
                          startDate: _startDate,
                          endDate: _endDate,
                          status: _status,
                          category: _category,
                          activePreset: _preset,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
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

  Widget _buildPresetChip(String key, String label) {
    final isSelected = _preset == key;
    return InkWell(
      onTap: () => _applyPreset(key),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF59E0B)
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
