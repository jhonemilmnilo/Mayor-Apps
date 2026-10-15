import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../models/news_item_model.dart';

class NewsDetailBottomSheet extends StatelessWidget {
  final NewsItemModel news;

  const NewsDetailBottomSheet({
    super.key,
    required this.news,
  });

  static void show(BuildContext context, NewsItemModel news) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewsDetailBottomSheet(news: news),
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
                        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
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
    final hasCover = news.imageUrl != null && news.imageUrl!.trim().isNotEmpty;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.90;
    final isDark = AppColors.isDark(context);

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.getBorder(context), width: 1.5),
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
                color: isDark ? Colors.white24 : Colors.black12,
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
                  // Photo Cover Banner
                  if (hasCover) ...[
                    GestureDetector(
                      onTap: () => _showZoomableImage(context, news.imageUrl!),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 190,
                              width: double.infinity,
                              color: AppColors.surfaceElevated,
                              child: Image.network(
                                news.imageUrl!,
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
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          news.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ),

                      // Status Badge (Published vs Draft)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: news.statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: news.statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: news.statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              news.statusText.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: news.statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scope / Barangay Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: Text(
                          news.barangay.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Article Title
                  Text(
                    news.title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.3,
                      height: 1.25,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Article Content / Body
                  Text(
                    "ARTICLE CONTENT / STORY",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Text(
                      news.content.trim().isNotEmpty
                          ? news.content
                          : "No text content recorded for this press release.",
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                        color: AppColors.getTextPrimary(context).withValues(alpha: 0.9),
                      ),
                    ),
                  ),

                  // Gallery Photos Carousel / Thumbnails (if any)
                  if (news.images.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "ATTACHED GALLERY PHOTOS",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AppColors.getTextSecondary(context),
                          ),
                        ),
                        Text(
                          "${news.images.length} Photos",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: news.images.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final imgUrl = news.images[idx];
                          return GestureDetector(
                            onTap: () => _showZoomableImage(context, imgUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 84,
                                height: 84,
                                color: AppColors.surfaceElevated,
                                child: Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.broken_image_rounded, size: 20, color: Colors.white38),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 2x2 Information Grid
                  Text(
                    "ARTICLE METADATA",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      // Target Scope
                      Expanded(
                        child: _buildInfoCard(
                          context: context,
                          icon: Icons.location_on_rounded,
                          iconColor: const Color(0xFF10B981),
                          label: "TARGET SCOPE",
                          value: news.barangay,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Publisher
                      Expanded(
                        child: _buildInfoCard(
                          context: context,
                          icon: Icons.person_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          label: "AUTHOR / PUBLISHER",
                          value: news.author,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Published Date
                      Expanded(
                        child: _buildInfoCard(
                          context: context,
                          icon: Icons.calendar_month_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          label: "PUBLISH DATE",
                          value: news.formattedDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Total Media Count
                      Expanded(
                        child: _buildInfoCard(
                          context: context,
                          icon: Icons.photo_library_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          label: "MEDIA ATTACHMENTS",
                          value: "${news.totalMediaCount} Photo${news.totalMediaCount == 1 ? '' : 's'}",
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
                        backgroundColor: isDark ? AppColors.surfaceElevated : const Color(0xFFF1F5F9),
                        foregroundColor: AppColors.getTextPrimary(context),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: AppColors.getBorder(context)),
                        ),
                      ),
                      child: Text(
                        "Close Article",
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
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(context)),
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
                    color: AppColors.getTextSecondary(context),
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
              color: AppColors.getTextPrimary(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
