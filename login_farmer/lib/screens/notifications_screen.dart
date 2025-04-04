// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:login_farmer/service/notification/notification_model.dart';
import 'package:login_farmer/service/notification/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationRepository.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load notifications: $e')),
      );
    }
  }

  Future<void> _markNotificationAsRead(int index) async {
    await _notificationRepository.markNotificationAsRead(index);
    await _loadNotifications();
  }

  Future<void> _clearAllNotifications() async {
    await _notificationRepository.clearNotifications();
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllNotifications,
            tooltip: 'Clear All Notifications',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return ListTile(
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notification.body),
                      trailing: notification.isRead
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () => _markNotificationAsRead(index),
                            ),
                      onTap: () {
                        // Optional: Handle notification tap
                        // Could navigate to a specific screen based on notification data
                        _markNotificationAsRead(index);
                      },
                    );
                  },
                ),
    );
  }
}
