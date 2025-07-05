import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_events.dart';

class CustomerNavigationController extends GetxController {
  final RxInt _currentIndex = 0.obs;
  
  int get currentIndex => _currentIndex.value;
  
  @override
  void onInit() {
    super.onInit();
    _setupTabNavigationListener();
  }
  
  void changeTab(int index) {
    if (kDebugMode) {
      print("DEBUG: changeTab called with index $index (current: $_currentIndex)");
    }
    
    if (_currentIndex.value != index) {
      _currentIndex.value = index;
      _refreshTabSpecificData(index);
    }
    
    if (kDebugMode) {
      print("DEBUG: Tab changed to $_currentIndex");
    }
  }
  
  void _refreshTabSpecificData(int tabIndex) {
    switch (tabIndex) {
      case 0: // Home tab
        // Trigger home tab refresh
        _triggerHomeTabRefresh();
        break;
      case 2: // Rewards tab
        // Trigger rewards tab refresh
        _triggerRewardsTabRefresh();
        break;
      default:
        break;
    }
  }
  
  void _triggerHomeTabRefresh() {
    // This will be handled by the home tab itself
    if (kDebugMode) {
      print("DEBUG: Triggering home tab refresh");
    }
  }
  
  void _triggerRewardsTabRefresh() {
    // This will be handled by the rewards tab itself
    if (kDebugMode) {
      print("DEBUG: Triggering rewards tab refresh");
    }
  }
  
  void _setupTabNavigationListener() {
    ever(AppEvents.navigateToTab, (int tabIndex) {
      if (kDebugMode) {
        print("DEBUG: Tab navigation event received: $tabIndex");
      }
      
      if (tabIndex >= 0 && tabIndex < 4) {
        changeTab(tabIndex);
        // Reset the value to prevent repeated navigations
        AppEvents.navigateToTab.value = -1;
      }
    });
  }
  
  String getTabTitle(int index) {
    // Return empty string for all tabs to show logo instead of text
    return '';
  }
  
  bool shouldShowHelpMenu(int index) {
    return index == 3; // Only show help menu on profile tab
  }
} 