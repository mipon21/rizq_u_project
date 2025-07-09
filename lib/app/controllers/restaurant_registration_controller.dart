import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/restaurant_registration_model.dart';
import '../routes/app_pages.dart';

class RestaurantRegistrationController extends GetxController {
  static RestaurantRegistrationController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final RxString restaurantName = ''.obs;
  final RxString ownerName = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString countryCode = '+212'.obs; // Default to Morocco
  final RxString postalAddress = ''.obs;
  final RxString supportEmail = ''.obs;
  final RxString bankDetails = ''.obs;
  final RxString ibanNumber = ''.obs;

  // Observable variables for local images
  final Rx<File?> logoFile = Rx<File?>(null);

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isUploadingLogo = false.obs;
  final RxString logoUrl = ''.obs;
  final RxInt currentStep = 0.obs;
  final RxBool isFormValid = false.obs;

  // Registration data
  final Rx<RestaurantRegistrationModel?> registrationData =
      Rx<RestaurantRegistrationModel?>(null);

  @override
  void onInit() {
    super.onInit();
    // Reset form when controller is initialized
    resetForm();
    // Listen to form changes to validate
    ever(restaurantName, (_) => _validateForm());
    ever(ownerName, (_) => _validateForm());
    ever(phoneNumber, (_) => _validateForm());
    ever(countryCode, (_) => _validateForm());
    ever(postalAddress, (_) => _validateForm());
    ever(logoFile, (_) => _validateForm());
  }


  void _validateForm() {
    isFormValid.value = restaurantName.value.trim().isNotEmpty &&
        ownerName.value.trim().isNotEmpty &&
        phoneNumber.value.trim().isNotEmpty &&
        countryCode.value.isNotEmpty &&
        postalAddress.value.trim().isNotEmpty &&
        logoFile.value != null;
  }

  Future<void> pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        logoFile.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick logo: $e');
    }
  }

  Future<String?> _uploadImage(File imageFile, String folder) async {
    try {
      final String fileName =
          '${folder}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child('$folder/$fileName');

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image: $e');
      return null;
    }
  }

  Future<bool> uploadLogo() async {
    try {
      if (logoFile.value != null) {
        final url = await _uploadImage(logoFile.value!, 'restaurant_logos');
        if (url == null) return false;
        logoUrl.value = url;
      }

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload logo: $e');
      return false;
    }
  }

  Future<void> submitRestaurantRegistration() async {
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

      // Upload logo first
      final logoUploaded = await uploadLogo();
      if (!logoUploaded) {
        Get.snackbar('Error', 'Failed to upload logo');
        return;
      }

      // Create registration data
      final registration = RestaurantRegistrationModel(
        uid: user.uid,
        email: user.email ?? '',
        restaurantName: restaurantName.value.trim(),
        ownerName: ownerName.value.trim(),
        phoneNumber: '${countryCode.value}${phoneNumber.value.trim()}',
        postalAddress: postalAddress.value.trim(),
        supportEmail: '',
        bankDetails: '',
        ibanNumber: '',
        logoUrl: logoUrl.value,
        approvalStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('restaurant_registrations')
          .doc(user.uid)
          .set(registration.toFirestore());

      // Update user document to mark as pending restaurant
      await _firestore.collection('users').doc(user.uid).update({
        'role': 'restaurateur',
        'approvalStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create admin notification
      await _createAdminNotification(registration);

      registrationData.value = registration;

      Get.snackbar(
        'Registration Submitted',
        'Your restaurant registration has been submitted for review. You will be notified once approved.',
        duration: const Duration(seconds: 5),
      );

      // Navigate to pending approval screen
      Get.offAllNamed(Routes.RESTAURANT_PENDING_APPROVAL);
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting restaurant registration: $e');
      }
      Get.snackbar('Error', 'Failed to submit registration: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createAdminNotification(
      RestaurantRegistrationModel registration) async {
    try {
      await _firestore.collection('admin_notifications').add({
        'title': 'New Restaurant Registration',
        'message':
            'Restaurant "${registration.restaurantName}" by ${registration.ownerName} is waiting for approval',
        'type': 'restaurant_registration',
        'relatedId': registration.uid,
        'read': false,
        'timestamp': Timestamp.now(),
        'data': {
          'restaurantName': registration.restaurantName,
          'ownerName': registration.ownerName,
          'email': registration.email,
          'phoneNumber': registration.phoneNumber,
          'postalAddress': registration.postalAddress,
        },
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error creating admin notification: $e');
      }
    }
  }

  Future<RestaurantRegistrationModel?> fetchRegistrationData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('restaurant_registrations')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final registration = RestaurantRegistrationModel.fromFirestore(doc);
        registrationData.value = registration;
        return registration;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching registration data: $e');
      }
      return null;
    }
  }

  void nextStep() {
    if (currentStep.value < 1) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  void resetForm() {
    restaurantName.value = '';
    ownerName.value = '';
    phoneNumber.value = '';
    countryCode.value = '+212'; // Reset to Morocco default
    postalAddress.value = '';
    logoUrl.value = '';
    currentStep.value = 0;
  }

  // Clear any previous rejection status when the restaurant registration page is loaded
  Future<void> clearRejectionStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if this user has a rejected registration
      final doc = await _firestore
          .collection('restaurant_registrations')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['approvalStatus'] == 'rejected') {
        if (kDebugMode) {
          print(
              'Clearing previous rejection status for restaurant: ${user.uid}');
        }

        // Reset the form
        resetForm();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing rejection status: $e');
      }
    }
  }
}

