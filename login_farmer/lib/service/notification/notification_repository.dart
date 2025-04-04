import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_model.dart';

class NotificationRepository {
  static const String _notificationsKey = 'app_notifications';
  static const int _maxStoredNotifications = 100;

  // Save a new notification
  Future<void> saveNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create notification model
      final notification = NotificationModel(
        title: title,
        body: body,
        data: data ?? {},
      );

      // Retrieve existing notifications
      List<NotificationModel> notifications = await getNotifications();

      // Add new notification
      notifications.insert(0, notification);

      // Trim to max stored notifications
      if (notifications.length > _maxStoredNotifications) {
        notifications = notifications.sublist(0, _maxStoredNotifications);
      }

      // Save notifications
      await prefs.setStringList(_notificationsKey,
          notifications.map((n) => json.encode(n.toJson())).toList());
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  // Get all stored notifications
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Retrieve notifications
      final notificationStrings = prefs.getStringList(_notificationsKey) ?? [];

      // Parse notifications
      return notificationStrings
          .map((n) => NotificationModel.fromJson(json.decode(n)))
          .toList();
    } catch (e) {
      debugPrint('Error retrieving notifications: $e');
      return [];
    }
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Retrieve notifications
      List<NotificationModel> notifications = await getNotifications();

      // Ensure index is valid
      if (index >= 0 && index < notifications.length) {
        notifications[index].isRead = true;

        // Save updated notifications
        await prefs.setStringList(_notificationsKey,
            notifications.map((n) => json.encode(n.toJson())).toList());
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Clear all notifications
  Future<void> clearNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('Error getting unread notification count: $e');
      return 0;
    }
  }
}
