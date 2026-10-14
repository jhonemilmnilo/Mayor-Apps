import 'package:flutter/material.dart';

class StaffAuditLogModel {
  final String id;
  final String staffName;
  final String department;
  final String action;
  final String details;
  final String status;
  final String time;
  final String createdAt;

  StaffAuditLogModel({
    required this.id,
    required this.staffName,
    required this.department,
    required this.action,
    required this.details,
    required this.status,
    required this.time,
    required this.createdAt,
  });

  factory StaffAuditLogModel.fromJson(Map<String, dynamic> json) {
    return StaffAuditLogModel(
      id: json['id']?.toString() ?? '',
      staffName: json['staffName']?.toString() ?? 'Municipal Staff',
      department: (json['department']?.toString() ?? 'LGU Operations').toUpperCase(),
      action: json['action']?.toString() ?? 'processed request',
      details: json['details']?.toString() ?? '',
      status: json['status']?.toString() ?? 'COMPLETED',
      time: json['time']?.toString() ?? json['timestamp']?.toString() ?? 'Recently',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Color get departmentColor {
    final dept = department.toUpperCase();
    if (dept.contains('POSO') || dept.contains('TRAFFIC')) {
      return const Color(0xFF3B82F6); // Blue 500
    }
    if (dept.contains('RPT') || dept.contains('ASSESSOR')) {
      return const Color(0xFF10B981); // Emerald 500
    }
    if (dept.contains('TREASURY') || dept.contains('PAYMENT')) {
      return const Color(0xFFF59E0B); // Amber 500
    }
    if (dept.contains('ENGINEERING') || dept.contains('BUILDING')) {
      return const Color(0xFF8B5CF6); // Purple 500
    }
    if (dept.contains('HEALTH') || dept.contains('SANITARY')) {
      return const Color(0xFFEC4899); // Pink 500
    }
    return const Color(0xFF6366F1); // Indigo 500 default
  }

  IconData get departmentIcon {
    final dept = department.toUpperCase();
    if (dept.contains('POSO') || dept.contains('TRAFFIC')) {
      return Icons.local_police_rounded;
    }
    if (dept.contains('RPT') || dept.contains('ASSESSOR')) {
      return Icons.domain_verification_rounded;
    }
    if (dept.contains('TREASURY') || dept.contains('PAYMENT')) {
      return Icons.payments_rounded;
    }
    if (dept.contains('ENGINEERING') || dept.contains('BUILDING')) {
      return Icons.architecture_rounded;
    }
    return Icons.badge_rounded;
  }
}
