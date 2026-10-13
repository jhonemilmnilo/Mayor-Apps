class DailyRequestReportStats {
  final int total;
  final int pending;
  final int released;
  final int rejected;
  final double revenue;

  DailyRequestReportStats({
    required this.total,
    required this.pending,
    required this.released,
    required this.rejected,
    required this.revenue,
  });

  factory DailyRequestReportStats.fromJson(Map<String, dynamic> json) {
    return DailyRequestReportStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      released: (json['released'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailyRequestItem {
  final String id;
  final String createdAt;
  final String status;
  final String residentName;
  final String serviceType;
  final String serviceCategory;
  final String? paymentMethod;
  final String? paymentStatus;
  final double amountPaid;

  DailyRequestItem({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.residentName,
    required this.serviceType,
    required this.serviceCategory,
    this.paymentMethod,
    this.paymentStatus,
    required this.amountPaid,
  });

  factory DailyRequestItem.fromJson(Map<String, dynamic> json) {
    return DailyRequestItem(
      id: json['id']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      residentName: json['residentName']?.toString() ?? 'Citizen Resident',
      serviceType: json['serviceType']?.toString() ?? 'Municipal Request',
      serviceCategory: json['serviceCategory']?.toString() ?? 'GENERAL',
      paymentMethod: json['paymentMethod']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PaginatedDailyRequestsResponse {
  final bool success;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final bool hasMore;
  final DailyRequestReportStats stats;
  final List<DailyRequestItem> transactions;

  PaginatedDailyRequestsResponse({
    required this.success,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
    required this.stats,
    required this.transactions,
  });

  factory PaginatedDailyRequestsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['transactions'] as List<dynamic>? ?? [];
    return PaginatedDailyRequestsResponse(
      success: json['success'] == true,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      hasMore: json['hasMore'] == true,
      stats: DailyRequestReportStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
      transactions: rawList
          .map((item) => DailyRequestItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
