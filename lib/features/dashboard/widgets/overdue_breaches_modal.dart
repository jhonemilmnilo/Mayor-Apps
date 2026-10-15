import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../models/overdue_arta_model.dart';

class OverdueBreachesModal extends StatefulWidget {
  final List<OverdueArtaModel> overdueRequests;

  const OverdueBreachesModal({
    super.key,
    required this.overdueRequests,
  });

  static void show(
    BuildContext context, {
    required List<OverdueArtaModel> overdueRequests,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OverdueBreachesModal(
        overdueRequests: overdueRequests,
      ),
    );
  }

  @override
  State<OverdueBreachesModal> createState() => _OverdueBreachesModalState();
}

class _OverdueBreachesModalState extends State<OverdueBreachesModal> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy • h:mm a');
  String _selectedOffice = "ALL";
  String _searchQuery = "";

  static const Color _alertRose = Color(0xFFF43F5E); // Rose 500

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _distinctOffices {
    final offices = widget.overdueRequests
        .map((e) => e.officeCode)
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList();
    offices.sort();
    return offices;
  }

  int get _maxDaysOver {
    if (widget.overdueRequests.isEmpty) return 0;
    return widget.overdueRequests
        .map((e) => e.daysOver)
        .reduce((a, b) => a > b ? a : b);
  }

  List<OverdueArtaModel> get _filteredList {
    return widget.overdueRequests.where((item) {
      final matchesOffice =
          _selectedOffice == "ALL" || item.officeCode == _selectedOffice;
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          item.referenceNo.toLowerCase().contains(q) ||
          item.serviceName.toLowerCase().contains(q) ||
          item.handlerName.toLowerCase().contains(q) ||
          item.officeCode.toLowerCase().contains(q);
      return matchesOffice && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;
    final distinctOffices = _distinctOffices;
    final maxDays = _maxDaysOver;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: (AppColors.isDark(context) ? Colors.white : Colors.black).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _alertRose.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.alertTriangle,
                        size: 20,
                        color: _alertRose,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "STATUTORY CLOCK BREACHES",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.2,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        Text(
                          "${widget.overdueRequests.length} citizen requests exceeded RA 11032 SLA",
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, size: 20, color: AppColors.getTextSecondary(context)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          Divider(color: AppColors.getBorder(context), height: 1),

          // 3 Metric Summary Cards (Total Breaches, Max Overdue, Affected Offices)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricPillar(
                    context,
                    title: "TOTAL BREACHES",
                    value: "${widget.overdueRequests.length}",
                    valueColor: _alertRose,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricPillar(
                    context,
                    title: "MAX OVERDUE",
                    value: "+$maxDays days",
                    valueColor: _alertRose,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricPillar(
                    context,
                    title: "AFFECTED OFFICES",
                    value: "${distinctOffices.length}",
                    valueColor: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.getTextPrimary(context)),
              decoration: InputDecoration(
                hintText: "Search reference, service, or handler...",
                hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.getTextSecondary(context)),
                prefixIcon: Icon(LucideIcons.search, size: 14, color: AppColors.getTextSecondary(context)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(LucideIcons.x, size: 14, color: AppColors.getTextSecondary(context)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.getSurfaceElevated(context).withValues(alpha: 0.6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.getBorder(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.getBorder(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _alertRose, width: 1.2),
                ),
              ),
            ),
          ),

          // Horizontal Office Filter Chips
          if (distinctOffices.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
              child: Row(
                children: [
                  _buildOfficeChip(context, "ALL", "All (${widget.overdueRequests.length})"),
                  const SizedBox(width: 6),
                  ...distinctOffices.map((code) {
                    final count = widget.overdueRequests
                        .where((o) => o.officeCode == code)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildOfficeChip(context, code, "$code ($count)"),
                    );
                  }),
                ],
              ),
            ),

          Divider(color: AppColors.getBorder(context), height: 1),

          // Scrollable Overdue Items List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.checkCircle2,
                          size: 36,
                          color: const Color(0xFF10B981).withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _searchQuery.isNotEmpty || _selectedOffice != "ALL"
                              ? "No overdue transactions matching criteria"
                              : "No clock breaches recorded!",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isDark = AppColors.isDark(context);

                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? _alertRose.withValues(alpha: 0.25) : _alertRose.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: isDark ? [] : AppColors.getCardShadow(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: Reference No + Office Badge + Overdue Pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                            color: AppColors.getBorder(context), width: 0.8),
                                      ),
                                      child: Text(
                                        item.referenceNo,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.getTextPrimary(context),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6)
                                            .withValues(alpha: isDark ? 0.15 : 0.1),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                            color: const Color(0xFF3B82F6)
                                                .withValues(alpha: isDark ? 0.3 : 0.25),
                                            width: 0.8),
                                      ),
                                      child: Text(
                                        item.officeCode,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: _alertRose.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _alertRose.withValues(alpha: 0.35),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    "+${item.daysOver} DAY${item.daysOver > 1 ? "S" : ""} OVER",
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                      color: _alertRose,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Service Name
                            Text(
                              item.serviceName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Handler & Deadline Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(LucideIcons.user,
                                        size: 11, color: AppColors.getTextSecondary(context)),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Handler: ${item.handlerName}",
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: AppColors.getTextSecondary(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.deadlineAt != null)
                                  Row(
                                    children: [
                                      Icon(LucideIcons.clock,
                                          size: 11, color: AppColors.getTextSecondary(context)),
                                      const SizedBox(width: 4),
                                      Text(
                                        _dateFormat.format(item.deadlineAt!),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: AppColors.getTextSecondary(context),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPillar(
    BuildContext context, {
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceElevated(context).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _alertRose.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeChip(BuildContext context, String code, String label) {
    final isSelected = _selectedOffice == code;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedOffice = code;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? _alertRose.withValues(alpha: 0.2)
              : AppColors.getSurfaceElevated(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _alertRose : AppColors.getBorder(context),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? _alertRose : AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }
}
