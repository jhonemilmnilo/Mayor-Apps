import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';

class ResidentFilterCriteria {
  final DateTime startDate;
  final DateTime endDate;
  final String gender; // 'ALL', 'Male', 'Female'
  final String civilStatus; // 'ALL', 'Single', 'Married', 'Widowed', 'Separated', 'Divorced'
  final String sector; // 'ALL', 'SENIOR', 'PWD', 'SOLO_PARENT', 'FOUR_PS'
  final String? activePreset; // 'ALL', 'TODAY', '7D', '30D', 'MONTH', 'CUSTOM'

  bool get isAllTime => activePreset == 'ALL';

  const ResidentFilterCriteria({
    required this.startDate,
    required this.endDate,
    this.gender = 'ALL',
    this.civilStatus = 'ALL',
    this.sector = 'ALL',
    this.activePreset = 'ALL',
  });

  ResidentFilterCriteria copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? gender,
    String? civilStatus,
    String? sector,
    String? activePreset,
  }) {
    return ResidentFilterCriteria(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      gender: gender ?? this.gender,
      civilStatus: civilStatus ?? this.civilStatus,
      sector: sector ?? this.sector,
      activePreset: activePreset ?? this.activePreset,
    );
  }
}

class ResidentFilterModal extends StatefulWidget {
  final ResidentFilterCriteria initialFilter;
  final Function(ResidentFilterCriteria) onApply;

  const ResidentFilterModal({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required ResidentFilterCriteria currentFilter,
    required Function(ResidentFilterCriteria) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ResidentFilterModal(
        initialFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ResidentFilterModal> createState() => _ResidentFilterModalState();
}

class _ResidentFilterModalState extends State<ResidentFilterModal> {
  late DateTime _startDate;
  late DateTime _endDate;
  late String _gender;
  late String _civilStatus;
  late String _sector;
  String? _preset;

  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');

  final List<Map<String, String>> _genderOptions = [
    {'key': 'ALL', 'label': 'All Genders'},
    {'key': 'Male', 'label': 'Male'},
    {'key': 'Female', 'label': 'Female'},
  ];

  final List<Map<String, String>> _civilStatusOptions = [
    {'key': 'ALL', 'label': 'All Statuses'},
    {'key': 'Single', 'label': 'Single'},
    {'key': 'Married', 'label': 'Married'},
    {'key': 'Widowed', 'label': 'Widowed'},
    {'key': 'Separated', 'label': 'Separated'},
    {'key': 'Divorced', 'label': 'Divorced'},
  ];

  final List<Map<String, dynamic>> _sectorOptions = [
    {'key': 'ALL', 'label': 'All Sectors', 'color': Color(0xFF3B82F6)},
    {'key': 'SENIOR', 'label': 'Senior Citizens', 'color': Color(0xFFF59E0B)},
    {'key': 'PWD', 'label': 'Persons with Disability', 'color': Color(0xFF10B981)},
    {'key': 'SOLO_PARENT', 'label': 'Solo Parents', 'color': Color(0xFFEC4899)},
    {'key': 'FOUR_PS', 'label': '4Ps Beneficiaries', 'color': Color(0xFF8B5CF6)},
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _gender = widget.initialFilter.gender;
    _civilStatus = widget.initialFilter.civilStatus;
    _sector = widget.initialFilter.sector;
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
              primary: Color(0xFF3B82F6),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.filter, size: 16, color: Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "FILTER RESIDENTS",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Configure timeline, demographics, and sectors",
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Quick Presets
                  Text(
                    "TIMELINE PRESETS",
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
                      _presetChip("All Time", 'ALL'),
                      const SizedBox(width: 5),
                      _presetChip("Today", 'TODAY'),
                      const SizedBox(width: 5),
                      _presetChip("7D", '7D'),
                      const SizedBox(width: 5),
                      _presetChip("30D", '30D'),
                      const SizedBox(width: 5),
                      _presetChip("Month", 'MONTH'),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 2. Custom Date Range Pickers
                  Text(
                    "REGISTRATION TIMELINE",
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
                        child: InkWell(
                          onTap: () => _pickDate(isStart: true),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF151B2B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("FROM", style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  _preset == 'ALL' ? "All Time" : _dateFormat.format(_startDate),
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(isStart: false),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF151B2B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("TO", style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  _preset == 'ALL' ? "Present" : _dateFormat.format(_endDate),
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3. Gender Filter
                  Text(
                    "GENDER",
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
                    children: _genderOptions.map((opt) {
                      final isSel = _gender == opt['key'];
                      return InkWell(
                        onTap: () => setState(() => _gender = opt['key']!),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF3B82F6).withValues(alpha: 0.2) : const Color(0xFF1E2330),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? const Color(0xFF3B82F6) : const Color(0xFF2A3040),
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            opt['label']!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSel ? const Color(0xFF60A5FA) : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // 4. Civil Status Filter
                  Text(
                    "CIVIL STATUS",
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
                    children: _civilStatusOptions.map((opt) {
                      final isSel = _civilStatus == opt['key'];
                      return InkWell(
                        onTap: () => setState(() => _civilStatus = opt['key']!),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF3B82F6).withValues(alpha: 0.2) : const Color(0xFF1E2330),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? const Color(0xFF3B82F6) : const Color(0xFF2A3040),
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            opt['label']!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSel ? const Color(0xFF60A5FA) : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // 5. Special Sector Filter
                  Text(
                    "SPECIAL SECTOR",
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
                    children: _sectorOptions.map((opt) {
                      final isSel = _sector == opt['key'];
                      final color = opt['color'] as Color;
                      return InkWell(
                        onTap: () => setState(() => _sector = opt['key']),
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

                  // Apply & Reset Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            setState(() {
                              _startDate = DateTime(2020, 1, 1);
                              _endDate = now;
                              _gender = 'ALL';
                              _civilStatus = 'ALL';
                              _sector = 'ALL';
                              _preset = 'ALL';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2A3040)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              ResidentFilterCriteria(
                                startDate: _startDate,
                                endDate: _endDate,
                                gender: _gender,
                                civilStatus: _civilStatus,
                                sector: _sector,
                                activePreset: _preset,
                              ),
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            ),
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
            color: isSel ? const Color(0xFF3B82F6).withValues(alpha: 0.2) : const Color(0xFF1E2330),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? const Color(0xFF3B82F6) : const Color(0xFF2A3040),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: isSel ? const Color(0xFF60A5FA) : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
