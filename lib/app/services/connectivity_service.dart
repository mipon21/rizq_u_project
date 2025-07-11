import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends GetxService {
  static ConnectivityService get instance => Get.find();
  
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _setupConnectivityListener();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      // Default to connected if we can't determine status
      isConnected.value = true;
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
      onError: (error) {
        if (kDebugMode) {
          print('Connectivity listener error: $error');
        }
      },
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = isConnected.value;
    // Check if any of the results indicate connectivity
    final hasConnection = results.any((result) => result != ConnectivityResult.none);
    isConnected.value = hasConnection;
    
    if (kDebugMode) {
      print('Connectivity changed: $results, isConnected: ${isConnected.value}');
    }

    // Show notification when connection is lost
    if (wasConnected && !isConnected.value) {
      _showNoInternetNotification();
    }
  }

  void _showNoInternetNotification() {
    Get.snackbar(
      'No Internet Connection',
      'Please check your internet connection and try again.',
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.red.shade50,
      colorText: Colors.red.shade900,
      snackPosition: SnackPosition.TOP,
      dismissDirection: DismissDirection.vertical,
      isDismissible: true,
      icon: const Icon(Icons.wifi_off, color: Colors.red),
    );
  }

  // Method to manually check connectivity
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final connected = results.any((result) => result != ConnectivityResult.none);
      isConnected.value = connected;
      return connected;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      return false;
    }
  }

  // Get current connection status
  bool get hasInternetConnection => isConnected.value;
} 