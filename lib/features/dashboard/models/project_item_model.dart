class ProjectItemModel {
  final String id;
  final String title;
  final String description;
  final String barangay;
  final String category;
  final String status;
  final double progress; // 0.0 to 100.0
  final double budget;
  final double spent;
  final String timeline;
  final String? contractor;
  final String? imageUrl;

  const ProjectItemModel({
    required this.id,
    required this.title,
    this.description = '',
    this.barangay = '',
    this.category = 'Infrastructure',
    this.status = 'IN_PROGRESS',
    this.progress = 0.0,
    this.budget = 0.0,
    this.spent = 0.0,
    this.timeline = '',
    this.contractor,
    this.imageUrl,
  });

  factory ProjectItemModel.fromJson(Map<String, dynamic> json) {
    // Graceful parsing supporting different backend key conventions
    final rawProgress = json['progress'] ?? json['completionRate'] ?? json['percentage'] ?? 0;
    double parsedProgress = 0.0;
    if (rawProgress is num) {
      parsedProgress = rawProgress.toDouble();
      // If backend sends 0.75 instead of 75
      if (parsedProgress > 0 && parsedProgress <= 1.0) {
        parsedProgress = parsedProgress * 100;
      }
    }

    final rawBudget = json['budget'] ?? json['allocatedBudget'] ?? json['cost'] ?? 0;
    final rawSpent = json['spent'] ?? json['disbursed'] ?? json['expended'] ?? 0;

    return ProjectItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? json['projectTitle'] ?? 'Municipal Project',
      description: json['description'] ?? '',
      barangay: json['barangay'] ?? json['location'] ?? 'Municipality-wide',
      category: json['category'] ?? json['type'] ?? 'Infrastructure',
      status: (json['status'] ?? 'IN_PROGRESS').toString().toUpperCase(),
      progress: parsedProgress.clamp(0.0, 100.0),
      budget: (rawBudget as num?)?.toDouble() ?? 0.0,
      spent: (rawSpent as num?)?.toDouble() ?? 0.0,
      timeline: json['timeline'] ?? json['targetDate'] ?? json['completionDate'] ?? '',
      contractor: json['contractor']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
    );
  }
}
