import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<NotificationModel> _notifications = [];
  StreamSubscription? _subscription;
  StreamSubscription? _ordersSubscription;
  String? _currentUserId;
  bool _isFirstLoad = true;
  bool _isFirstOrdersLoad = true;
  final Map<String, String> _lastKnownStatuses = {};

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void initialize(String userId) {
    if (_currentUserId == userId) return;
    
    _currentUserId = userId;
    _isFirstLoad = true;
    _isFirstOrdersLoad = true;
    _subscription?.cancel();
    _ordersSubscription?.cancel();
    _lastKnownStatuses.clear();
    
    // Watch Notification Inbox (Chat, Promos, etc)
    _subscription = _db.streamNotifications(userId).listen((newNotifications) {
      if (!_isFirstLoad) {
        // Find the new arrivals by comparing IDs
        final existingIds = _notifications.map((n) => n.id).toSet();
        final newlyAdded = newNotifications.where((n) => !existingIds.contains(n.id)).toList();
        
        for (final notif in newlyAdded) {
          if (!notif.isRead) {
            NotificationService().showLocalNotification(
              id: DateTime.now().millisecond,
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

    // --- Order Status Watcher (Detects changes even from Console) ---
    _ordersSubscription = _db.streamCustomerOrders(userId).listen(
      (orders) {
        for (final order in orders) {
          final oldStatus = _lastKnownStatuses[order.id];
          
          // If status changed and it's NOT the first time we see this order
          if (!_isFirstOrdersLoad && oldStatus != null && oldStatus != order.status) {
            NotificationService().showLocalNotification(
              id: order.id.hashCode,
              title: 'Order Updated! 📦',
              body: 'Your order #${order.id.substring(0, 5).toUpperCase()} is now ${order.status.replaceAll('_', ' ')}',
              payload: order.id,
            );
          }
          
          // Update local status map
          _lastKnownStatuses[order.id] = order.status;
        }
        _isFirstOrdersLoad = false;
      },
      onError: (e) {
        debugPrint('Order Stream Error: $e');
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.markNotificationAsRead(notificationId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.deleteNotification(notificationId);
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
