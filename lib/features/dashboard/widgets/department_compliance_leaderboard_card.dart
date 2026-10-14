import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../models/department_compliance_model.dart';

class DepartmentComplianceLeaderboardCard extends StatelessWidget {
  final List<DepartmentComplianceModel> leaderboard;
  final int maxItems;

  const DepartmentComplianceLeaderboardCard({
    super.key,
    required this.leaderboard,
    this.maxItems = 6,
  });

  @override
  Widget build(BuildContext context) {
    const accentTeal = Color(0xFF14B8A6); // Teal 500

    final displayedList = leaderboard.take(maxItems).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accentTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.balance_rounded,
                  color: accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DEPARTMENT COMPLIANCE",
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: accentTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "RA 11032 Anti-Red Tape Authority (ARTA) SLA",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Leaderboard List
          if (displayedList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 32,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No departmental compliance data recorded yet",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final dept = displayedList[index];
                final rank = index + 1;

                Color rankBadgeBg;
                Color rankTextColor;
                if (rank == 1) {
                  rankBadgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.2);
                  rankTextColor = const Color(0xFFF59E0B);
                } else if (rank == 2) {
                  rankBadgeBg = const Color(0xFF94A3B8).withValues(alpha: 0.2);
                  rankTextColor = const Color(0xFFE2E8F0);
                } else if (rank == 3) {
                  rankBadgeBg = const Color(0xFFB45309).withValues(alpha: 0.2);
                  rankTextColor = const Color(0xFFD97706);
                } else {
                  rankBadgeBg = Colors.white.withValues(alpha: 0.05);
                  rankTextColor = AppColors.textSecondary;
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank Badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: rankBadgeBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: rankTextColor.withValues(alpha: 0.4), width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "#$rank",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: rankTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Department Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    dept.officeName,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white12, width: 0.6),
                                  ),
                                  child: Text(
                                    dept.officeCode,
                                    style: GoogleFonts.inter(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "Done: ${dept.completed}",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Pending: ${dept.pending}",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (dept.overdue > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    "Overdue: ${dept.overdue}",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFF43F5E),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Rate & Status Pill
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${dept.complianceRate.toStringAsFixed(dept.complianceRate.truncateToDouble() == dept.complianceRate ? 0 : 1)}%",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: dept.statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: dept.statusColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              dept.statusLabel.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: dept.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),

          // Footnote
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ranked by statutory SLA compliance rate",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                "PST Working Days",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accentTeal.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
