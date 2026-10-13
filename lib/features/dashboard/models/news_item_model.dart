import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewsStats {
  final int totalArticles;
  final int announcements;
  final int localNews;

  const NewsStats({
    this.totalArticles = 0,
    this.announcements = 0,
    this.localNews = 0,
  });

  factory NewsStats.fromJson(Map<String, dynamic> json) {
    return NewsStats(
      totalArticles: (json['totalArticles'] as num?)?.toInt() ?? 0,
      announcements: (json['announcements'] as num?)?.toInt() ?? 0,
      localNews: (json['localNews'] as num?)?.toInt() ?? 0,
    );
  }
}

class NewsItemModel {
  final String id;
  final String title;
  final String content;
  final String author;
  final String category;
  final String? imageUrl;
  final List<String> images;
  final bool isPublished;
  final String publishDate;
  final String barangay;
  final String createdAt;

  const NewsItemModel({
    required this.id,
    required this.title,
    this.content = '',
    this.author = 'Executive Office',
    this.category = 'Local News',
    this.imageUrl,
    this.images = const [],
    this.isPublished = true,
    this.publishDate = '',
    this.barangay = 'Whole Municipality',
    this.createdAt = '',
  });

  factory NewsItemModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List? ?? [];
    return NewsItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Municipal News Article',
      content: json['content']?.toString() ?? '',
      author: json['author']?.toString() ?? 'Executive Office',
      category: json['category']?.toString() ?? 'Local News',
      imageUrl: json['imageUrl']?.toString(),
      images: rawImages.map((e) => e.toString()).toList(),
      isPublished: json['isPublished'] != false,
      publishDate: json['publishDate']?.toString() ?? json['createdAt']?.toString() ?? '',
      barangay: json['barangay']?.toString() ?? 'Whole Municipality',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  String get formattedDate {
    if (publishDate.isEmpty && createdAt.isEmpty) return 'Recent';
    try {
      final target = publishDate.isNotEmpty ? publishDate : createdAt;
      final dt = DateTime.parse(target).toLocal();
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return publishDate;
    }
  }

  Color get statusColor {
    return isPublished ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
  }

  String get statusText {
    return isPublished ? 'Published' : 'Draft';
  }

  bool get hasGallery => images.isNotEmpty;

  int get totalMediaCount {
    int count = images.length;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty && !images.contains(imageUrl)) {
      count++;
    }
    return count;
  }
}

class PaginatedNewsResponse {
  final bool success;
  final List<NewsItemModel> news;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final bool hasMore;
  final NewsStats stats;

  const PaginatedNewsResponse({
    required this.success,
    required this.news,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
    required this.stats,
  });

  factory PaginatedNewsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['news'] as List? ?? [];
    return PaginatedNewsResponse(
      success: json['success'] == true,
      news: rawList
          .map((e) => NewsItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      hasMore: json['hasMore'] == true,
      stats: NewsStats.fromJson(json['stats'] ?? {}),
    );
  }
}
