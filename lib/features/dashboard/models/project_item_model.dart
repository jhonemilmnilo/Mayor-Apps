class ProjectStats {
  final int total;
  final int ongoing;
  final int completed;
  final int planned;
  final int onHold;

  ProjectStats({
    required this.total,
    required this.ongoing,
    required this.completed,
    required this.planned,
    required this.onHold,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    return ProjectStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      ongoing: (json['ongoing'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      planned: (json['planned'] as num?)?.toInt() ?? 0,
      onHold: (json['onHold'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProjectItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String location;
  final String? budget;
  final String? contractor;
  final String? startDate;
  final String? endDate;
  final double progress; // 0.0 to 100.0
  final String? imageUrl;
  final String barangay;
  final String createdAt;

  const ProjectItemModel({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Infrastructure',
    this.status = 'Planned',
    this.location = 'Municipality-Wide',
    this.budget,
    this.contractor,
    this.startDate,
    this.endDate,
    this.progress = 0.0,
    this.imageUrl,
    this.barangay = 'Mapandan',
    this.createdAt = '',
  });

  factory ProjectItemModel.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'] ?? json['completionRate'] ?? json['percentage'] ?? 0;
    double parsedProgress = 0.0;
    if (rawProgress is num) {
      parsedProgress = rawProgress.toDouble();
      if (parsedProgress > 0 && parsedProgress <= 1.0) {
        parsedProgress = parsedProgress * 100;
      }
    }

    final rawBudget = json['budget'] ?? json['allocatedBudget'] ?? json['cost'];
    String? parsedBudget;
    if (rawBudget != null) {
      parsedBudget = rawBudget.toString();
    }

    return ProjectItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? json['projectTitle'] ?? 'Municipal Project',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Infrastructure',
      status: (json['status'] ?? 'Planned').toString(),
      location: json['location']?.toString() ?? json['barangay']?.toString() ?? 'Municipality-Wide',
      budget: parsedBudget,
      contractor: json['contractor']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      progress: parsedProgress.clamp(0.0, 100.0),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      barangay: json['barangay']?.toString() ?? 'Mapandan',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PaginatedProjectsResponse {
  final bool success;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final bool hasMore;
  final ProjectStats stats;
  final List<ProjectItemModel> projects;

  PaginatedProjectsResponse({
    required this.success,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
    required this.stats,
    required this.projects,
  });

  factory PaginatedProjectsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['projects'] as List<dynamic>? ?? [];
    return PaginatedProjectsResponse(
      success: json['success'] == true,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      hasMore: json['hasMore'] == true,
      stats: ProjectStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
      projects: rawList
          .map((item) => ProjectItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
