import 'package:flutter/material.dart';

class AdminServicesCounts {
  final int hotlines;
  final int kainan;
  final int tuluyan;
  final int tourism;
  final int reports;
  final int arta;
  final double artaComplianceRate;
  final int artaOverdue;

  const AdminServicesCounts({
    this.hotlines = 0,
    this.kainan = 0,
    this.tuluyan = 0,
    this.tourism = 0,
    this.reports = 0,
    this.arta = 0,
    this.artaComplianceRate = 100.0,
    this.artaOverdue = 0,
  });

  factory AdminServicesCounts.fromJson(Map<String, dynamic> json) {
    return AdminServicesCounts(
      hotlines: (json['hotlines'] as num?)?.toInt() ?? 0,
      kainan: (json['kainan'] as num?)?.toInt() ?? 0,
      tuluyan: (json['tuluyan'] as num?)?.toInt() ?? 0,
      tourism: (json['tourism'] as num?)?.toInt() ?? 0,
      reports: (json['reports'] as num?)?.toInt() ?? 0,
      arta: (json['arta'] as num?)?.toInt() ?? 0,
      artaComplianceRate: (json['artaComplianceRate'] as num?)?.toDouble() ?? 100.0,
      artaOverdue: (json['artaOverdue'] as num?)?.toInt() ?? 0,
    );
  }
}

class HotlineItemModel {
  final String id;
  final String name;
  final String category;
  final String? mobileNumber;
  final String? telephone;
  final String? address;
  final int order;
  final bool isActive;

  const HotlineItemModel({
    required this.id,
    required this.name,
    this.category = 'Emergency',
    this.mobileNumber,
    this.telephone,
    this.address,
    this.order = 0,
    this.isActive = true,
  });

  factory HotlineItemModel.fromJson(Map<String, dynamic> json) {
    return HotlineItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Emergency Agency',
      category: json['category']?.toString() ?? 'Emergency',
      mobileNumber: json['mobileNumber']?.toString(),
      telephone: json['telephone']?.toString(),
      address: json['address']?.toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] != false,
    );
  }

  String get primaryNumber {
    if (mobileNumber != null && mobileNumber!.trim().isNotEmpty) {
      return mobileNumber!;
    }
    if (telephone != null && telephone!.trim().isNotEmpty) {
      return telephone!;
    }
    return 'Hotline on duty';
  }
}

class DiningItemModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final String cuisineType;
  final String? openingHours;
  final String? contactNumber;
  final String? facebookUrl;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? googleMapsUrl;
  final String barangay;

  const DiningItemModel({
    required this.id,
    required this.name,
    this.description = '',
    this.address = 'Mapandan, Pangasinan',
    this.cuisineType = 'Filipino Food',
    this.openingHours,
    this.contactNumber,
    this.facebookUrl,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    this.barangay = 'Mapandan',
  });

  factory DiningItemModel.fromJson(Map<String, dynamic> json) {
    return DiningItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Dining Establishment',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? 'Mapandan, Pangasinan',
      cuisineType: json['cuisineType']?.toString() ?? 'Filipino Cuisine',
      openingHours: json['openingHours']?.toString(),
      contactNumber: json['contactNumber']?.toString(),
      facebookUrl: json['facebookUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      googleMapsUrl: json['googleMapsUrl']?.toString(),
      barangay: json['barangay']?.toString() ?? 'Mapandan',
    );
  }
}

class AccommodationItemModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final String type;
  final String? priceRange;
  final String? amenities;
  final String? contactNumber;
  final String? websiteUrl;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? googleMapsUrl;
  final String barangay;

  const AccommodationItemModel({
    required this.id,
    required this.name,
    this.description = '',
    this.address = 'Mapandan, Pangasinan',
    this.type = 'Resort',
    this.priceRange,
    this.amenities,
    this.contactNumber,
    this.websiteUrl,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    this.barangay = 'Mapandan',
  });

  factory AccommodationItemModel.fromJson(Map<String, dynamic> json) {
    return AccommodationItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Accommodation Lodging',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? 'Mapandan, Pangasinan',
      type: json['type']?.toString() ?? 'Resort',
      priceRange: json['priceRange']?.toString(),
      amenities: json['amenities']?.toString(),
      contactNumber: json['contactNumber']?.toString(),
      websiteUrl: json['websiteUrl']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      googleMapsUrl: json['googleMapsUrl']?.toString(),
      barangay: json['barangay']?.toString() ?? 'Mapandan',
    );
  }
}

class TourismSpotItemModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final String? entranceFee;
  final String? bestTimeToVisit;
  final String? contactNumber;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? googleMapsUrl;
  final String barangay;
  final bool isPublished;

  const TourismSpotItemModel({
    required this.id,
    required this.name,
    this.category = 'Heritage',
    this.description = '',
    this.address = 'Mapandan, Pangasinan',
    this.entranceFee,
    this.bestTimeToVisit,
    this.contactNumber,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    this.barangay = 'Mapandan',
    this.isPublished = true,
  });

  factory TourismSpotItemModel.fromJson(Map<String, dynamic> json) {
    return TourismSpotItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Tourist Spot',
      category: json['category']?.toString() ?? 'Heritage',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? 'Mapandan, Pangasinan',
      entranceFee: json['entranceFee']?.toString(),
      bestTimeToVisit: json['bestTimeToVisit']?.toString(),
      contactNumber: json['contactNumber']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      googleMapsUrl: json['googleMapsUrl']?.toString(),
      barangay: json['barangay']?.toString() ?? 'Mapandan',
      isPublished: json['isPublished'] is bool
          ? (json['isPublished'] as bool)
          : (json['isPublished'] != false &&
              json['isPublished'] != 'false' &&
              json['isPublished'] != 0),
    );
  }
}

class ArtaItemModel {
  final String id;
  final String referenceNo;
  final String serviceName;
  final String officeCode;
  final String transactionType;
  final String status;
  final String applicantName;
  final String? applicantContact;
  final String submittedAt;
  final String? deadlineAt;
  final String? completedAt;
  final String slaStatus; // COMPLIANT, PENDING, BREACHED, COMPLETED

  const ArtaItemModel({
    required this.id,
    required this.referenceNo,
    required this.serviceName,
    required this.officeCode,
    this.transactionType = 'SIMPLE',
    this.status = 'RECEIVED',
    this.applicantName = 'Citizen Applicant',
    this.applicantContact,
    required this.submittedAt,
    this.deadlineAt,
    this.completedAt,
    this.slaStatus = 'COMPLIANT',
  });

  factory ArtaItemModel.fromJson(Map<String, dynamic> json) {
    return ArtaItemModel(
      id: json['id']?.toString() ?? '',
      referenceNo: json['referenceNo']?.toString() ?? 'ARTA-REQ',
      serviceName: json['serviceName']?.toString() ?? 'Citizen Charter Service',
      officeCode: json['officeCode']?.toString() ?? 'MTO',
      transactionType: json['transactionType']?.toString() ?? 'SIMPLE',
      status: json['status']?.toString() ?? 'RECEIVED',
      applicantName: json['applicantName']?.toString() ?? 'Citizen Applicant',
      applicantContact: json['applicantContact']?.toString(),
      submittedAt: json['submittedAt']?.toString() ?? '',
      deadlineAt: json['deadlineAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      slaStatus: json['slaStatus']?.toString() ?? 'COMPLIANT',
    );
  }

  Color get slaColor {
    switch (slaStatus.toUpperCase()) {
      case 'BREACHED':
        return const Color(0xFFEF4444);
      case 'PENDING':
        return const Color(0xFF3B82F6);
      case 'COMPLETED':
      case 'COMPLIANT':
      default:
        return const Color(0xFF10B981);
    }
  }
}
