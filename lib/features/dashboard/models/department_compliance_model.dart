import 'package:flutter/material.dart';

class DepartmentComplianceModel {
  final String officeCode;
  final String officeName;
  final double complianceRate;
  final int completed;
  final int pending;
  final int overdue;
  final int total;

  DepartmentComplianceModel({
    required this.officeCode,
    required this.officeName,
    required this.complianceRate,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.total,
  });

  factory DepartmentComplianceModel.fromJson(Map<String, dynamic> json) {
    return DepartmentComplianceModel(
      officeCode: json['officeCode']?.toString() ?? '',
      officeName: json['officeName']?.toString() ?? 'Department Office',
      complianceRate: (json['complianceRate'] as num?)?.toDouble() ?? 100.0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isCompliant => complianceRate >= 90.0;
  bool get isModerate => complianceRate >= 75.0 && complianceRate < 90.0;
  bool get isAtRisk => complianceRate < 75.0;

  Color get statusColor {
    if (isCompliant) return const Color(0xFF10B981); // Emerald 500
    if (isModerate) return const Color(0xFFF59E0B); // Amber 500
    return const Color(0xFFF43F5E); // Rose 500
  }

  String get statusLabel {
    if (isCompliant) return "Compliant";
    if (isModerate) return "Moderate";
    return "At Risk";
  }

  IconData get officeIcon {
    final code = officeCode.toUpperCase();
    if (code.contains('BPLO') || code.contains('PERMIT')) {
      return Icons.store_mall_directory_rounded;
    }
    if (code.contains('ENGINEER') || code.contains('BUILDING')) {
      return Icons.architecture_rounded;
    }
    if (code.contains('TREASURY') || code.contains('TREASURER')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (code.contains('CIVIL') || code.contains('REGISTRAR')) {
      return Icons.history_edu_rounded;
    }
    if (code.contains('RHU') || code.contains('HEALTH')) {
      return Icons.medical_services_rounded;
    }
    if (code.contains('ASSESSOR')) {
      return Icons.real_estate_agent_rounded;
    }
    if (code.contains('POSO') || code.contains('TRAFFIC')) {
      return Icons.local_police_rounded;
    }
    return Icons.domain_rounded;
  }
}
