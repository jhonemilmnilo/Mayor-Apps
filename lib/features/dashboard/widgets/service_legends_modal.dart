import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
    final currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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

          // Header
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
                      child: const Icon(LucideIcons.tags, size: 16, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SERVICE FEES & CATEGORIES",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Chart color codes and active service classifications",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
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

          // List of Services
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              itemCount: kMunicipalServices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final service = kMunicipalServices[index];

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      // Colored Indicator Circle
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: service.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: service.color.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          service.label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: service.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: service.color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          service.key,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: service.color,
                          ),
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
