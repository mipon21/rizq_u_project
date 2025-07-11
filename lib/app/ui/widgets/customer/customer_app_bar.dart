import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/support_constants.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/contact_service.dart';
import 'confirmation_dialog.dart';
import 'package:rizq/app/utils/constants/image_strings.dart';
class CustomerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final bool showHelpMenu;
  final String title;
  final List<Widget>? actions;
  final Widget? bottom;
  final double? toolbarHeight;

  const CustomerAppBar({
    super.key,
    this.showBackButton = false,
    this.showHelpMenu = false,
    this.title = '',
    this.actions,
    this.bottom,
    this.toolbarHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      title: title.isNotEmpty
          ? Text(title)
          : Image.asset(MImages.generalLogo, height: 70),
      toolbarHeight: toolbarHeight,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_outlined,
                color: MColors.primary,
              ),
              onPressed: () => Get.back(),
            )
          : null,
      actions: _buildActions(context),
      bottom: bottom as PreferredSizeWidget?,
      shadowColor: Colors.transparent,
    );
  }

  List<Widget>? _buildActions(BuildContext context) {
    if (actions != null) return actions;
    
    if (showHelpMenu) {
      return [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: PopupMenuButton<String>(
            color: Colors.white,
            onSelected: (value) => _handleMenuAction(value, context),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'contact_us',
                child: Row(
                  children: [
                    Icon(Icons.headset_mic_sharp, color: MColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Contact Us'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete_account',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Account', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            tooltip: 'Help',
            child: Row(
              children: [
                Icon(Icons.help, color: Theme.of(context).primaryColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Help',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    
    return null;
  }

  void _handleMenuAction(String value, BuildContext context) {
    switch (value) {
      case 'contact_us':
        ContactService.sendEmail(
          email: SupportConstants.supportEmail,
          subject: 'Question about Rizq Application',
          message: '',
        );
        break;
      case 'delete_account':
       _confirmDeleteAccount(context);
        break;
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    ConfirmationDialog.show(
      context: context,
      title: 'Confirm Account Deletion',
      content: 'This action is permanent and cannot be undone. Do you want to proceed?',
      confirmText: 'Delete Account',
      confirmTextColor: Colors.white,
      
      confirmColor: Colors.red,
      onConfirm: () {
        final authController = Get.find<AuthController>();
        authController.deleteAccount();
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight((toolbarHeight ?? 80) + ((bottom as PreferredSizeWidget?)?.preferredSize.height ?? 0));
} 