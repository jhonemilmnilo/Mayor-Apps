import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnnouncementStats {
  final int totalNotices;
  final int pinnedBriefs;
  final int criticalAlerts;

  const AnnouncementStats({
    this.totalNotices = 0,
    this.pinnedBriefs = 0,
    this.criticalAlerts = 0,
  });

  factory AnnouncementStats.fromJson(Map<String, dynamic> json) {
    return AnnouncementStats(
      totalNotices: (json['totalNotices'] as num?)?.toInt() ?? 0,
      pinnedBriefs: (json['pinnedBriefs'] as num?)?.toInt() ?? 0,
      criticalAlerts: (json['criticalAlerts'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnnouncementItemModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String priority;
  final String category;
  final bool isPinned;
  final bool isActive;
  final String barangay;
  final String? expiryDate;
  final String? eventSchedule;
  final String? authorEmail;
  final String? department;
  final String createdAt;

  const AnnouncementItemModel({
    required this.id,
    required this.title,
    this.content = '',
    this.imageUrl,
    this.priority = 'Normal',
    this.category = 'General',
    this.isPinned = false,
    this.isActive = true,
    this.barangay = 'Whole Municipality',
    this.expiryDate,
    this.eventSchedule,
    this.authorEmail,
    this.department,
    this.createdAt = '',
  });

  factory AnnouncementItemModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'LGU Notice',
      content: json['content']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      priority: json['priority']?.toString() ?? 'Normal',
      category: json['category']?.toString() ?? 'General',
      isPinned: json['isPinned'] == true,
      isActive: json['isActive'] != false,
      barangay: json['barangay']?.toString() ?? 'Whole Municipality',
      expiryDate: json['expiryDate']?.toString(),
      eventSchedule: json['eventSchedule']?.toString() ?? json['eventDate']?.toString(),
      authorEmail: json['authorEmail']?.toString(),
      department: json['department']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  String get formattedDate {
    if (createdAt.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return createdAt;
    }
  }

  String get formattedExpiry {
    if (expiryDate != null && expiryDate!.isNotEmpty) {
      try {
        final dt = DateTime.parse(expiryDate!).toLocal();
        return DateFormat('MMM d, yyyy').format(dt);
      } catch (_) {
        return expiryDate!;
      }
    }
    if (eventSchedule != null && eventSchedule!.isNotEmpty) {
      return eventSchedule!;
    }
    return 'No expiration set';
  }

  Color get priorityColor {
    final p = priority.toUpperCase();
    if (p == 'CRITICAL' || p == 'URGENT') {
      return const Color(0xFFEF4444); // Red 500
    } else if (p == 'HIGH' || p == 'IMPORTANT') {
      return const Color(0xFFF59E0B); // Amber 500
    } else if (p == 'NORMAL') {
      return const Color(0xFF3B82F6); // Blue 500
    }
    return const Color(0xFF94A3B8); // Slate 400
  }

  Color get priorityBadgeBg {
    return priorityColor.withValues(alpha: 0.15);
  }

  Color get statusColor {
    return isActive ? const Color(0xFF10B981) : const Color(0xFF64748B);
  }

  String get statusText {
    return isActive ? 'Active' : 'Expired';
  }
}

class AnnouncementQueryResponse {
  final bool success;
  final List<AnnouncementItemModel> announcements;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final bool hasMore;
  final AnnouncementStats stats;

  const AnnouncementQueryResponse({
    required this.success,
    required this.announcements,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
    required this.stats,
  });

  factory AnnouncementQueryResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['announcements'] as List? ?? [];
    return AnnouncementQueryResponse(
      success: json['success'] == true,
      announcements: rawList
          .map((e) => AnnouncementItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      hasMore: json['hasMore'] == true,
      stats: AnnouncementStats.fromJson(json['stats'] ?? {}),
    );
  }
}
