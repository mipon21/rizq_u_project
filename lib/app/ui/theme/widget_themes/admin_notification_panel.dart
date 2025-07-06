import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../controllers/admin_controller.dart';
import '../../../routes/app_pages.dart';

class AdminNotificationPanel extends StatelessWidget {
  final bool isBottomSheet;

  const AdminNotificationPanel({
    super.key,
    this.isBottomSheet = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    Widget content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  controller.markAllNotificationsAsRead();
                },
                child: const Text('Mark all as read'),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: Obx(() {
            if (controller.notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No notifications',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: controller.notifications.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final notification = controller.notifications[index];
                final bool isRead = notification['read'] ?? false;
                final String title = notification['title'] ?? 'Notification';
                final String message = notification['message'] ?? '';
                final String type = notification['type'] ?? 'info';
                final Timestamp? timestamp =
                    notification['timestamp'] as Timestamp?;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getNotificationColor(type).withOpacity(0.2),
                    child: Icon(
                      _getNotificationIcon(type),
                      color: _getNotificationColor(type),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message),
                      const SizedBox(height: 4),
                      Text(
                        timestamp != null
                            ? DateFormat('MMM dd, yyyy • hh:mm a')
                                .format(timestamp.toDate())
                            : 'Unknown date',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    if (!isRead) {
                      controller.markNotificationAsRead(notification['id']);
                    }

                    // Handle notification tap based on type
                    _handleNotificationTap(notification);
                  },
                  tileColor: isRead ? null : Colors.blue.withOpacity(0.05),
                );
              },
            );
          }),
        ),
      ],
    );

    if (isBottomSheet) {
      return content;
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: content,
      );
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'restaurant_approval':
        return Colors.green;
      case 'restaurant_rejection':
        return Colors.red;
      case 'subscription':
        return Colors.purple;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'restaurant_approval':
        return Icons.check_circle;
      case 'restaurant_rejection':
        return Icons.cancel;
      case 'subscription':
        return Icons.payment;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final String type = notification['type'] ?? 'info';
    final String? relatedId = notification['relatedId'];

    // Navigate based on notification type
    if (type == 'restaurant_approval' || type == 'restaurant_rejection') {
      if (Get.isBottomSheetOpen ?? false) {
        Get.back(); // Close notification panel
      }
      Get.toNamed(Routes.ADMIN_RESTAURANTS);
    } else if (type == 'subscription') {
      if (Get.isBottomSheetOpen ?? false) {
        Get.back(); // Close notification panel
      }
      Get.toNamed(Routes.ADMIN_CUSTOM_SUBSCRIPTION_PLANS);
    }
  }
}
