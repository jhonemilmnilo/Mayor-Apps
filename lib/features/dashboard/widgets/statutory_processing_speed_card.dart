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
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.getBorder(context), width: 1.2),
        boxShadow: AppColors.getCardShadow(context),
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
                        color: AppColors.getTextPrimary(context),
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
                              color: AppColors.getTextSecondary(context),
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
          Divider(height: 1, color: AppColors.getBorder(context)),
          const SizedBox(height: 14),

          // 1. Simple Transactions Tier (Emerald #10B981)
          _buildTierRow(
            context,
            title: "Simple Transactions",
            statutoryLimitLabel: "Statutory Limit: 3 Days",
            tier: processingSpeed.simple,
            themeColor: const Color(0xFF10B981),
          ),

          const SizedBox(height: 12),

          // 2. Complex Transactions Tier (Blue #3B82F6)
          _buildTierRow(
            context,
            title: "Complex Transactions",
            statutoryLimitLabel: "Statutory Limit: 7 Days",
            tier: processingSpeed.complex,
            themeColor: const Color(0xFF3B82F6),
          ),

          const SizedBox(height: 12),

          // 3. Highly Technical Tier (Indigo #6366F1)
          _buildTierRow(
            context,
            title: "Highly Technical",
            statutoryLimitLabel: "Statutory Limit: 20 Days",
            tier: processingSpeed.highlyTechnical,
            themeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildTierRow(
    BuildContext context, {
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
        color: AppColors.getSurfaceElevated(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorder(context).withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Avg Working Days (Flexible & Responsive)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${tier.avgDays.toStringAsFixed(tier.avgDays.truncateToDouble() == tier.avgDays ? 0 : 1)} / ${tier.limit} Days",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(width: 5),
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
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          color: isWithinCeiling
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF43F5E),
                        ),
                      ),
                    ),
                  ],
                ),
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
                  color: (AppColors.isDark(context) ? Colors.white : Colors.black).withValues(alpha: 0.08),
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
              Flexible(
                child: Text(
                  statutoryLimitLabel,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: AppColors.getTextSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  "${tier.count} recorded",
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: AppColors.getTextSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
