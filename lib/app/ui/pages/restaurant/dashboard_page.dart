// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this to pubspec.yaml if not present
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart';
import 'package:rizq/app/controllers/restaurant_controller.dart';
import 'package:rizq/app/routes/app_pages.dart';
import 'package:intl/intl.dart';
import 'package:rizq/app/ui/pages/restaurant/tabs/qr_scanner_page.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import 'package:rizq/app/controllers/program_controller.dart';
import 'package:rizq/app/ui/pages/restaurant/tabs/rewards_tab.dart';
import 'package:rizq/app/ui/pages/restaurant/tabs/dashboard_tab.dart';
import 'package:rizq/app/ui/pages/restaurant/tabs/program_settings_tab.dart';
import 'package:rizq/app/ui/pages/restaurant/tabs/profile_tab.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();

  // Static method to change tabs
  static void navigateToTab(int index, {int? rewardsSubtabIndex}) {
    final state = Get.find<_DashboardPageState>(tag: 'dashboard_page_state');
    if (index == 3 && rewardsSubtabIndex != null) {
      state.changeToRewardsTab(rewardsSubtabIndex);
    } else {
      state.changeTab(index);
    }
  }
}

class _DashboardPageState extends State<DashboardPage> {
  final RestaurantController controller = Get.find<RestaurantController>();
  final AuthController authController = Get.find<AuthController>();
  int _currentIndex = 0;
  // Track the initial tab index for RewardsTab
  int _rewardsInitialTab = 0;

