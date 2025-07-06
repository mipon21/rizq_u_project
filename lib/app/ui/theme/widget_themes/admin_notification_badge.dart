import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:badges/badges.dart' as badges;
import '../../../controllers/admin_controller.dart';

class AdminNotificationBadge extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color badgeColor;
  final EdgeInsets padding;

  const AdminNotificationBadge({
    super.key,
    required this.child,
    required this.onTap,
    this.badgeColor = Colors.red,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return Padding(
      padding: padding,
      child: Obx(() => badges.Badge(
            position: badges.BadgePosition.topEnd(top: 0, end: 0),
            showBadge: controller.unreadNotifications.value > 0,
            badgeContent: Text(
              controller.unreadNotifications.value.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: badgeColor,
              padding: const EdgeInsets.all(4),
            ),
            child: InkWell(
              onTap: onTap,
              child: child,
            ),
          )),
    );
  }
}
