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
  final RxString supportEmail = ''.obs;
  final RxString bankDetails = ''.obs;
  final RxString ibanNumber = ''.obs;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isUploadingLogo = false.obs;
  final RxBool isUploadingIdFront = false.obs;
  final RxBool isUploadingIdBack = false.obs;
  final RxString logoUrl = ''.obs;
  final RxString nationalIdFrontUrl = ''.obs;
  final RxString nationalIdBackUrl = ''.obs;
  final RxInt currentStep = 0.obs;
  final RxBool isFormValid = false.obs;

  // Registration data
  final Rx<RestaurantRegistrationModel?> registrationData =
      Rx<RestaurantRegistrationModel?>(null);

  @override
  void onInit() {
    super.onInit();
    // Listen to form changes to validate
    ever(restaurantName, (_) => _validateForm());
    ever(ownerName, (_) => _validateForm());
    ever(supportEmail, (_) => _validateForm());
    ever(bankDetails, (_) => _validateForm());
    ever(ibanNumber, (_) => _validateForm());
    ever(logoUrl, (_) => _validateForm());
    ever(nationalIdFrontUrl, (_) => _validateForm());
    ever(nationalIdBackUrl, (_) => _validateForm());
  }

  @override
  void onClose() {
    super.onClose();
  }

  void _validateForm() {
    isFormValid.value = restaurantName.value.trim().isNotEmpty &&
        ownerName.value.trim().isNotEmpty &&
        supportEmail.value.trim().isNotEmpty &&
        bankDetails.value.trim().isNotEmpty &&
        ibanNumber.value.trim().isNotEmpty &&
        logoUrl.value.isNotEmpty &&
        nationalIdFrontUrl.value.isNotEmpty &&
        nationalIdBackUrl.value.isNotEmpty;
  }

  Future<void> pickAndUploadLogo() async {
    try {
      isUploadingLogo.value = true;
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final String fileName =
            'restaurant_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef =
            _storage.ref().child('restaurant_logos/$fileName');

        final UploadTask uploadTask = storageRef.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        logoUrl.value = downloadUrl;
        Get.snackbar('Success', 'Logo uploaded successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload logo: $e');
    } finally {
      isUploadingLogo.value = false;
    }
  }

  Future<void> pickAndUploadNationalIdFront() async {
    try {
      isUploadingIdFront.value = true;
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final String fileName =
            'national_id_front_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef =
            _storage.ref().child('national_ids/$fileName');

        final UploadTask uploadTask = storageRef.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        nationalIdFrontUrl.value = downloadUrl;
        Get.snackbar('Success', 'National ID front uploaded successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload National ID front: $e');
    } finally {
      isUploadingIdFront.value = false;
    }
  }

  Future<void> pickAndUploadNationalIdBack() async {
    try {
      isUploadingIdBack.value = true;
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final String fileName =
            'national_id_back_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef =
            _storage.ref().child('national_ids/$fileName');

        final UploadTask uploadTask = storageRef.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        nationalIdBackUrl.value = downloadUrl;
        Get.snackbar('Success', 'National ID back uploaded successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload National ID back: $e');
    } finally {
      isUploadingIdBack.value = false;
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

      // Create registration data
      final registration = RestaurantRegistrationModel(
        uid: user.uid,
        email: user.email ?? '',
        restaurantName: restaurantName.value.trim(),
        ownerName: ownerName.value.trim(),
        ownerNationalIdFront: nationalIdFrontUrl.value,
        ownerNationalIdBack: nationalIdBackUrl.value,
        supportEmail: supportEmail.value.trim(),
        bankDetails: bankDetails.value.trim(),
        ibanNumber: ibanNumber.value.trim(),
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
          'supportEmail': registration.supportEmail,
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
    if (currentStep.value < 3) {
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
    supportEmail.value = '';
    bankDetails.value = '';
    ibanNumber.value = '';
    logoUrl.value = '';
    nationalIdFrontUrl.value = '';
    nationalIdBackUrl.value = '';
    currentStep.value = 0;
  }
}
