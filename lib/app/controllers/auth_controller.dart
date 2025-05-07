import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:rizq/app/routes/app_pages.dart'; // Adjust import path if needed
import 'package:flutter/foundation.dart'; // For kDebugMode

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables for authentication state and user role
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final RxString userRole = ''.obs; // 'customer' or 'restaurateur'
  final RxBool isLoading = false.obs;

  // --- Public Getters ---

  // Getter to expose the user safely (non-reactive)
  User? get currentUser => _firebaseUser.value;
  String get currentUserUid {
    final uid = _firebaseUser.value?.uid ?? '';
    return uid.replaceAll(RegExp(r'\\+'), '');
  }

  // Getter to expose the reactive Rx<User?> object itself
  // This allows other controllers/widgets to listen using ever() or Obx()
  Rx<User?> get reactiveFirebaseUser => _firebaseUser;

  @override
  void onReady() {
    // Bind the Firebase user stream to our Rx variable
    _firebaseUser.bindStream(_auth.authStateChanges());
    // Automatically handle navigation when auth state changes
    ever(_firebaseUser, _setInitialScreen);
    super.onReady();
  }

  // Determines the initial screen based on auth state and role
  void _setInitialScreen(User? user) async {
    if (user == null) {
      // If user is logged out, go to Login page
      if (kDebugMode) {
        print('User is logged out. Navigating to Login.');
      }
      Get.offAllNamed(Routes.LOGIN);
    } else {
      // If user is logged in, fetch role and navigate accordingly
      if (kDebugMode) {
        print('User is logged in (${user.uid}). Fetching role...');
      }
      await _fetchUserRole(user.uid);
      _navigateBasedOnRole();
    }
  }

  // Fetches the user's role from Firestore
  Future<void> _fetchUserRole(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data()!.containsKey('role')) {
        userRole.value = docSnapshot.data()!['role'];
        if (kDebugMode) {
          print('User role fetched: ${userRole.value}');
        }
      } else {
        if (kDebugMode) {
          print('User document or role not found for UID: $uid');
        }
        // Handle cases where user exists in Auth but not Firestore or role is missing
        userRole.value = ''; // Reset role if not found
        // Maybe log out or show an error? For now, default navigation might handle it.
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user role: $e');
      }
      Get.snackbar('Error', 'Could not fetch user details. Please try again.');
      userRole.value = ''; // Reset on error
    }
  }

  // Navigates user based on their role
  void _navigateBasedOnRole() {
    if (userRole.value == 'customer') {
      if (kDebugMode) {
        print('Navigating to Customer Home.');
      }
      Get.offAllNamed(Routes.CUSTOMER_HOME);
    } else if (userRole.value == 'restaurateur') {
      if (kDebugMode) {
        print('Navigating to Restaurant Dashboard.');
      }
      Get.offAllNamed(Routes.RESTAURANT_DASHBOARD);
    } else if (userRole.value == 'admin') {
      print('Admin role detected, navigating to admin dashboard');
      Get.offAllNamed(Routes.ADMIN_DASHBOARD);
    } else {
      // If role is unknown or invalid after login, default to login screen
      if (kDebugMode) {
        print('Unknown role or navigation error. Defaulting to Login.');
      }
      // Avoid infinite loop if _setInitialScreen keeps getting called
      // Only navigate if we aren't already on the login page?
      // Or potentially log out the user.
      // For simplicity now, we assume fetchUserRole handles errors.
      // If fetch failed and role is empty, _setInitialScreen might redirect here.
      // Consider adding logic to prevent loops if role fetch consistently fails.
      // Get.offAllNamed(Routes.LOGIN);
    }
  }

  // --- Authentication Methods ---

  Future<void> register(String email, String password, String role) async {
    try {
      isLoading.value = true;
      // Validate role
      if (role != 'customer' && role != 'restaurateur') {
        throw Exception('Invalid role specified.');
      }

      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;

      if (user != null) {
        // Create user document in Firestore with clean data
        String cleanString(String input) {
          return input.replaceAll(RegExp(r'\\+'), '');
        }

        await _firestore.collection('users').doc(user.uid).set({
          'uid': cleanString(user.uid),
          'email': cleanString(email),
          'role': cleanString(role),
          'createdAt': FieldValue.serverTimestamp(),
          // Initialize points map for customers
          if (role == 'customer') 'pointsByRestaurant': {},
        });

        // Create restaurant document if restaurateur
        if (role == 'restaurateur') {
          await _firestore.collection('restaurants').doc(user.uid).set({
            'uid': cleanString(user.uid), // Link to auth UID
            'name': '', // To be set up later
            'address': '',
            'logoUrl': '',
            'subscriptionPlan': 'free_trial', // Default plan
            'subscriptionStatus': 'free_trial', // Initial status
            'currentScanCount': 0,
            'trialStartDate': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          // Also create an initial program document
          await _firestore.collection('programs').doc(user.uid).set({
            'restaurantId': user.uid,
            'rewardType': 'Free Drink', // Default reward
            'pointsRequired': 10, // Standard 10 points
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Update local role and let the listener handle navigation
        userRole.value = role;
        // No need to navigate manually, _setInitialScreen handles it via the stream
        if (kDebugMode) {
          print('Registration successful for ${user.email}, role: $role');
        }
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Registration Failed',
        e.message ?? 'An unknown error occurred.',
      );
      if (kDebugMode) {
        print(
          'FirebaseAuthException during registration: ${e.code} - ${e.message}',
        );
      }
    } catch (e) {
      Get.snackbar('Registration Failed', 'An unexpected error occurred.');
      if (kDebugMode) {
        print('Unexpected error during registration: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Navigation is handled by the _setInitialScreen listener
      if (kDebugMode) {
        print('Login successful for $email.');
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Login Failed', e.message ?? 'An unknown error occurred.');
      if (kDebugMode) {
        print('FirebaseAuthException during login: ${e.code} - ${e.message}');
      }
    } catch (e) {
      Get.snackbar('Login Failed', 'An unexpected error occurred.');
      if (kDebugMode) {
        print('Unexpected error during login: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Password Reset', 'Password reset email sent to $email.');
      Get.back(); // Close the forgot password dialog/page
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Password Reset Failed',
        e.message ?? 'An unknown error occurred.',
      );
    } catch (e) {
      Get.snackbar('Password Reset Failed', 'An unexpected error occurred.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _auth.signOut();
      userRole.value = ''; // Clear role on logout
      // Navigation is handled by the _setInitialScreen listener
      if (kDebugMode) {
        print('User logged out.');
      }
    } catch (e) {
      Get.snackbar('Logout Failed', 'An error occurred during logout.');
      if (kDebugMode) {
        print('Error during logout: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Delete user account and related data
  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      User? user = _auth.currentUser;

      if (user != null) {
        String uid = user.uid;

        // First delete all related data from Firestore based on user role
        if (userRole.value == 'customer') {
          // Delete customer-specific collections and documents
          await _firestore.collection('users').doc(uid).delete();

          // Delete any customer-specific subcollections if they exist
          // e.g., claimed rewards, scan history, etc.
          final scanHistoryRef = _firestore
              .collection('scanHistory')
              .where('customerId', isEqualTo: uid);
          final scanHistoryDocs = await scanHistoryRef.get();

          for (var doc in scanHistoryDocs.docs) {
            await doc.reference.delete();
          }

          final claimHistoryRef = _firestore
              .collection('claimHistory')
              .where('customerId', isEqualTo: uid);
          final claimHistoryDocs = await claimHistoryRef.get();

          for (var doc in claimHistoryDocs.docs) {
            await doc.reference.delete();
          }
        } else if (userRole.value == 'restaurateur') {
          // Delete restaurant-specific collections and documents
          await _firestore.collection('users').doc(uid).delete();
          await _firestore.collection('restaurants').doc(uid).delete();
          await _firestore.collection('programs').doc(uid).delete();

          // Delete related QR codes or other data
          final qrCodesRef = _firestore
              .collection('qrCodes')
              .where('restaurantId', isEqualTo: uid);
          final qrCodeDocs = await qrCodesRef.get();

          for (var doc in qrCodeDocs.docs) {
            await doc.reference.delete();
          }
        }

        // Finally delete the user account from Firebase Auth
        await user.delete();

        // Clear role on account deletion
        userRole.value = '';

        if (kDebugMode) {
          print('Account deleted successfully.');
        }

        Get.offAllNamed(Routes.LOGIN);
      } else {
        throw Exception('No user is currently signed in.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        Get.snackbar(
          'Re-authentication Required',
          'Please log out and log in again before deleting your account.',
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Account Deletion Failed',
          e.message ?? 'An unknown error occurred.',
        );
      }

      if (kDebugMode) {
        print(
            'FirebaseAuthException during account deletion: ${e.code} - ${e.message}');
      }
    } catch (e) {
      Get.snackbar('Account Deletion Failed', 'An unexpected error occurred.');
      if (kDebugMode) {
        print('Unexpected error during account deletion: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }
}
