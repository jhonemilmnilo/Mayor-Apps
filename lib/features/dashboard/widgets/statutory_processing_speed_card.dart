import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/api/api_constants.dart';
import '../models/processing_speed_model.dart';

class StatutoryProcessingSpeedCard extends StatelessWidget {
  final StatutoryProcessingSpeedModel processingSpeed;

  const StatutoryProcessingSpeedCard({
    super.key,
    required this.processingSpeed,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF6366F1); // Indigo 500

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
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.gauge,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "STATUTORY PROCESSING SPEED",
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
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Average working days vs. RA 11032 statutory ceilings",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 14),

          // 1. Simple Transactions Tier (Emerald #10B981)
          _buildTierRow(
            title: "Simple Transactions",
            statutoryLimitLabel: "Statutory Limit: 3 Days",
            tier: processingSpeed.simple,
            themeColor: const Color(0xFF10B981),
          ),

          const SizedBox(height: 12),

          // 2. Complex Transactions Tier (Blue #3B82F6)
          _buildTierRow(
            title: "Complex Transactions",
            statutoryLimitLabel: "Statutory Limit: 7 Days",
            tier: processingSpeed.complex,
            themeColor: const Color(0xFF3B82F6),
          ),

          const SizedBox(height: 12),

          // 3. Highly Technical Tier (Indigo #6366F1)
          _buildTierRow(
            title: "Highly Technical",
            statutoryLimitLabel: "Statutory Limit: 20 Days",
            tier: processingSpeed.highlyTechnical,
            themeColor: const Color(0xFF6366F1),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Footnote Area matching web system
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Statutory Day 0: ",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Clock rolls over after 5:00 PM or weekends",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 0.8),
                ),
                child: Text(
                  "PST Working Days",
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierRow({
    required String title,
    required String statutoryLimitLabel,
    required ProcessingSpeedTierModel tier,
    required Color themeColor,
  }) {
    final isWithinCeiling = tier.isWithinCeiling;
    final progressFraction = (tier.percentage / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Title & Avg Working Days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  Text(
                    "${tier.avgDays.toStringAsFixed(tier.avgDays.truncateToDouble() == tier.avgDays ? 0 : 1)} / ${tier.limit} Working Days",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isWithinCeiling
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFF43F5E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isWithinCeiling
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : const Color(0xFFF43F5E).withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isWithinCeiling ? "WITHIN SLA" : "EXCEEDED",
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: isWithinCeiling
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF43F5E),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Visual Progress Bar
          Stack(
            children: [
              Container(
                height: 7,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progressFraction,
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // Footer info: Statutory Limit vs Recorded Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statutoryLimitLabel,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "${tier.count} transactions recorded",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
