import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';

class BarangaySearchModal extends StatefulWidget {
  final List<String> barangays;
  final String selectedBarangay;
  final Function(String) onSelect;

  const BarangaySearchModal({
    super.key,
    required this.barangays,
    required this.selectedBarangay,
    required this.onSelect,
  });

  @override
  State<BarangaySearchModal> createState() => _BarangaySearchModalState();
}

class _BarangaySearchModalState extends State<BarangaySearchModal> {
  final _searchController = TextEditingController();
  late List<String> _filteredBarangays;

  @override
  void initState() {
    super.initState();
    _filteredBarangays = widget.barangays;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBarangays = widget.barangays;
      } else {
        _filteredBarangays = widget.barangays
            .where((b) => b.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (AppColors.isDark(context) ? Colors.white : Colors.black).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SELECT JURISDICTION",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.x, size: 20, color: AppColors.getTextSecondary(context)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            style: TextStyle(color: AppColors.getTextPrimary(context), fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(LucideIcons.search, size: 18, color: AppColors.getTextSecondary(context)),
              hintText: "Search barangay name...",
              hintStyle: TextStyle(color: AppColors.getTextSecondary(context).withValues(alpha: 0.5), fontSize: 14),
              filled: true,
              fillColor: AppColors.getSurface(context),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.getBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.getBorder(context)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options List
          Expanded(
            child: ListView(
              children: [
                // All Barangays Item
                _buildBarangayTile(
                  name: "All Barangays (Municipality Wide)",
                  value: "",
                  isSelected: widget.selectedBarangay.isEmpty,
                ),
                Divider(color: AppColors.getBorder(context), height: 16),
                // Barangay List
                ..._filteredBarangays.map((b) {
                  return _buildBarangayTile(
                    name: "Brgy. $b",
                    value: b,
                    isSelected: widget.selectedBarangay == b,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangayTile({
    required String name,
    required String value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        widget.onSelect(value);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.getTextPrimary(context) : AppColors.getTextSecondary(context),
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.check, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