  // Add this method to allow changing tabs from outside
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });

    // If changing to rewards tab, fetch the latest data
    if (index == 3) {
      controller.fetchClaimedRewards();
    }
  }

  // Add this method to change to rewards tab with specific subtab
  void changeToRewardsTab(int rewardsSubtabIndex) {
    setState(() {
      _currentIndex = 3; // Rewards tab index
      _rewardsInitialTab = rewardsSubtabIndex;
    });

    // Fetch the latest data
    controller.fetchClaimedRewards();
  }

  @override
  void initState() {
    super.initState();

    // Register this state with GetX so it can be found from anywhere
    Get.put(this, tag: 'dashboard_page_state');
  }

  @override
  void dispose() {
    // Remove this state from GetX when disposed
    Get.delete<_DashboardPageState>(tag: 'dashboard_page_state');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      DashboardTab(),
      ProgramSettingsTab(),
      QrScannerPage(),
      RewardsTab(initialTabIndex: _rewardsInitialTab),
      ProfileTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/icons/general-u.png', height: 70),
        toolbarHeight: 80,
        actions: _currentIndex == 4
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (value) {
                      if (value == 'contact_us') {
                        _showContactUsDialog(context);
                      } else if (value == 'delete_account') {
                        _showDeleteAccountConfirmation(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'contact_us',
                        child: Row(
                          children: [
                            Icon(Icons.contact_support,
                                color: MColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text('Contact Us'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete_account',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever,
                                color: Colors.red[700], size: 20),
                            const SizedBox(width: 8),
                            Text('Account Deletion'),
                          ],
                        ),
                      ),
                    ],
                    child: Row(
                      children: [
                        Icon(Icons.help,
                            color: Theme.of(context).primaryColor, size: 16),
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
                    tooltip: 'Help',
                  ),
                ),
              ]
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        child: const Icon(Icons.qr_code_scanner),
        tooltip: 'Scan Customer QR',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _currentIndex == 0
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Home',
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: _currentIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Program Settings',
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
              SizedBox(width: 50),
              IconButton(
                icon: Icon(
                  Icons.card_giftcard_outlined,
                  color: _currentIndex == 3
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Rewards History',
                onPressed: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                  controller.fetchClaimedRewards();
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.person_outline,
                  color: _currentIndex == 4
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Edit Profile',
                onPressed: () {
                  setState(() {
                    _currentIndex = 4;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show Contact Us dialog
  void _showContactUsDialog(BuildContext context) {
    final supportEmail = 'support@rizq.app';
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Contact Us'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You have a question regarding the Rizq application?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, color: MColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        supportEmail,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: MColors.primary),
                      onPressed: () {
                        _copyToClipboard(supportEmail);
                      },
                      tooltip: 'Copy to clipboard',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subject field
              // Column(
              //   crossAxisAlignment: CrossAxisAlignment.start,

              //   children: [
              //     Text(
              //       'Subject',
              //       style: TextStyle(
              //         fontWeight: FontWeight.w500,
              //         fontSize: 14,
              //       ),
              //     ),
              //     const SizedBox(height: 8),
              //     TextField(
              //       controller: subjectController,
              //       decoration: InputDecoration(
              //         hintText: 'Enter subject',
              //         border: OutlineInputBorder(
              //           borderRadius: BorderRadius.circular(4),
              //           borderSide: BorderSide(color: Colors.grey[300]!),
              //         ),
              //         contentPadding:
              //             const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              //         fillColor: Colors.white,
              //         filled: true,
              //       ),
              //     ),
              //     const SizedBox(height: 16),

              //     // Description field
              //     Text(
              //       'Description',
              //       style: TextStyle(
              //         fontWeight: FontWeight.w500,
              //         fontSize: 14,
              //       ),
              //     ),
              //     const SizedBox(height: 8),
              //     TextField(
              //       controller: descriptionController,
              //       maxLines: 5,
              //       decoration: InputDecoration(
              //         hintText: 'Describe your issue or question',
              //         border: OutlineInputBorder(
              //           borderRadius: BorderRadius.circular(4),
              //           borderSide: BorderSide(color: Colors.grey[300]!),
              //         ),
              //         contentPadding: const EdgeInsets.all(12),
              //         fillColor: Colors.white,
              //         filled: true,
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _launchEmailApp(
                supportEmail,
                subjectController.text,
                descriptionController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Launch email app with pre-filled information
  void _launchEmailApp(String email, String subject, String body) async {
    final profile = controller.restaurantProfile.value;
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Create email body with footer
    final completeBody = '''
$body

Regards,
${profile?.name ?? 'Restaurant'}
$userEmail
Restaurant UID: $uid
''';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters({
        'subject': subject,
        'body': completeBody,
      }),
    );

    try {
      // Try to launch with explicit app selection
      final bool launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
        ),
      );

      if (launched) {
        Navigator.of(Get.context!).pop(); // Close the dialog after launching
      } else {
        // Fallback: Show a dialog with the email information that can be copied
        _showEmailCopyDialog(email, subject, completeBody);
      }
    } catch (e) {
      // Show error and manual email instructions
      _showEmailCopyDialog(email, subject, completeBody);
    }
  }

  // Show dialog with email information that can be copied
  void _showEmailCopyDialog(String email, String subject, String body) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Email Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not launch email app automatically. Please copy the information below and send an email manually:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildCopyableField('Email', email),
              const SizedBox(height: 8),
              _buildCopyableField('Subject', subject),
              const SizedBox(height: 8),
              _buildCopyableField('Message', body, maxLines: 5),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Build a copyable text field with a copy button
  Widget _buildCopyableField(String label, String content, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SelectableText(
                    content,
                    maxLines: maxLines,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: MColors.primary),
                onPressed: () {
                  _copyToClipboard(content);
                },
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Copy text to clipboard and show a snackbar
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      'Text copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  // Helper method to encode query parameters
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // Show Delete Account Confirmation dialog
  void _showDeleteAccountConfirmation(BuildContext context) {
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
              _confirmAccountDeletion(context);
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
  void _confirmAccountDeletion(BuildContext context) {
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
              // authController.deleteAccount();
              Get.snackbar(
                'Account Deletion',
                'Your account deletion request has been submitted.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red[700],
                colorText: Colors.white,
              );
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
