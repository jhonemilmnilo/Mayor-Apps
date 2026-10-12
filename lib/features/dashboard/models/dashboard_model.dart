import 'project_item_model.dart';

class MetricCounts {
  final int residents;
  final int jobs;
  final int reports;
  final int projects;

  MetricCounts({
    required this.residents,
    required this.jobs,
    required this.reports,
    required this.projects,
  });

  factory MetricCounts.fromJson(Map<String, dynamic> json) {
    return MetricCounts(
      residents: json['residents'] ?? 0,
      jobs: json['jobs'] ?? 0,
      reports: json['reports'] ?? 0,
      projects: json['projects'] ?? 0,
    );
  }
}

class RevenueChartPoint {
  final String date;
  final double total;
  final Map<String, double> categories;

  RevenueChartPoint({
    required this.date,
    required this.total,
    this.categories = const {},
  });

  factory RevenueChartPoint.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'] as Map<String, dynamic>? ?? {};
    final parsedCats = <String, double>{};
    rawCats.forEach((k, v) {
      if (v is num) {
        parsedCats[k] = v.toDouble();
      }
    });

    return RevenueChartPoint(
      date: json['date'] ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      categories: parsedCats,
    );
  }
}

class RevenueAnalytics {
  final double totalAmount;
  final List<RevenueChartPoint> chart;

  RevenueAnalytics({required this.totalAmount, required this.chart});

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) {
    var rawList = json['chart'] as List? ?? [];
    return RevenueAnalytics(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      chart: rawList.map((e) => RevenueChartPoint.fromJson(e)).toList(),
    );
  }
}

class TransactionChartPoint {
  final String date;
  final int total;
  final int requests;
  final int evaluation;
  final int processing;
  final int released;
  final int rejected;
  final Map<String, int> categories;

  TransactionChartPoint({
    required this.date,
    required this.total,
    this.requests = 0,
    this.evaluation = 0,
    this.processing = 0,
    this.released = 0,
    this.rejected = 0,
    this.categories = const {},
  });

  factory TransactionChartPoint.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'] as Map<String, dynamic>? ?? {};
    final catMap = rawCats.map((k, v) => MapEntry(k, (v as num).toInt()));
    final tot = json['total'] ?? json['requests'] ?? 0;

    return TransactionChartPoint(
      date: json['date'] ?? '',
      total: tot,
      requests: json['requests'] ?? tot,
      evaluation: json['evaluation'] ?? 0,
      processing: json['processing'] ?? 0,
      released: json['released'] ?? 0,
      rejected: json['rejected'] ?? 0,
      categories: catMap,
    );
  }
}

class TransactionAnalytics {
  final int totalCount;
  final List<TransactionChartPoint> chart;

  TransactionAnalytics({required this.totalCount, required this.chart});

  factory TransactionAnalytics.fromJson(Map<String, dynamic> json) {
    var rawList = json['chart'] as List? ?? [];
    return TransactionAnalytics(
      totalCount: json['totalCount'] ?? 0,
      chart: rawList.map((e) => TransactionChartPoint.fromJson(e)).toList(),
    );
  }
}

class DemographicChartPoint {
  final String date;
  final int count;

  DemographicChartPoint({required this.date, required this.count});

  factory DemographicChartPoint.fromJson(Map<String, dynamic> json) {
    return DemographicChartPoint(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class DemographicAnalytics {
  final int totalCount;
  final List<DemographicChartPoint> chart;

  DemographicAnalytics({required this.totalCount, required this.chart});

  factory DemographicAnalytics.fromJson(Map<String, dynamic> json) {
    var rawList = json['chart'] as List? ?? [];
    return DemographicAnalytics(
      totalCount: json['totalCount'] ?? 0,
      chart: rawList.map((e) => DemographicChartPoint.fromJson(e)).toList(),
    );
  }
}

class MapPlaceItem {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String? description;
  final String? imageUrl;

  MapPlaceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.description,
    this.imageUrl,
  });

  factory MapPlaceItem.fromJson(Map<String, dynamic> json) {
    return MapPlaceItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'OTHER',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 16.0333,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 120.4500,
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class MayorDashboardData {
  final String themeColor;
  final String selectedBarangay;
  final MetricCounts counts;
  final RevenueAnalytics revenue;
  final TransactionAnalytics transactions;
  final DemographicAnalytics demographics;
  final int residentsRegistered;
  final List<dynamic> announcements;
  final List<dynamic> news;
  final List<dynamic> upcomingEvents;
  final List<ProjectItemModel> activeProjects;
  final List<dynamic> payments;
  final List<dynamic> recentTransactions;
  final List<dynamic> recentReports;
  final List<dynamic> staffLogs;
  final List<MapPlaceItem> mapPlaces;
  final List<String> barangays;

  MayorDashboardData({
    required this.themeColor,
    required this.selectedBarangay,
    required this.counts,
    required this.revenue,
    required this.transactions,
    required this.demographics,
    required this.residentsRegistered,
    required this.announcements,
    required this.news,
    required this.upcomingEvents,
    required this.activeProjects,
    required this.payments,
    required this.recentTransactions,
    required this.recentReports,
    required this.staffLogs,
    required this.mapPlaces,
    required this.barangays,
  });

  factory MayorDashboardData.fromJson(Map<String, dynamic> json) {
    final analytics = json['analytics'] as Map<String, dynamic>? ?? {};
    final recentFeeds = json['recentFeeds'] as Map<String, dynamic>? ?? {};
    final rawPlaces = json['mapPlaces'] as List? ?? [];
    final rawProjects = recentFeeds['projects'] as List? ?? [];

    return MayorDashboardData(
      themeColor: json['themeColor'] ?? '#FF003C',
      selectedBarangay: json['selectedBarangay'] ?? '',
      counts: MetricCounts.fromJson(json['counts'] ?? {}),
      revenue: RevenueAnalytics.fromJson(analytics['revenue'] ?? {}),
      transactions: TransactionAnalytics.fromJson(analytics['transactions'] ?? {}),
      demographics: DemographicAnalytics.fromJson(analytics['demographics'] ?? {}),
      residentsRegistered: analytics['residentsRegistered'] ?? 0,
      announcements: recentFeeds['announcements'] as List? ?? [],
      news: recentFeeds['news'] as List? ?? [],
      upcomingEvents: recentFeeds['upcomingEvents'] as List? ?? [],
      activeProjects: rawProjects.map((p) {
        if (p is Map<String, dynamic>) {
          return ProjectItemModel.fromJson(p);
        }
        return ProjectItemModel.fromJson({});
      }).toList(),
      payments: recentFeeds['payments'] as List? ?? [],
      recentTransactions: recentFeeds['transactions'] as List? ?? [],
      recentReports: recentFeeds['reports'] as List? ?? [],
      staffLogs: recentFeeds['staffLogs'] as List? ?? [],
      mapPlaces: rawPlaces.map((p) => MapPlaceItem.fromJson(p as Map<String, dynamic>)).toList(),
      barangays: (json['barangays'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

