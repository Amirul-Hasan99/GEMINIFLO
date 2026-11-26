import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_notification.dart';

class NotificationDataSource {
  final ApiClient client;
  NotificationDataSource(this.client);
  Future<List<AppNotification>> getNotifications() async {
    final r = await client.get(ApiConstants.notifications);
    final rows = r.data['data']['notifications'] as List? ?? const [];
    return rows.map((x) {
      final j = Map<String, dynamic>.from(x as Map);
      return AppNotification(
        id: '${j['id']}',
        title: '${j['title']}',
        message: '${j['message']}',
        createdAt: DateTime.parse('${j['createdAt']}').toLocal(),
        type: _type('${j['type']}'),
        bookingId: j['bookingId']?.toString(),
        bookingCode: j['bookingCode']?.toString(),
        isRead: j['isRead'] as bool? ?? false,
      );
    }).toList();
  }

  Future<AppNotification> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? bookingId,
    String? bookingCode,
  }) async {
    await client.post(
      ApiConstants.notifications,
      data: {
        'title': title,
        'message': message,
        'type': type.name,
        'booking_id': bookingId,
        'booking_code': bookingCode,
      },
    );
    final rows = await getNotifications();
    return rows.first;
  }

  Future<void> markAsRead(String id) =>
      client.put(ApiConstants.notificationRead(id));
  Future<void> markAllAsRead() => client.put(ApiConstants.notificationsReadAll);
  Future<void> clearAll() => client.delete(ApiConstants.notificationsClear);
  static NotificationType _type(String name) => NotificationType.values
      .firstWhere((t) => t.name == name, orElse: () => NotificationType.system);
}
