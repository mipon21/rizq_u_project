import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:rizq/app/routes/app_pages.dart'; // Adjust import path if needed
import 'package:flutter/foundation.dart'; // For kDebugMode
import '../utils/snackbar_utils.dart'; // Import snackbar utilities

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
      // If user is logged in, check email verification first
      if (kDebugMode) {
        print('User is logged in (${user.uid}). Checking email verification...');
      }
      
      // Refresh user data to get latest email verification status
      await user.reload();
      user = _auth.currentUser;
      
      if (user != null && !user.emailVerified) {
        // If email is not verified, redirect to email verification page
        if (kDebugMode) {
          print('Email not verified. Navigating to Email Verification.');
        }
        Get.offAllNamed(Routes.EMAIL_VERIFICATION);
      } else {
        // If email is verified, check if user document exists in Firestore
        if (kDebugMode) {
          print('Email verified. Checking user document...');
        }
        
        try {
          final docSnapshot = await _firestore.collection('users').doc(user!.uid).get();
          
          if (!docSnapshot.exists) {
            // User doesn't exist in Firestore yet, create the document
            if (kDebugMode) {
              print('User document not found. Creating user document...');
            }
            await _createUserDocument(user);
          }
          
          // Fetch user role and navigate accordingly
          await _fetchUserRole(user.uid);
          _navigateBasedOnRole();
        } catch (e) {
          if (kDebugMode) {
            print('Error checking/creating user document: $e');
          }
          // If there's an error, redirect to email verification to try again
          Get.offAllNamed(Routes.EMAIL_VERIFICATION);
        }
      }
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
  void _navigateBasedOnRole() async {
    if (userRole.value == 'customer') {
      if (kDebugMode) {
        print('Navigating to Customer Home.');
      }
      Get.offAllNamed(Routes.CUSTOMER_HOME);
    } else if (userRole.value == 'restaurateur') {
      // Check if restaurant needs approval
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(_firebaseUser.value!.uid)
            .get();
        final approvalStatus = userDoc.data()?['approvalStatus'] ?? 'pending';

        if (approvalStatus == 'pending') {
          // Check if registration data exists
          final registrationDoc = await _firestore
              .collection('restaurant_registrations')
              .doc(_firebaseUser.value!.uid)
              .get();

          if (registrationDoc.exists) {
            final registrationData = registrationDoc.data()!;
            final registrationStatus =
                registrationData['approvalStatus'] ?? 'pending';

            if (registrationStatus == 'pending') {
              if (kDebugMode) {
                print(
                    'Restaurant pending approval, navigating to pending approval page.');
              }
              Get.offAllNamed(Routes.RESTAURANT_PENDING_APPROVAL);
              return;
            } else if (registrationStatus == 'rejected') {
              if (kDebugMode) {
                print(
                    'Restaurant rejected, navigating to pending approval page.');
              }
              Get.offAllNamed(Routes.RESTAURANT_PENDING_APPROVAL);
              return;
            } else if (registrationStatus == 'approved') {
              // Update user document to reflect approval
              await _firestore
                  .collection('users')
                  .doc(_firebaseUser.value!.uid)
                  .update({
                'approvalStatus': 'approved',
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          } else {
            // No registration data, redirect to registration
            if (kDebugMode) {
              print(
                  'No registration data found, navigating to restaurant registration.');
            }
            Get.offAllNamed(Routes.RESTAURANT_REGISTRATION);
            return;
          }
        } else if (approvalStatus == 'rejected') {
          if (kDebugMode) {
            print('Restaurant rejected, navigating to pending approval page.');
          }
          Get.offAllNamed(Routes.RESTAURANT_PENDING_APPROVAL);
          return;
        }

        // If approved or no approval status needed, go to dashboard
        if (kDebugMode) {
          print('Navigating to Restaurant Dashboard.');
        }
        Get.offAllNamed(Routes.RESTAURANT_DASHBOARD);
      } catch (e) {
        if (kDebugMode) {
          print('Error checking restaurant approval status: $e');
        }
        // Fallback to dashboard
        Get.offAllNamed(Routes.RESTAURANT_DASHBOARD);
      }
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
      // Get.offAllNamed(Routes.LOGIN);
    }
  }

  // --- Authentication Methods ---

  Future<void> register(String email, String password, String role) async {
    try {
      isLoading.value = true;
      // Normalize role: treat 'restaurant' as 'restaurateur'
      String normalizedRole = role;
      if (role == 'restaurant') {
        normalizedRole = 'restaurateur';
      }
      // Validate role
      if (normalizedRole != 'customer' && normalizedRole != 'restaurateur') {
        throw Exception('Invalid role specified.');
      }

      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;

      if (user != null) {
        // Send email verification immediately
        await user.sendEmailVerification();
        
        // Store role temporarily for later use
        userRole.value = normalizedRole;
        
        if (kDebugMode) {
          print('Firebase Auth user created for ${user.email}, role: $normalizedRole');
          print('Email verification sent to ${user.email}');
        }
        
        // Show success message
        SnackbarUtils.showSuccess(
          'Verification Email Sent',
          'Please check your email and click the verification link to complete registration.',
        );
        
        // Navigate to email verification page
        Get.offAllNamed(Routes.EMAIL_VERIFICATION);
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
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password,
      );
      
      // Check if email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        if (kDebugMode) {
          print('Login successful but email not verified for $email.');
        }
        
        SnackbarUtils.showError(
          'Please complete your registration by verifying your email.',
        );
        
        // Navigation to email verification will be handled by _setInitialScreen
      } else {
        if (kDebugMode) {
          print('Login successful for $email.');
        }
      }
      
      // Navigation is handled by the _setInitialScreen listener
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
      if (kDebugMode) {
        print('Sending password reset email to: $email');
      }
      
      await _auth.sendPasswordResetEmail(email: email);
      
      if (kDebugMode) {
        print('Password reset email sent successfully to: $email');
      }
      
      // Show success message with better styling
      SnackbarUtils.showSuccess(
        'Password Reset Email Sent', 
        'Please check your email at $email for reset instructions.'
      );
      
      // Wait a moment before navigating back to ensure snackbar is visible
      await Future.delayed(const Duration(milliseconds: 1500));
      Get.back(); // Close the forgot password dialog/page
      
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('FirebaseAuthException in forgotPassword: ${e.code} - ${e.message}');
      }
      SnackbarUtils.showError(
        e.message ?? 'An unknown error occurred while sending reset email.',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error in forgotPassword: $e');
      }
      SnackbarUtils.showError('An unexpected error occurred while sending reset email.');
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

  // Check if email is verified and proceed accordingly
  Future<void> checkEmailVerification() async {
    try {
      isLoading.value = true;
      User? user = _auth.currentUser;
      
      if (user != null) {
        // Reload user to get latest email verification status
        await user.reload();
        user = _auth.currentUser;
        
        if (user != null && user.emailVerified) {
          if (kDebugMode) {
            print('Email verified! Creating user account...');
          }
          
          // Now create the user document in Firestore
          await _createUserDocument(user);
          
          SnackbarUtils.showSuccess(
            'Email Verified!',
            'Your account has been created successfully.',
          );
          
          // Fetch user role and navigate
          await _fetchUserRole(user.uid);
          _navigateBasedOnRole();
        } else {
          if (kDebugMode) {
            print('Email not yet verified.');
          }
          
          SnackbarUtils.showError(
            'Email not verified yet. Please check your email and click the verification link.',
          );
        }
      } else {
        throw Exception('No user is currently signed in.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking email verification: $e');
      }
      SnackbarUtils.showError(
        'An error occurred while checking email verification.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      isLoading.value = true;
      User? user = _auth.currentUser;
      
      if (user != null) {
        await user.sendEmailVerification();
        
        if (kDebugMode) {
          print('Email verification resent to ${user.email}');
        }
        
        SnackbarUtils.showSuccess(
          'Verification Email Sent',
          'A new verification email has been sent to ${user.email}',
        );
      } else {
        throw Exception('No user is currently signed in.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        SnackbarUtils.showError(
          'Too many requests. Please wait a moment before requesting another verification email.',
        );
      } else {
        SnackbarUtils.showError(
          e.message ?? 'An error occurred while sending verification email.',
        );
      }
      
      if (kDebugMode) {
        print('FirebaseAuthException in resendEmailVerification: ${e.code} - ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resending email verification: $e');
      }
      SnackbarUtils.showError(
        'An error occurred while sending verification email.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Create user document in Firestore after email verification
  Future<void> _createUserDocument(User user) async {
    try {
      String normalizedRole = userRole.value;
      
      // Clean string function to remove extra backslashes
      String cleanString(String input) {
        return input.replaceAll(RegExp(r'\\+'), '');
      }

      await _firestore.collection('users').doc(user.uid).set({
        'uid': cleanString(user.uid),
        'email': cleanString(user.email ?? ''),
        'role': cleanString(normalizedRole),
        'createdAt': FieldValue.serverTimestamp(),
        // Initialize points map for customers
        if (normalizedRole == 'customer') 'pointsByRestaurant': {},
        // Add approval status for restaurants
        if (normalizedRole == 'restaurateur') 'approvalStatus': 'pending',
      });

      if (kDebugMode) {
        print('User document created in Firestore for ${user.email}, role: $normalizedRole');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user document: $e');
      }
      throw Exception('Failed to create user account. Please try again.');
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
