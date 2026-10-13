class CitizenReportStats {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int rejected;

  CitizenReportStats({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.rejected,
  });

  factory CitizenReportStats.fromJson(Map<String, dynamic> json) {
    return CitizenReportStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      inProgress: (json['inProgress'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
    );
  }
}

class CitizenReportItem {
  final String id;
  final String category;
  final String description;
  final String status;
  final List<String> images;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? adminComment;
  final String createdAt;
  final String reporterName;
  final String? reporterEmail;
  final String barangayName;

  CitizenReportItem({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    required this.images,
    this.latitude,
    this.longitude,
    this.address,
    this.adminComment,
    required this.createdAt,
    required this.reporterName,
    this.reporterEmail,
    required this.barangayName,
  });

  factory CitizenReportItem.fromJson(Map<String, dynamic> json) {
    var rawImages = json['images'];
    List<String> parsedImages = [];
    if (rawImages is List) {
      parsedImages = rawImages.map((e) => e.toString()).toList();
    }

    return CitizenReportItem(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General Grievance',
      description: json['description']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'PENDING').toUpperCase(),
      images: parsedImages,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address']?.toString(),
      adminComment: json['adminComment']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      reporterName: json['reporterName']?.toString() ?? 'Citizen Resident',
      reporterEmail: json['reporterEmail']?.toString(),
      barangayName: json['barangayName']?.toString() ?? 'Mapandan',
    );
  }
}

class PaginatedCitizenReportsResponse {
  final bool success;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final bool hasMore;
  final CitizenReportStats stats;
  final List<CitizenReportItem> reports;

  PaginatedCitizenReportsResponse({
    required this.success,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
    required this.stats,
    required this.reports,
  });

  factory PaginatedCitizenReportsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['reports'] as List<dynamic>? ?? [];
    return PaginatedCitizenReportsResponse(
      success: json['success'] == true,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      hasMore: json['hasMore'] == true,
      stats: CitizenReportStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
      reports: rawList
          .map((item) => CitizenReportItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
