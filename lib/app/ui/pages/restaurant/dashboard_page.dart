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
import 'package:rizq/app/utils/contact_us_helper.dart';
import 'package:rizq/app/utils/account_deletion_helper.dart';
import 'package:rizq/app/utils/constants/support_constants.dart';
import 'package:rizq/app/utils/constants/image_strings.dart';
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

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
    // Check if restaurant is suspended
    return Obx(() {
      if (controller.isSuspended) {
        return _buildSuspendedScreen(SupportConstants.supportEmail);
      }
      
      final List<Widget> pages = [
        DashboardTab(),
        ProgramSettingsTab(),
        QrScannerPage(),
        RewardsTab(initialTabIndex: _rewardsInitialTab),
        ProfileTab(),
      ];
      
      return Scaffold(
        // No AppBar - each tab has its own
        resizeToAvoidBottomInset: false,
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
        body: pages[_currentIndex],
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
                    Icons.local_activity_outlined,
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
    });
  }

  // All contact us and account deletion functionality moved to helper classes

  // Build suspension screen for suspended restaurants
  Widget _buildSuspendedScreen(String supportEmail) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(MImages.generalLogo, height: 70),
        toolbarHeight: 80,
        // backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            Text(
              'Account Suspended!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your restaurant account has been temporarily suspended by the administrator.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ContactUsHelper.launchEmailApp(
                  SupportConstants.supportEmail,
                  'Account Suspension Appeal - ${controller.name}',
                  'Dear Support Team,\n\n'
                      'I would like to appeal the suspension of my restaurant account.\n\n'
                      'Restaurant Name: ${controller.name}\n'
                      'Account Email: ${authController.currentUser?.email ?? 'N/A'}\n\n'
                      'Please review my account status and let me know how to proceed.\n\n'
                      'Thank you for your assistance.\n\n'
                      'Best regards,\n'
                      '${controller.name}',
                );
              },
              icon: const Icon(Icons.email, color: Colors.white),
              label: Text(
                SupportConstants.contactSupportTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                authController.logout();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
