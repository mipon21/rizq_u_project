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

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final RestaurantController controller = Get.find<RestaurantController>();
  final AuthController authController = Get.find<AuthController>();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      DashboardTab(),
      ProgramSettingsTab(),
      QrScannerPage(),
      RewardsTab(),
      ProfileTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/icons/general-u.png', height: 70),
        toolbarHeight: 80,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => authController.logout(),
          ),
        ],
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
              // IconButton(
              //   icon: Icon(
              //     Icons.qr_code_scanner,
              //     color: _currentIndex == 2
              //         ? Theme.of(context).colorScheme.primary
              //         : null,
              //   ),
              //   tooltip: 'Scan QR',
              //   onPressed: () {
              //     setState(() {
              //       _currentIndex = 2;
              //     });
              //   },
              // ),
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
}
