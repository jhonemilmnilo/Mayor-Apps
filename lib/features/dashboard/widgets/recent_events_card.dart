import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/api/api_constants.dart';
import '../models/event_item_model.dart';
import 'event_detail_bottom_sheet.dart';
import 'event_filter_modal.dart';
import 'events_audit_modal.dart';

class RecentEventsCard extends StatefulWidget {
  final List<EventItemModel> upcomingEvents;
  final List<EventItemModel> pastEvents;

  const RecentEventsCard({
    super.key,
    required this.upcomingEvents,
    this.pastEvents = const [],
  });

  @override
  State<RecentEventsCard> createState() => _RecentEventsCardState();
}

class _RecentEventsCardState extends State<RecentEventsCard> {
  EventFilterCriteria _filter = const EventFilterCriteria();

  List<EventItemModel> get _allEvents => [...widget.upcomingEvents, ...widget.pastEvents];

  List<EventItemModel> get _filteredEvents {
    return _allEvents.where((item) {
      if (_filter.timeframe != 'ALL') {
        final tf = _filter.timeframe.toUpperCase();
        if (tf == 'LIVE' && !item.isLiveNow) return false;
        if (tf == 'UPCOMING' && !item.isUpcoming) return false;
        if (tf == 'ENDED' && !item.isEnded) return false;
      }
      if (_filter.category != 'ALL' &&
          item.category.toUpperCase() != _filter.category.toUpperCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  void _openFilterModal() {
    EventFilterModal.show(
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
      _filter = const EventFilterCriteria();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;
    final isFiltered = _filter.isFiltered;

    // Smart priority sorting: Live Now first, then Upcoming, then Past fallback
    final liveNow = filtered.where((e) => e.isLiveNow).toList();
    final upcoming = filtered.where((e) => e.isUpcoming).toList();
    final past = filtered.where((e) => e.isEnded).toList();

    List<EventItemModel> displayList = [];
    if (isFiltered) {
      displayList = filtered.take(3).toList();
    } else {
      if (liveNow.isNotEmpty || upcoming.isNotEmpty) {
        displayList = [...liveNow, ...upcoming].take(3).toList();
      } else {
        displayList = past.take(3).toList();
      }
    }

    final hasActiveEvents = liveNow.isNotEmpty || upcoming.isNotEmpty;
    final cardTitle = hasActiveEvents ? "UPCOMING EVENTS" : "RECENT EVENTS";

    String subtitleText;
    if (liveNow.isNotEmpty) {
      subtitleText = "${liveNow.length} happening now • ${upcoming.length} upcoming";
    } else if (upcoming.isNotEmpty) {
      subtitleText = "${upcoming.length} upcoming municipal events";
    } else if (past.isNotEmpty) {
      subtitleText = "${past.length} recent past events";
    } else {
      subtitleText = "No active municipal events scheduled";
    }

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
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardTitle,
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
                      subtitleText,
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

          // Active Filter Pill Bar (strictly Category & Timeframe, NO date range)
          GestureDetector(
            onTap: _openFilterModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isFiltered
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                    : AppColors.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFiltered
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 14,
                    color: isFiltered ? const Color(0xFF8B5CF6) : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFiltered
                          ? "${_filter.category.toUpperCase()} • ${_filter.timeframe.toUpperCase()}"
                          : "ALL CATEGORIES • ALL TIMEFRAMES",
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isFiltered ? const Color(0xFF8B5CF6) : AppColors.textSecondary,
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
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Color(0xFF8B5CF6),
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
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_busy_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No Events Scheduled",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Upcoming festivals, sports and municipal activities will appear here.",
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

          // Action Button: Violet Full-Width button matching web
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                EventsAuditModal.show(
                  context,
                  fallbackEvents: _allEvents,
                  initialFilter: _filter,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
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
                    "VIEW ALL EVENTS",
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

  Widget _buildItemRow(BuildContext context, EventItemModel item) {
    return GestureDetector(
      onTap: () => EventDetailBottomSheet.show(context, item),
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
            // Thumbnail Preview (44x44)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
                color: AppColors.surfaceElevated,
                child: (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty)
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Center(
                          child: Icon(
                            Icons.calendar_month_rounded,
                            size: 20,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // Title + Venue + Schedule
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${item.venueName} • ${item.formattedDateRange}",
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status Indicator (Live Now gets special emerald pulse)
            if (item.isLiveNow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "LIVE",
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: item.statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.category,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: item.isUpcoming ? const Color(0xFF8B5CF6) : AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
