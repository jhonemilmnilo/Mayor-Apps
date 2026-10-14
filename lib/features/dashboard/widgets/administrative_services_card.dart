import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../models/admin_service_model.dart';
import 'arta_compliance_modal.dart';
import 'citizen_report_filter_modal.dart';
import 'citizen_reports_modal.dart';
import 'hotlines_directory_modal.dart';
import 'kainan_directory_modal.dart';
import 'tourism_directory_modal.dart';
import 'tuluyan_directory_modal.dart';

class AdministrativeServicesCard extends StatelessWidget {
  final AdminServicesCounts adminServices;
  final String selectedBarangay;

  const AdministrativeServicesCard({
    super.key,
    required this.adminServices,
    this.selectedBarangay = 'ALL',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.getBorder(context), width: 1.2),
        boxShadow: AppColors.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ADMINISTRATIVE SERVICES",
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.2,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    Text(
                      "Centralized municipal operations, directories & hotlines",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.getTextSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 1. ARTA Compliance
          _buildServiceRow(
            context: context,
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF3B82F6),
            title: "ARTA Compliance",
            subtitle: "RA 11032 Citizen Charter SLA statutory audit",
            onTap: () => ArtaComplianceModal.show(
              context,
              summaryCounts: adminServices,
            ),
          ),
          const SizedBox(height: 10),

          // 2. Kainan Directory Hub
          _buildServiceRow(
            context: context,
            icon: Icons.restaurant_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: "Kainan Hub Directory",
            subtitle: "Municipal dining, cafes & culinary spots",
            onTap: () => KainanDirectoryModal.show(context),
          ),
          const SizedBox(height: 10),

          // 3. Tuluyan Lodging Hub
          _buildServiceRow(
            context: context,
            icon: Icons.hotel_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: "Tuluyan Lodging Hub",
            subtitle: "Accommodations, resorts & staycation venues",
            onTap: () => TuluyanDirectoryModal.show(context),
          ),
          const SizedBox(height: 10),

          // 4. Tourism Gallery Directory
          _buildServiceRow(
            context: context,
            icon: Icons.landscape_rounded,
            iconColor: const Color(0xFF10B981),
            title: "Tourism Gallery",
            subtitle: "Heritage spots, municipal parks & landmarks",
            onTap: () => TourismDirectoryModal.show(context),
          ),
          const SizedBox(height: 10),

          // 5. Civic Incident Reports
          _buildServiceRow(
            context: context,
            icon: Icons.report_problem_outlined,
            iconColor: const Color(0xFFEC4899),
            title: "Incident Reports",
            subtitle: "Citizen public safety reports & civic tracking",
            onTap: () => CitizenReportsModal.show(
              context,
              initialFilter: const CitizenReportFilterCriteria(),
              selectedBarangay: selectedBarangay,
              initialTotalCount: adminServices.reports,
            ),
          ),
          const SizedBox(height: 10),

          // 6. Emergency Hotlines Directory
          _buildServiceRow(
            context: context,
            icon: Icons.phone_in_talk_rounded,
            iconColor: const Color(0xFFEF4444),
            title: "Emergency Hotlines",
            subtitle: "PNP, BFP, RHU, MDRRMO quick response",
            onTap: () => HotlinesDirectoryModal.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceElevated(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.getTextSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Dedicated VIEW Button
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "VIEW",
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
