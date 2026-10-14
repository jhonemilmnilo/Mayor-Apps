import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventStats {
  final int totalEvents;
  final int happeningNow;
  final int upcomingEvents;
  final int festivals;

  const EventStats({
    this.totalEvents = 0,
    this.happeningNow = 0,
    this.upcomingEvents = 0,
    this.festivals = 0,
  });

  factory EventStats.fromJson(Map<String, dynamic> json) {
    return EventStats(
      totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
      happeningNow: (json['happeningNow'] as num?)?.toInt() ?? 0,
      upcomingEvents: (json['upcomingEvents'] as num?)?.toInt() ?? 0,
      festivals: (json['festivals'] as num?)?.toInt() ?? 0,
    );
  }
}

class EventItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String startDate;
  final String endDate;
  final String venueName;
  final String address;
  final String? contactNumber;
  final String? imageUrl;
  final List<String> reminders;
  final double? latitude;
  final double? longitude;
  final String? googleMapsUrl;
  final bool isPublished;
  final String barangay;
  final String createdAt;
  final String updatedAt;

  const EventItemModel({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Community',
    required this.startDate,
    required this.endDate,
    this.venueName = 'Mapandan Civic Center',
    this.address = 'Mapandan, Pangasinan',
    this.contactNumber,
    this.imageUrl,
    this.reminders = const [],
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    this.isPublished = true,
    this.barangay = 'Whole Municipality',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory EventItemModel.fromJson(Map<String, dynamic> json) {
    final rawReminders = json['reminders'] as List? ?? [];

    return EventItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Municipal Event',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Community',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      venueName: json['venueName']?.toString() ?? 'Mapandan Civic Center',
      address: json['address']?.toString() ?? 'Mapandan, Pangasinan',
      contactNumber: json['contactNumber']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      reminders: rawReminders.map((e) => e.toString()).toList(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      googleMapsUrl: json['googleMapsUrl']?.toString(),
      isPublished: json['isPublished'] != false,
      barangay: json['barangay']?.toString() ?? 'Whole Municipality',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  DateTime? get startDateTime {
    if (startDate.isEmpty) return null;
    try {
      return DateTime.parse(startDate).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime? get endDateTime {
    if (endDate.isEmpty) return null;
    try {
      return DateTime.parse(endDate).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool get isLiveNow {
    final s = startDateTime;
    final e = endDateTime;
    if (s == null || e == null) return false;
    final now = DateTime.now();
    return s.isBefore(now) && e.isAfter(now);
  }

  bool get isUpcoming {
    final s = startDateTime;
    if (s == null) return false;
    final now = DateTime.now();
    return s.isAfter(now);
  }

  bool get isEnded {
    final e = endDateTime;
    if (e == null) return false;
    final now = DateTime.now();
    return e.isBefore(now);
  }

  String get statusLabel {
    if (isLiveNow) return 'Live Now';
    if (isUpcoming) return 'Upcoming';
    return 'Ended';
  }

  Color get statusColor {
    if (isLiveNow) return const Color(0xFF10B981);
    if (isUpcoming) return const Color(0xFF3B82F6);
    return const Color(0xFF94A3B8);
  }

  Color get statusBgColor {
    return statusColor.withValues(alpha: 0.15);
  }

  String get formattedDateRange {
    final s = startDateTime;
    final e = endDateTime;
    if (s == null && e == null) return 'Schedule TBA';
    if (s != null && e == null) return DateFormat('MMM d, yyyy').format(s);
    if (s == null && e != null) return DateFormat('MMM d, yyyy').format(e);

    final startFmt = DateFormat('MMM d').format(s!);
    final endFmt = DateFormat('MMM d, yyyy').format(e!);

    if (s.year == e.year && s.month == e.month && s.day == e.day) {
      return DateFormat('MMM d, yyyy').format(s);
    } else if (s.year == e.year && s.month == e.month) {
      return '$startFmt – ${e.day}, ${e.year}';
    } else if (s.year == e.year) {
      return '$startFmt – $endFmt';
    } else {
      return '${DateFormat('MMM d, yyyy').format(s)} – $endFmt';
    }
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasReminders => reminders.isNotEmpty;

  String get mapsSearchUrl {
    if (googleMapsUrl != null && googleMapsUrl!.trim().isNotEmpty) {
      return googleMapsUrl!;
    }
    final query = Uri.encodeComponent('$venueName, $address, Mapandan, Pangasinan');
    return 'https://www.google.com/maps/search/?api=1&query=$query';
  }
}

class PaginatedEventsResponse {
  final bool success;
  final List<EventItemModel> events;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final bool hasMore;
  final EventStats stats;

  const PaginatedEventsResponse({
    required this.success,
    required this.events,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
    required this.stats,
  });

  factory PaginatedEventsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['events'] as List? ?? [];
    return PaginatedEventsResponse(
      success: json['success'] == true,
      events: rawList
          .map((e) => EventItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      hasMore: json['hasMore'] == true,
      stats: EventStats.fromJson(json['stats'] ?? {}),
    );
  }
}
