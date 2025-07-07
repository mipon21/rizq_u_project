import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../controllers/customer_controller.dart';
import '../../../controllers/customer_navigation_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/app_events.dart';
import 'qr_code_page.dart';
import 'customer_profile_page.dart';
import 'home_tab.dart';
import 'rewards_tab.dart';
import '../../widgets/customer/customer_app_bar.dart';
import '../../widgets/customer/confirmation_dialog.dart';
import '../../../services/contact_service.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> with RouteAware {
  final CustomerController controller = Get.find<CustomerController>();
  final CustomerNavigationController navController = Get.put(CustomerNavigationController());
  final RouteObserver<PageRoute> routeObserver = Get.find<RouteObserver<PageRoute>>();

  @override
  void initState() {
    super.initState();
    _refreshData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialNavigation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    _refreshData();
    _handleNavigationResult();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _handleInitialNavigation() {
    final args = Get.arguments;
    if (args != null && args is Map && args.containsKey('navigateTo')) {
      final tabIndex = args['navigateTo'] as int;
      if (tabIndex >= 0 && tabIndex < 4) {
        navController.changeTab(tabIndex);
      }
    }

    if (AppEvents.navigateToTab.value >= 0 && AppEvents.navigateToTab.value < 4) {
      navController.changeTab(AppEvents.navigateToTab.value);
      AppEvents.navigateToTab.value = -1;
    }
  }

  void _handleNavigationResult() {
    final result = Get.arguments;
    if (result != null && result is Map && result.containsKey('navigateTo')) {
      final tabIndex = result['navigateTo'] as int;
      if (tabIndex >= 0 && tabIndex < 4) {
        navController.changeTab(tabIndex);
      }
    }
  }

  void _refreshData() {
    controller.fetchAllRestaurantPrograms();
    controller.fetchClaimHistory();
    controller.fetchScanHistory();
    controller.fetchCustomerProfile();
  }

  Widget _getPage(int index) {
    switch (index) {
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentIndex = navController.currentIndex;
      
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomerAppBar(
          showHelpMenu: navController.shouldShowHelpMenu(currentIndex),
          title: navController.getTabTitle(currentIndex),
        ),
        body: _getPage(currentIndex),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 8,
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
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
          onTap: navController.changeTab,
        ),
      );
    });
  }

  // Show confirmation dialog before claiming a reward
  void _showClaimConfirmation(dynamic program) {
    ConfirmationDialog.show(
      context: context,
      title: 'Claim ${program.rewardType}',
      content: 'Are you sure you want to claim this reward at ${program.restaurantName}?\n\nYour points will be reset after claiming.',
      confirmText: 'Confirm',
      confirmColor: Colors.purple.shade700,
      confirmTextColor: Colors.white,
      onConfirm: () => controller.claimReward(program),
    );
  }
}
