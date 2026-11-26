import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/notification_datasource.dart';
import '../../domain/entities/app_notification.dart';

final notificationDataSourceProvider = Provider<NotificationDataSource>((ref) {
  return NotificationDataSource(ref.watch(apiClientProvider));
});

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    Future.microtask(() => loadNotifications());
    return const NotificationState();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(notificationDataSourceProvider);
      final notifs = await ds.getNotifications();
      state = state.copyWith(notifications: notifs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? bookingId,
    String? bookingCode,
  }) async {
    try {
      final ds = ref.read(notificationDataSourceProvider);
      final newNotif = await ds.addNotification(
        title: title,
        message: message,
        type: type,
        bookingId: bookingId,
        bookingCode: bookingCode,
      );
      state = state.copyWith(notifications: [newNotif, ...state.notifications]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final ds = ref.read(notificationDataSourceProvider);
      await ds.markAsRead(id);
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          return n.id == id ? n.copyWith(isRead: true) : n;
        }).toList(),
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final ds = ref.read(notificationDataSourceProvider);
      await ds.markAllAsRead();
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          return n.copyWith(isRead: true);
        }).toList(),
      );
    } catch (_) {}
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationProvider);
  return notifs.unreadCount;
});
