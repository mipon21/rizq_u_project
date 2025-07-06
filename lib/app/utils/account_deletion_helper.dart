import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class AccountDeletionHelper {
  // Show Delete Account Confirmation dialog
  static void showDeleteAccountConfirmation(
      BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              confirmAccountDeletion(context, authController);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[700],
            ),
            child: const Text('Yes, I want to delete my account'),
          ),
        ],
      ),
    );
  }

  // Final confirmation for account deletion
  static void confirmAccountDeletion(
      BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: const Text(
            'This action is permanent and cannot be undone. All your data will be deleted. Do you want to proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Execute the account deletion
              authController.deleteAccount();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
} 