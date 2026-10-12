import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';

class ServiceCategoryConfig {
  final String key;
  final String label;
  final Color color;

  const ServiceCategoryConfig({
    required this.key,
    required this.label,
    required this.color,
  });
}

const List<ServiceCategoryConfig> kMunicipalServices = [
  ServiceCategoryConfig(key: 'BUILDING_PERMIT', label: 'Building Permit', color: Color(0xFFF59E0B)), // Amber
  ServiceCategoryConfig(key: 'BUSINESS_PERMIT', label: 'Business Permit', color: Color(0xFF10B981)), // Emerald
  ServiceCategoryConfig(key: 'CEDULA', label: 'CEDULA', color: Color(0xFF3B82F6)), // Blue
  ServiceCategoryConfig(key: 'CIVIL_REGISTRY', label: 'Civil Registry', color: Color(0xFF8B5CF6)), // Purple
  ServiceCategoryConfig(key: 'FENCING_PERMIT', label: 'Fencing Permit', color: Color(0xFF14B8A6)), // Teal
  ServiceCategoryConfig(key: 'OCCUPANCY_PERMIT', label: 'Occupancy Permit', color: Color(0xFF06B6D4)), // Cyan
  ServiceCategoryConfig(key: 'POSO', label: 'POSO', color: Color(0xFFF97316)), // Orange
  ServiceCategoryConfig(key: 'RHU', label: 'RHU', color: Color(0xFFEF4444)), // Red
  ServiceCategoryConfig(key: 'RPT', label: 'RPT', color: Color(0xFF6366F1)), // Indigo
];

class ServiceLegendsModal extends StatelessWidget {
  final List<dynamic> payments;
  final double totalRevenue;

  const ServiceLegendsModal({
    super.key,
    required this.payments,
    required this.totalRevenue,
  });

  static void show(BuildContext context, {required List<dynamic> payments, required double totalRevenue}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceLegendsModal(
        payments: payments,
        totalRevenue: totalRevenue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.50,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 34,
              height: 3.5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Compact Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.tags, size: 14, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "SERVICE COLOR LEGENDS",
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          // Ultra-Compact 2-Column Grid (Fits exactly 9 items neatly)
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                mainAxisExtent: 36,
              ),
              itemCount: kMunicipalServices.length,
              itemBuilder: (context, index) {
                final service = kMunicipalServices[index];

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      // Colored Indicator Circle
                      Container(
                        width: 8.5,
                        height: 8.5,
                        decoration: BoxDecoration(
                          color: service.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: service.color.withValues(alpha: 0.4),
                              blurRadius: 3,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          service.label,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
}
