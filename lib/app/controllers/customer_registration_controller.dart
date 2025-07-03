import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/customer_registration_model.dart';
import '../routes/app_pages.dart';

class CustomerRegistrationController extends GetxController {
  static CustomerRegistrationController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final RxString firstName = ''.obs;
  final RxString lastName = ''.obs;
  final Rx<DateTime?> dateOfBirth = Rx<DateTime?>(null);

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isFormValid = false.obs;

  // Registration data
  final Rx<CustomerRegistrationModel?> registrationData =
      Rx<CustomerRegistrationModel?>(null);

  @override
  void onInit() {
    super.onInit();
    // Listen to form changes to validate
    ever(firstName, (_) => _validateForm());
    ever(lastName, (_) => _validateForm());
    ever(dateOfBirth, (_) => _validateForm());
  }

  @override
  void onClose() {
    super.onClose();
  }

  void _validateForm() {
    isFormValid.value = firstName.value.trim().isNotEmpty &&
        lastName.value.trim().isNotEmpty &&
        dateOfBirth.value != null;
  }

  Future<void> submitCustomerRegistration() async {
    if (!isFormValid.value) {
      Get.snackbar('Error', 'Please fill all required fields');
      return;
    }

    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      // Create registration data
      final registration = CustomerRegistrationModel(
        uid: user.uid,
        email: user.email ?? '',
        firstName: firstName.value.trim(),
        lastName: lastName.value.trim(),
        dateOfBirth: dateOfBirth.value!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore - directly to the users collection
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': registration.fullName,
        'firstName': registration.firstName,
        'lastName': registration.lastName,
        'dateOfBirth': registration.dateOfBirth,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'registrationComplete': true,
      }, SetOptions(merge: true));

      // Update Firebase Auth display name
      await user.updateDisplayName(registration.fullName);

      registrationData.value = registration;

      Get.snackbar(
        'Registration Complete',
        'Welcome to Rizq! Your account has been created successfully.',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );

      // Navigate to customer home
      Get.offAllNamed(Routes.CUSTOMER_HOME);
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting customer registration: $e');
      }
      Get.snackbar('Error', 'Failed to complete registration: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<CustomerRegistrationModel?> fetchRegistrationData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (data['registrationComplete'] == true) {
          final registration = CustomerRegistrationModel(
            uid: user.uid,
            email: data['email'] ?? '',
            firstName: data['firstName'] ?? '',
            lastName: data['lastName'] ?? '',
            dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
          registrationData.value = registration;
          return registration;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching registration data: $e');
      }
      return null;
    }
  }

  void resetForm() {
    firstName.value = '';
    lastName.value = '';
    dateOfBirth.value = null;
  }
} 