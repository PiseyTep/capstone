// lib/services/notification/notification_model.dart
import 'dart:convert';

class NotificationModel {
  final int? id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  bool isRead;

  NotificationModel({
    this.id,
    required this.title,
    required this.body,
    required this.data,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'data': data,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
      };

  // Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] is Map ? json['data'] : {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }

  // Custom comparison method
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        id == other.id &&
        title == other.title &&
        body == other.body;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ body.hashCode;
}
