import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../models/announcement_item_model.dart';
import 'announcement_detail_bottom_sheet.dart';
import 'announcement_filter_modal.dart';
import 'announcements_audit_modal.dart';

class RecentAnnouncementsCard extends StatefulWidget {
  final List<AnnouncementItemModel> announcements;

  const RecentAnnouncementsCard({
    super.key,
    required this.announcements,
  });

  @override
  State<RecentAnnouncementsCard> createState() => _RecentAnnouncementsCardState();
}

class _RecentAnnouncementsCardState extends State<RecentAnnouncementsCard> {
  AnnouncementFilterState _filter = const AnnouncementFilterState();

  List<AnnouncementItemModel> get _filteredAnnouncements {
    return widget.announcements.where((a) {
      if (_filter.priority != 'All' &&
          a.priority.toUpperCase() != _filter.priority.toUpperCase()) {
        return false;
      }
      if (_filter.category != 'All' &&
          a.category.toUpperCase() != _filter.category.toUpperCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  void _openFilterModal() {
    AnnouncementFilterModal.show(
      context,
      initialFilter: _filter,
      onApply: (newFilter) {
        setState(() {
          _filter = newFilter;
        });
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _filter = const AnnouncementFilterState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredAnnouncements.take(3).toList();
    final isFiltered = _filter.isFiltered;

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
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.accentAmber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RECENT ANNOUNCEMENTS",
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Latest ${widget.announcements.length} published announcements",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Active Filter Pill Bar (strictly Category & Priority, NO date range)
          GestureDetector(
            onTap: _openFilterModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFiltered
                    ? AppColors.accentAmber.withValues(alpha: 0.12)
                    : AppColors.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFiltered
                      ? AppColors.accentAmber.withValues(alpha: 0.6)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 14,
                    color: isFiltered ? AppColors.accentAmber : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFiltered
                          ? "${_filter.category.toUpperCase()} • ${_filter.priority.toUpperCase()}"
                          : "ALL TYPES • ALL PRIORITIES",
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isFiltered ? AppColors.accentAmber : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isFiltered)
                    GestureDetector(
                      onTap: _clearFilters,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.accentAmber,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // List Items
          if (displayList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign_outlined,
                      color: AppColors.accentAmber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No Announcements Published",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "New announcements for residents will appear here.",
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...displayList.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildItemRow(context, item),
              );
            }),

          const SizedBox(height: 6),

          // Action Button: Amber Full-Width button matching web
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                AnnouncementsAuditModal.show(
                  context,
                  fallbackAnnouncements: widget.announcements,
                  initialFilter: _filter,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "VIEW ALL ANNOUNCEMENTS",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, AnnouncementItemModel item) {
    return GestureDetector(
      onTap: () => AnnouncementDetailBottomSheet.show(context, item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: item.priorityBadgeBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: item.priorityColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                item.priority.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                  color: item.priorityColor,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Title + Category + Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isPinned) ...[
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 11,
                          color: Color(0xFFF97316),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${item.category} • ${item.formattedDate}",
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status Dot
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: item.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.statusText,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
