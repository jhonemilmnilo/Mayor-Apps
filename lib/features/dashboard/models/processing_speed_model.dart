class ProcessingSpeedTierModel {
  final double avgDays;
  final int limit;
  final int percentage;
  final int count;

  const ProcessingSpeedTierModel({
    required this.avgDays,
    required this.limit,
    required this.percentage,
    required this.count,
  });

  factory ProcessingSpeedTierModel.fromJson(Map<String, dynamic> json, int defaultLimit) {
    final rawAvg = json['avgDays'];
    double parsedAvg = 0.0;
    if (rawAvg is num) {
      parsedAvg = rawAvg.toDouble();
    } else if (rawAvg is String) {
      parsedAvg = double.tryParse(rawAvg) ?? 0.0;
    }

    final rawLimit = json['limit'];
    int parsedLimit = defaultLimit;
    if (rawLimit is num) {
      parsedLimit = rawLimit.toInt();
    }

    final rawPercentage = json['percentage'];
    int parsedPercentage = 0;
    if (rawPercentage is num) {
      parsedPercentage = rawPercentage.toInt();
    } else if (parsedLimit > 0) {
      parsedPercentage = ((parsedAvg / parsedLimit) * 100).round().clamp(0, 100);
    }

    final rawCount = json['count'];
    int parsedCount = 0;
    if (rawCount is num) {
      parsedCount = rawCount.toInt();
    }

    return ProcessingSpeedTierModel(
      avgDays: parsedAvg,
      limit: parsedLimit,
      percentage: parsedPercentage,
      count: parsedCount,
    );
  }

  bool get isWithinCeiling => avgDays <= limit;
}

class StatutoryProcessingSpeedModel {
  final ProcessingSpeedTierModel simple;
  final ProcessingSpeedTierModel complex;
  final ProcessingSpeedTierModel highlyTechnical;

  const StatutoryProcessingSpeedModel({
    required this.simple,
    required this.complex,
    required this.highlyTechnical,
  });

  factory StatutoryProcessingSpeedModel.fromJson(Map<String, dynamic> json) {
    return StatutoryProcessingSpeedModel(
      simple: ProcessingSpeedTierModel.fromJson(
        json['simple'] as Map<String, dynamic>? ?? {},
        3,
      ),
      complex: ProcessingSpeedTierModel.fromJson(
        json['complex'] as Map<String, dynamic>? ?? {},
        7,
      ),
      highlyTechnical: ProcessingSpeedTierModel.fromJson(
        json['highlyTechnical'] as Map<String, dynamic>? ?? {},
        20,
      ),
    );
  }

  factory StatutoryProcessingSpeedModel.fallback() {
    return const StatutoryProcessingSpeedModel(
      simple: ProcessingSpeedTierModel(avgDays: 1.7, limit: 3, percentage: 57, count: 0),
      complex: ProcessingSpeedTierModel(avgDays: 5.0, limit: 7, percentage: 71, count: 0),
      highlyTechnical: ProcessingSpeedTierModel(avgDays: 9.6, limit: 20, percentage: 48, count: 0),
    );
  }
}
