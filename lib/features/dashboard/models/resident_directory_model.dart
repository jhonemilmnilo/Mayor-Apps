class ResidentReportStats {
  final int total;
  final int seniors;
  final int pwd;
  final int soloParents;
  final int fourPs;

  ResidentReportStats({
    required this.total,
    required this.seniors,
    required this.pwd,
    required this.soloParents,
    required this.fourPs,
  });

  factory ResidentReportStats.fromJson(Map<String, dynamic> json) {
    return ResidentReportStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      seniors: (json['seniors'] as num?)?.toInt() ?? 0,
      pwd: (json['pwd'] as num?)?.toInt() ?? 0,
      soloParents: (json['soloParents'] as num?)?.toInt() ?? 0,
      fourPs: (json['fourPs'] as num?)?.toInt() ?? 0,
    );
  }
}

class ResidentDirectoryItem {
  final String id;
  final String fullName;
  final String firstName;
  final String lastName;
  final String gender;
  final String civilStatus;
  final String barangay;
  final bool isSenior;
  final bool isPWD;
  final bool isSoloParent;
  final bool is4Ps;
  final String? contactNumber;
  final String? email;
  final String createdAt;

  ResidentDirectoryItem({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.civilStatus,
    required this.barangay,
    required this.isSenior,
    required this.isPWD,
    required this.isSoloParent,
    required this.is4Ps,
    this.contactNumber,
    this.email,
    required this.createdAt,
  });

  factory ResidentDirectoryItem.fromJson(Map<String, dynamic> json) {
    return ResidentDirectoryItem(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Citizen Resident',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'N/A',
      civilStatus: json['civilStatus']?.toString() ?? 'Single',
      barangay: json['barangay']?.toString() ?? 'Mapandan',
      isSenior: json['isSenior'] == true,
      isPWD: json['isPWD'] == true,
      isSoloParent: json['isSoloParent'] == true,
      is4Ps: json['is4Ps'] == true,
      contactNumber: json['contactNumber']?.toString(),
      email: json['email']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PaginatedResidentsResponse {
  final bool success;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final bool hasMore;
  final ResidentReportStats stats;
  final List<ResidentDirectoryItem> residents;

  PaginatedResidentsResponse({
    required this.success,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
    required this.stats,
    required this.residents,
  });

  factory PaginatedResidentsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['residents'] as List<dynamic>? ?? [];
    return PaginatedResidentsResponse(
      success: json['success'] == true,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      hasMore: json['hasMore'] == true,
      stats: ResidentReportStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
      residents: rawList
          .map((item) => ResidentDirectoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
