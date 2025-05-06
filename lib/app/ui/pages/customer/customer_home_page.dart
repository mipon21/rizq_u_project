import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart';
import 'package:rizq/app/controllers/customer_controller.dart';
import '../../../routes/app_pages.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import 'package:rizq/app/utils/app_events.dart';
import 'package:rizq/app/ui/pages/customer/qr_code_page.dart';
import 'package:rizq/app/ui/pages/customer/customer_profile_page.dart';
import 'package:rizq/app/ui/pages/customer/home_tab.dart';
import 'package:rizq/app/ui/pages/customer/rewards_tab.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({Key? key}) : super(key: key);

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> with RouteAware {
  final CustomerController controller = Get.find<CustomerController>();
  final AuthController authController = Get.find<AuthController>();
  final RouteObserver<PageRoute> routeObserver =
      Get.find<RouteObserver<PageRoute>>();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch data when the page is created
    _refreshData();

    // Check if we have navigation arguments upon initial creation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args != null && args is Map && args.containsKey('navigateTo')) {
        final tabIndex = args['navigateTo'] as int;
        if (tabIndex >= 0 && tabIndex < 4) {
          _changeTab(tabIndex);
        }
      }

      // Check if there's already a tab navigation request
      // This handles the case where the event was fired before this page loaded
      if (AppEvents.navigateToTab.value >= 0 &&
          AppEvents.navigateToTab.value < 4) {
        if (kDebugMode) {
          print(
              "DEBUG: Found existing tab navigation request: ${AppEvents.navigateToTab.value}");
        }
        _changeTab(AppEvents.navigateToTab.value);
        AppEvents.navigateToTab.value = -1;
      }

      // Set up a permanent worker to listen for tab navigation events
      // This ensures the listener persists as long as the app is running
      _setupTabNavigationListener();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    // Refresh data when returning to this page
    _refreshData();

    // Check for navigation result
    final result = Get.arguments;
    if (result != null && result is Map && result.containsKey('navigateTo')) {
      final tabIndex = result['navigateTo'] as int;
      if (tabIndex >= 0 && tabIndex < 4) {
        _changeTab(tabIndex);
      }
    }
  }

  @override
  void dispose() {
    // Unsubscribe from route observer
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Refresh data method
  void _refreshData() {
    controller.fetchAllRestaurantPrograms();
    // Also fetch history data for the rewards tab
    controller.fetchClaimHistory();
    controller.fetchScanHistory();
  }

  // Method to change tab
  void _changeTab(int index) {
    if (kDebugMode) {
      print(
          "DEBUG: _changeTab called with index $index (current: $_currentIndex)");
    }

    // Refresh data when switching tabs to ensure fresh content
    if (_currentIndex != index) {
      _refreshTabSpecificData(index);
    }

    setState(() {
      _currentIndex = index;
    });
    if (kDebugMode) {
      print("DEBUG: Tab changed to $_currentIndex");
    }
  }

  // Refresh data specific to the selected tab
  void _refreshTabSpecificData(int tabIndex) {
    switch (tabIndex) {
      case 0: // Home tab
        controller.fetchAllRestaurantPrograms();
        break;
      case 2: // Rewards tab
        controller.refreshClaimHistory();
        break;
      default:
        break;
    }
  }

  // Method to get the tab at the current index
  Widget _getPage() {
    switch (_currentIndex) {
      case 0:
        return HomeTab(
          controller: controller,
          refreshData: _refreshData,
          showClaimConfirmation: _showClaimConfirmation,
        );
      case 1:
        return const QrCodePage();
      case 2:
        return RewardsTab(controller: controller);
      case 3:
        return const CustomerProfilePage();
      default:
        return HomeTab(
          controller: controller,
          refreshData: _refreshData,
          showClaimConfirmation: _showClaimConfirmation,
        );
    }
  }

  // Get app bar title based on selected tab
  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return '';
      case 1:
        return 'Mon QR Code';
      case 2:
        return 'Your Rewards';
      case 3:
        return 'Mon Profil';
      default:
        return '';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Image.asset('assets/icons/general-u.png', height: 90),
        toolbarHeight: 100,
      ),
      body: _getPage(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 8,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'QR Code',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Récompenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: _changeTab,
      ),
    );
  }

  // Show confirmation dialog before claiming a reward
  void _showClaimConfirmation(dynamic program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Réclamer ${program.rewardType}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir réclamer cette récompense chez ${program.restaurantName}?',
            ),
            const SizedBox(height: 12),
            const Text(
              'Vos points seront remis à zéro après réclamation.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.claimReward(program);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );
  }

  // Set up a permanent worker to listen for tab navigation events
  void _setupTabNavigationListener() {
    ever(AppEvents.navigateToTab, (int tabIndex) {
      if (kDebugMode) {
        print("DEBUG: Tab navigation event received: $tabIndex");
      }

      if (tabIndex >= 0 && tabIndex < 4) {
        _changeTab(tabIndex);
        // Reset the value to prevent repeated navigations
        AppEvents.navigateToTab.value = -1;
      }
    });
  }
}
