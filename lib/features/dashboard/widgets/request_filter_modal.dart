import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';

class RequestFilterCriteria {
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'requests', 'evaluation', 'processing', 'released', 'rejected'
  final String category; // 'ALL' or specific category
  final String? activePreset; // 'TODAY', '7D', '30D', 'MONTH', 'CUSTOM'

  const RequestFilterCriteria({
    required this.startDate,
    required this.endDate,
    this.status = 'requests',
    this.category = 'ALL',
    this.activePreset = '30D',
  });

  RequestFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? category,
    String? activePreset,
  }) {
    return RequestFilterCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      category: category ?? this.category,
      activePreset: activePreset ?? this.activePreset,
    );
  }
}

class RequestFilterModal extends StatefulWidget {
  final RequestFilterCriteria initialFilter;
  final Function(RequestFilterCriteria) onApply;

  const RequestFilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required RequestFilterCriteria currentFilter,
    required Function(RequestFilterCriteria) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestFilterModal(
        initialFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<RequestFilterModal> createState() => _RequestFilterModalState();
}

class _RequestFilterModalState extends State<RequestFilterModal> {
  late DateTime _startDate;
  late DateTime _endDate;
  late String _status;
  late String _category;
  String? _preset;

  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');

  final List<Map<String, dynamic>> _statusOptions = [
    {'key': 'requests', 'label': 'All Requests', 'color': Color(0xFF8B5CF6)},
    {'key': 'evaluation', 'label': 'For Evaluation', 'color': Color(0xFFF59E0B)},
    {'key': 'processing', 'label': 'In Processing', 'color': Color(0xFF0EA5E9)},
    {'key': 'released', 'label': 'Released', 'color': Color(0xFF10B981)},
    {'key': 'rejected', 'label': 'Rejected', 'color': Color(0xFFF43F5E)},
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

    if (preset == 'TODAY') {
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

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final first = DateTime(2020);
    final last = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B5CF6),
              surface: Color(0xFF151B2B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _preset = 'CUSTOM';
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151B2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF2A3040), width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.filter, size: 18, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Filter Daily Requests",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Quick Presets
          Text(
            "DATE PRESET",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _presetChip("Today", "TODAY"),
              const SizedBox(width: 6),
              _presetChip("7 Days", "7D"),
              const SizedBox(width: 6),
              _presetChip("30 Days", "30D"),
              const SizedBox(width: 6),
              _presetChip("This Month", "MONTH"),
            ],
          ),

          const SizedBox(height: 18),

          // Custom Date Range Pickers
          Text(
            "DATE RANGE",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dateBox(
                  label: "From",
                  date: _dateFormat.format(_startDate),
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(LucideIcons.arrowRight, size: 14, color: AppColors.textSecondary),
              ),
              Expanded(
                child: _dateBox(
                  label: "To",
                  date: _dateFormat.format(_endDate),
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Status Filter Tabs
          Text(
            "STATUS FILTER",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _statusOptions.map((opt) {
              final isSel = _status == opt['key'];
              final color = opt['color'] as Color;
              return InkWell(
                onTap: () => setState(() => _status = opt['key']),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSel ? color.withValues(alpha: 0.2) : const Color(0xFF1E2330),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel ? color : const Color(0xFF2A3040),
                      width: isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    opt['label'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSel ? color : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Apply / Reset Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = now.subtract(const Duration(days: 29));
                      _endDate = now;
                      _status = 'requests';
                      _category = 'ALL';
                      _preset = '30D';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2A3040)),
                    shape: RoundedRectangle308(BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "RESET",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      RequestFilterCriteria(
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
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangle308(BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "APPLY FILTER",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.white,
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

  Widget _presetChip(String label, String code) {
    final isSel = _preset == code;
    return Expanded(
      child: InkWell(
        onTap: () => _applyPreset(code),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF8B5CF6).withValues(alpha: 0.2) : const Color(0xFF1E2330),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFF2A3040),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isSel ? const Color(0xFF8B5CF6) : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateBox({required String label, required String date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2330),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A3040)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, size: 13, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                Text(
                  date,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RoundedRectangle308 extends RoundedRectangleBorder {
  const RoundedRectangle308(BorderRadius radius) : super(borderRadius: radius);
}
