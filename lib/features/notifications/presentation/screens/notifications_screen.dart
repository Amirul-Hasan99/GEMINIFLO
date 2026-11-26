import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifications = state.notifications;
    final unreadCount = state.unreadCount;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF09090B),
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE4E4E7),
            height: 1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20, color: Color(0xFF09090B)),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.home),
        ),
        title: Row(
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(
                color: Color(0xFF09090B),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (notifications.isNotEmpty && unreadCount > 0)
            TextButton.icon(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllAsRead(),
              icon: const Icon(
                LucideIcons.checkCheck,
                size: 15,
                color: Color(0xFF09090B),
              ),
              label: const Text(
                'Tandai Dibaca',
                style: TextStyle(
                  color: Color(0xFF09090B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(notificationProvider.notifier).loadNotifications(),
              color: const Color(0xFF09090B),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return _ShadcnNotificationCard(
                    notification: notif,
                    onTap: () {
                      if (!notif.isRead) {
                        ref
                            .read(notificationProvider.notifier)
                            .markAsRead(notif.id);
                      }
                      if (notif.bookingId != null) {
                        context.push(
                          RouteNames.orderDetailPath(notif.bookingId!),
                        );
                      }
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: const Icon(
                LucideIcons.bellOff,
                size: 24,
                color: Color(0xFF71717A),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Notifikasi',
              style: TextStyle(
                color: Color(0xFF09090B),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aktivitas pesanan, status verifikasi pembayaran, dan pembaruan terkini akan tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF71717A),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShadcnNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _ShadcnNotificationCard({
    required this.notification,
    required this.onTap,
  });

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderCreated:
        return LucideIcons.packagePlus;
      case NotificationType.paymentWaiting:
        return LucideIcons.clock;
      case NotificationType.paymentVerified:
        return LucideIcons.checkCircle2;
      case NotificationType.paymentRejected:
        return LucideIcons.alertCircle;
      case NotificationType.orderStatusChanged:
        return LucideIcons.truck;
      case NotificationType.orderCancelled:
        return LucideIcons.xCircle;
      case NotificationType.system:
        return LucideIcons.info;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}h lalu';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUnread ? const Color(0xFF09090B) : const Color(0xFFE4E4E7),
            width: isUnread ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shadcn style monochrome black icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isUnread ? const Color(0xFF09090B) : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUnread ? const Color(0xFF09090B) : const Color(0xFFE4E4E7),
                ),
              ),
              child: Icon(
                _getIcon(notification.type),
                size: 17,
                color: isUnread ? Colors.white : const Color(0xFF09090B),
              ),
            ),
            const SizedBox(width: 12),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: const Color(0xFF09090B),
                            fontSize: 13.5,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: isUnread ? const Color(0xFF27272A) : const Color(0xFF71717A),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  if (notification.bookingCode != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE4E4E7)),
                      ),
                      child: Text(
                        'Pesanan #${notification.bookingCode}',
                        style: const TextStyle(
                          color: Color(0xFF09090B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF09090B),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
