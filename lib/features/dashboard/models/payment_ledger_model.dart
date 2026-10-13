class PaymentLedgerStats {
  final int totalCount;
  final double totalRevenue;
  final int paidCount;
  final int pendingCount;
  final double avgPayment;

  PaymentLedgerStats({
    required this.totalCount,
    required this.totalRevenue,
    required this.paidCount,
    required this.pendingCount,
    required this.avgPayment,
  });

  factory PaymentLedgerStats.fromJson(Map<String, dynamic> json) {
    return PaymentLedgerStats(
      totalCount: json['totalCount'] ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      paidCount: json['paidCount'] ?? 0,
      pendingCount: json['pendingCount'] ?? 0,
      avgPayment: (json['avgPayment'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PaymentLedgerItem {
  final String id;
  final double amount;
  final String method;
  final String status;
  final String? orNumber;
  final String createdAt;
  final String serviceType;
  final String serviceCategory;
  final String payerName;

  PaymentLedgerItem({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    this.orNumber,
    required this.createdAt,
    required this.serviceType,
    required this.serviceCategory,
    required this.payerName,
  });

  factory PaymentLedgerItem.fromJson(Map<String, dynamic> json) {
    return PaymentLedgerItem(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: (json['method'] ?? 'CASH').toString().toUpperCase(),
      status: (json['status'] ?? 'PAID').toString().toUpperCase(),
      orNumber: json['orNumber'],
      createdAt: json['createdAt'] ?? '',
      serviceType: json['serviceType'] ?? 'Municipal Fee',
      serviceCategory: json['serviceCategory'] ?? 'GENERAL',
      payerName: json['payerName'] ?? 'Walk-in Resident',
    );
  }
}

class PaginatedPaymentsResponse {
  final bool success;
  final List<PaymentLedgerItem> payments;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final bool hasMore;
  final PaymentLedgerStats stats;

  PaginatedPaymentsResponse({
    required this.success,
    required this.payments,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
    required this.stats,
  });

  factory PaginatedPaymentsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['payments'] as List? ?? [])
        .map((e) => PaymentLedgerItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaginatedPaymentsResponse(
      success: json['success'] == true,
      payments: list,
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      hasMore: json['hasMore'] ?? false,
      stats: PaymentLedgerStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
