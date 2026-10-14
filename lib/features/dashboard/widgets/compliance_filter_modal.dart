import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';

class ComplianceFilterCriteria {
  final DateTime startDate;
  final DateTime endDate;
  final String? activePreset; // 'TODAY', '7D', '30D', 'MONTH', 'CUSTOM'

  const ComplianceFilterCriteria({
    required this.startDate,
    required this.endDate,
    this.activePreset = '30D',
  });

  ComplianceFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? activePreset,
  }) {
    return ComplianceFilterCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      activePreset: activePreset ?? this.activePreset,
    );
  }
}

class ComplianceFilterModal extends StatefulWidget {
  final ComplianceFilterCriteria initialFilter;
  final Function(ComplianceFilterCriteria) onApply;

  const ComplianceFilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required ComplianceFilterCriteria currentFilter,
    required Function(ComplianceFilterCriteria) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComplianceFilterModal(
        initialFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ComplianceFilterModal> createState() => _ComplianceFilterModalState();
}

class _ComplianceFilterModalState extends State<ComplianceFilterModal> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _preset;

  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');
  static const Color _accentTeal = Color(0xFF14B8A6);

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _preset = widget.initialFilter.activePreset;
  }

  void _applyPreset(String presetKey) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (presetKey) {
      case 'ALL':
        start = DateTime(2024, 1, 1);
        break;
      case 'TODAY':
        start = DateTime(now.year, now.month, now.day);
        break;
      case '7D':
        start = now.subtract(const Duration(days: 7));
        break;
      case '30D':
        start = now.subtract(const Duration(days: 30));
        break;
      case 'MONTH':
        start = DateTime(now.year, now.month, 1);
        break;
      default:
        start = _startDate;
        end = _endDate;
    }

    setState(() {
      _preset = presetKey;
      _startDate = start;
      _endDate = end;
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accentTeal,
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
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _accentTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.calendar, size: 16, color: _accentTeal),
                    ),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "COMPLIANCE TIMELINE",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        Text(
                          "Filter statutory SLA compliance by date range",
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.getTextSecondary(context)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, size: 18, color: AppColors.getTextSecondary(context)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Divider(color: AppColors.getBorder(context), height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Quick Presets Section
                  Text(
                    "QUICK TIMELINE PRESETS",
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip(context, "ALL", "All Time"),
                      _buildPresetChip(context, "TODAY", "Today"),
                      _buildPresetChip(context, "7D", "Last 7 Days"),
                      _buildPresetChip(context, "30D", "Last 30 Days"),
                      _buildPresetChip(context, "MONTH", "This Month"),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 2. Custom Date Range Pickers (Start & End)
                  Text(
                    "DATE RANGE FILTER",
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),

                  InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.getSurfaceElevated(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.getBorder(context)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 12, color: _accentTeal),
                                    const SizedBox(width: 5),
                                    Text(
                                      "START DATE",
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dateFormat.format(_startDate),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(LucideIcons.arrowRight, size: 14, color: AppColors.getTextSecondary(context)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 12, color: _accentTeal),
                                    const SizedBox(width: 5),
                                    Text(
                                      "END DATE",
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dateFormat.format(_endDate),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.getTextPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _accentTeal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.edit3, size: 14, color: _accentTeal),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Apply & Reset Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            setState(() {
                              _startDate = now.subtract(const Duration(days: 30));
                              _endDate = now;
                              _preset = '30D';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.getBorder(context)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text(
                            "RESET",
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextSecondary(context),
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
                              ComplianceFilterCriteria(
                                startDate: _startDate,
                                endDate: _endDate,
                                activePreset: _preset,
                              ),
                            );
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                          ),
                          child: Text(
                            "APPLY TIMELINE",
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, String key, String label) {
    final isSelected = _preset == key;
    return InkWell(
      onTap: () => _applyPreset(key),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? _accentTeal.withValues(alpha: 0.2) : AppColors.getSurfaceElevated(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _accentTeal : AppColors.getBorder(context),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? _accentTeal : AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }
}
