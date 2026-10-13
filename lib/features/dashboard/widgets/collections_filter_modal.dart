import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';

class CollectionsFilterCriteria {
  final DateTime startDate;
  final DateTime endDate;
  final String paymentMethod; // 'ALL', 'ONLINE', 'CASH'
  final String? activePreset; // 'TODAY', '7D', '30D', 'MONTH', 'CUSTOM'

  const CollectionsFilterCriteria({
    required this.startDate,
    required this.endDate,
    this.paymentMethod = 'ALL',
    this.activePreset = '30D',
  });

  CollectionsFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    String? activePreset,
  }) {
    return CollectionsFilterCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      activePreset: activePreset ?? this.activePreset,
    );
  }
}

class CollectionsFilterModal extends StatefulWidget {
  final CollectionsFilterCriteria initialFilter;
  final Function(CollectionsFilterCriteria) onApply;

  const CollectionsFilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required CollectionsFilterCriteria currentFilter,
    required Function(CollectionsFilterCriteria) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollectionsFilterModal(
        initialFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<CollectionsFilterModal> createState() => _CollectionsFilterModalState();
}

class _CollectionsFilterModalState extends State<CollectionsFilterModal> {
  late DateTime _startDate;
  late DateTime _endDate;
  late String _paymentMethod;
  String? _preset;

  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _paymentMethod = widget.initialFilter.paymentMethod;
    _preset = widget.initialFilter.activePreset;
  }

  void _applyPreset(String presetKey) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (presetKey) {
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
              primary: Color(0xFF10B981),
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
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color: Colors.white.withValues(alpha: 0.2),
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
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.filter, size: 16, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "FILTER COLLECTIONS",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Configure start date, end date, and payment channel",
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

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
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip("TODAY", "Today"),
                      _buildPresetChip("7D", "Last 7 Days"),
                      _buildPresetChip("30D", "Last 30 Days"),
                      _buildPresetChip("MONTH", "This Month"),
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
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF10B981)),
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
                                  _dateFormat.format(_startDate),
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
                            child: const Icon(LucideIcons.arrowRight, size: 14, color: AppColors.textSecondary),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF10B981)),
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
                                  _dateFormat.format(_endDate),
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

                  const SizedBox(height: 18),

                  // 3. Payment Method Filter (Matching Web 'ALL METHODS...')
                  Text(
                    "PAYMENT METHOD",
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(child: _buildMethodPill("ALL", "All Channels", LucideIcons.layers)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMethodPill("ONLINE", "Online Pay", LucideIcons.smartphone)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMethodPill("CASH", "Cashier", LucideIcons.coins)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 4. Action Buttons (Reset & Apply)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _applyPreset('30D');
                              _paymentMethod = 'ALL';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            "Reset Defaults",
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
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
                              CollectionsFilterCriteria(
                                startDate: _startDate,
                                endDate: _endDate,
                                paymentMethod: _paymentMethod,
                                activePreset: _preset,
                              ),
                            );
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.check, size: 15, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                "APPLY FILTER",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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

  Widget _buildPresetChip(String key, String label) {
    final isSelected = _preset == key;
    return InkWell(
      onTap: () => _applyPreset(key),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.16) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? const Color(0xFF10B981) : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMethodPill(String key, String label, IconData icon) {
    final isSelected = _paymentMethod == key;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = key),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.16) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF10B981) : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
