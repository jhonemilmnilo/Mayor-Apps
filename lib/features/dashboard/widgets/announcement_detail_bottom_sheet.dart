import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../models/announcement_item_model.dart';

class AnnouncementDetailBottomSheet extends StatelessWidget {
  final AnnouncementItemModel announcement;

  const AnnouncementDetailBottomSheet({
    super.key,
    required this.announcement,
  });

  static void show(BuildContext context, AnnouncementItemModel announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnnouncementDetailBottomSheet(announcement: announcement),
    );
  }

  void _showZoomableImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 260,
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.accentAmber),
                      ),
                    );
                  },
                  errorBuilder: (ctx, err, stack) => Container(
                    padding: const EdgeInsets.all(24),
                    color: AppColors.surfaceElevated,
                    child: const Text("Failed to load photo", style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = announcement.imageUrl != null && announcement.imageUrl!.trim().isNotEmpty;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Banner if available
                  if (hasImage) ...[
                    GestureDetector(
                      onTap: () => _showZoomableImage(context, announcement.imageUrl!),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              color: AppColors.surfaceElevated,
                              child: Image.network(
                                announcement.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Center(
                                  child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 36),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Tap to zoom",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Badges Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (announcement.isPinned)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.push_pin_rounded, size: 12, color: Color(0xFFF97316)),
                              const SizedBox(width: 4),
                              Text(
                                "PINNED",
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFFF97316),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: announcement.priorityBadgeBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: announcement.priorityColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          "${announcement.priority.toUpperCase()} PRIORITY",
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: announcement.priorityColor,
                          ),
                        ),
                      ),

                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          announcement.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: announcement.statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: announcement.statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: announcement.statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              announcement.statusText.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: announcement.statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Notice Title
                  Text(
                    announcement.title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.3,
                      height: 1.25,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Notice Body
                  Text(
                    "NOTICE BODY / MESSAGE",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      announcement.content.trim().isNotEmpty
                          ? announcement.content
                          : "No additional details provided for this executive notice.",
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2x2 Information Grid
                  Text(
                    "METADATA & SCHEDULE",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      // Target Scope
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.location_on_rounded,
                          iconColor: const Color(0xFF10B981),
                          label: "TARGET SCOPE",
                          value: announcement.barangay,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Author / Publisher
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.person_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          label: "AUTHOR / PUBLISHER",
                          value: announcement.authorEmail ??
                              announcement.department ??
                              "Executive Office",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Posted Date
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.calendar_month_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          label: "POSTED DATE",
                          value: announcement.formattedDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Expiry Date / Schedule
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.access_time_rounded,
                          iconColor: AppColors.accentAmber,
                          label: "EXPIRY / SCHEDULE",
                          value: announcement.formattedExpiry,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Text(
                        "Close Notice",
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
