import 'package:flutter/material.dart';

class ActivityLogItemModel {
  final String id;
  final String type; // 'resident', 'report', 'payment', 'transaction'
  final String user;
  final String action;
  final String details;
  final String time;
  final DateTime? createdAt;
  final String barangay;

  const ActivityLogItemModel({
    required this.id,
    required this.type,
    required this.user,
    required this.action,
    required this.details,
    required this.time,
    this.createdAt,
    this.barangay = 'Mapandan',
  });

  factory ActivityLogItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString());
    }

    return ActivityLogItemModel(
      id: json['id']?.toString() ?? '',
      type: (json['type']?.toString() ?? 'resident').toLowerCase(),
      user: json['user']?.toString() ?? 'A Resident',
      action: json['action']?.toString() ?? 'recorded activity for',
      details: json['details']?.toString() ?? 'Service Item',
      time: json['time']?.toString() ?? 'Just now',
      createdAt: parsedDate,
      barangay: json['barangay']?.toString() ?? 'Mapandan',
    );
  }

  // DPA Compliant Masked Name: "Juan Dela Cruz" -> "Juan C."
  String get maskedUser {
    final trimmed = user.trim();
    if (trimmed.isEmpty) return 'A Resident';
    if (trimmed.contains('@')) {
      final parts = trimmed.split('@');
      return parts[0].length > 2 ? '${parts[0].substring(0, 3)}***@${parts[1]}' : trimmed;
    }
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length <= 1) return trimmed;
    final firstName = words.sublist(0, words.length - 1).join(' ');
    final lastInitial = words.last.isNotEmpty ? words.last[0].toUpperCase() : '';
    return '$firstName $lastInitial.';
  }

  Color get typeColor {
    switch (type) {
      case 'resident':
        return const Color(0xFF3B82F6); // Blue
      case 'report':
        return const Color(0xFFF59E0B); // Amber
      case 'payment':
        return const Color(0xFF10B981); // Emerald
      case 'transaction':
        return const Color(0xFFA855F7); // Purple
      default:
        return const Color(0xFFF43F5E); // Rose
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'resident':
        return Icons.person_add_rounded;
      case 'report':
        return Icons.warning_amber_rounded;
      case 'payment':
        return Icons.check_circle_outline_rounded;
      case 'transaction':
        return Icons.description_outlined;
      default:
        return Icons.insights_rounded;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'resident':
        return 'NEW RESIDENT';
      case 'report':
        return 'INCIDENT REPORT';
      case 'payment':
        return 'PAYMENT';
      case 'transaction':
        return 'SERVICE REQUEST';
      default:
        return 'ACTIVITY';
    }
  }
}
