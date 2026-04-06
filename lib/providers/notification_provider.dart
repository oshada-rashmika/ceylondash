import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<NotificationModel> _notifications = [];
  StreamSubscription? _subscription;
  String? _currentUserId;
  bool _isFirstLoad = true;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void initialize(String userId) {
    if (_currentUserId == userId) return;
    
    _currentUserId = userId;
    _isFirstLoad = true;
    _subscription?.cancel();
    
    _subscription = _db.streamNotifications(userId).listen((newNotifications) {
      if (!_isFirstLoad) {
        // Find the new arrivals by comparing IDs
        final existingIds = _notifications.map((n) => n.id).toSet();
        final newlyAdded = newNotifications.where((n) => !existingIds.contains(n.id)).toList();
        
        for (final notif in newlyAdded) {
          if (!notif.isRead) {
            NotificationService().showLocalNotification(
              title: notif.title,
              body: notif.body,
              payload: notif.relatedId,
            );
          }
        }
      }
      
      _notifications = newNotifications;
      _isFirstLoad = false;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.markNotificationAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;
    await _db.markAllNotificationsAsRead(_currentUserId!);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
