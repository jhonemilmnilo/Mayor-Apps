class OverdueArtaModel {
  final String id;
  final String referenceNo;
  final String serviceName;
  final String officeCode;
  final String officeName;
  final String handlerName;
  final int daysOver;
  final String status;
  final DateTime? deadlineAt;

  const OverdueArtaModel({
    required this.id,
    required this.referenceNo,
    required this.serviceName,
    required this.officeCode,
    required this.officeName,
    required this.handlerName,
    required this.daysOver,
    required this.status,
    this.deadlineAt,
  });

  factory OverdueArtaModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDeadline;
    final rawDeadline = json['deadlineAt'];
    if (rawDeadline != null && rawDeadline is String && rawDeadline.isNotEmpty) {
      parsedDeadline = DateTime.tryParse(rawDeadline);
    }

    final rawDays = json['daysOver'];
    int parsedDays = 1;
    if (rawDays is num) {
      parsedDays = rawDays.toInt();
    } else if (rawDays is String) {
      parsedDays = int.tryParse(rawDays) ?? 1;
    }

    return OverdueArtaModel(
      id: json['id']?.toString() ?? '',
      referenceNo: json['referenceNo']?.toString() ?? 'ARTA-REQ',
      serviceName: json['serviceName']?.toString() ?? 'Citizen Service Request',
      officeCode: json['officeCode']?.toString().toUpperCase() ?? 'LGU',
      officeName: json['officeName']?.toString() ?? (json['officeCode']?.toString() ?? 'LGU'),
      handlerName: json['handlerName']?.toString() ?? 'Unassigned',
      daysOver: parsedDays,
      status: json['status']?.toString() ?? 'IN_PROCESS',
      deadlineAt: parsedDeadline,
    );
  }
}
