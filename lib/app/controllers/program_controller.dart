    import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rizq/app/controllers/auth_controller.dart'; // For kDebugMode


    class LoyaltyProgramModel {
      final String restaurantId;
      final String rewardType; // e.g., "Free Coffee", "Discount", "Meal"
      final int pointsRequired;

       LoyaltyProgramModel({
         required this.restaurantId,
         required this.rewardType,
         required this.pointsRequired,
       });

        factory LoyaltyProgramModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
          final data = snapshot.data()!;
          return LoyaltyProgramModel(
            restaurantId: data['restaurantId'] ?? snapshot.id,
            rewardType: data['rewardType'] ?? 'Free Item', // Default value
            pointsRequired: data['pointsRequired'] ?? 10, // Default value
          );
        }
    }

    class ProgramController extends GetxController {
      static ProgramController get instance => Get.find();
      final AuthController _authController = Get.find();
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      final RxBool isLoading = false.obs;
      final Rx<LoyaltyProgramModel?> loyaltyProgram = Rx<LoyaltyProgramModel?>(null);

      String get restaurantUid => _authController.currentUserUid;

       // Reactive getters for UI
       String get currentRewardType => loyaltyProgram.value?.rewardType ?? 'Not Set';
       int get currentPointsRequired => loyaltyProgram.value?.pointsRequired ?? 10;

      @override
      void onInit() {
        super.onInit();
        if (restaurantUid.isNotEmpty) {
          fetchLoyaltyProgram();
        }
         // Re-fetch if user changes
         ever(_authController.reactiveFirebaseUser, (_) {
           if (restaurantUid.isNotEmpty) {
             fetchLoyaltyProgram();
           } else {
             loyaltyProgram.value = null; // Clear on logout
           }
         });
      }

      Future<void> fetchLoyaltyProgram() async {
         if (restaurantUid.isEmpty) return;
        isLoading.value = true;
        try {
          final doc = await _firestore.collection('programs').doc(restaurantUid).get();
          if (doc.exists) {
            loyaltyProgram.value = LoyaltyProgramModel.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
             if (kDebugMode) {
               print("Fetched program for $restaurantUid: ${loyaltyProgram.value?.rewardType} requires ${loyaltyProgram.value?.pointsRequired} points.");
             }
          } else {
             loyaltyProgram.value = null; // No program configured yet
             if (kDebugMode) {
               print("Loyalty program document not found for restaurant $restaurantUid.");
               // Consider creating a default one here if desired
             }
          }
        } catch (e) {
          Get.snackbar('Error', 'Failed to load loyalty program: $e');
           if (kDebugMode) {
             print("Error fetching program for $restaurantUid: $e");
           }
        } finally {
          isLoading.value = false;
        }
      }

      Future<void> updateLoyaltyProgram(String newRewardType, int newPointsRequired) async {
         if (restaurantUid.isEmpty) return;
         isLoading.value = true;
         try {
            // Validate inputs (basic)
           if (newRewardType.isEmpty || newPointsRequired <= 0) {
              Get.snackbar('Invalid Input', 'Reward type cannot be empty and points must be positive.');
              return;
           }

           await _firestore.collection('programs').doc(restaurantUid).set({ // Use set with merge:true or update
             'restaurantId': restaurantUid, // Ensure this is set
             'rewardType': newRewardType,
             'pointsRequired': newPointsRequired,
             'updatedAt': FieldValue.serverTimestamp(),
           }, SetOptions(merge: true)); // merge: true ensures we don't overwrite other fields if they exist

           // Update local state
           loyaltyProgram.value = LoyaltyProgramModel(
              restaurantId: restaurantUid,
              rewardType: newRewardType,
              pointsRequired: newPointsRequired,
            );
            loyaltyProgram.refresh(); // Notify listeners

           Get.snackbar('Success', 'Loyalty program updated.');
            if (kDebugMode) {
              print("Updated program for $restaurantUid: $newRewardType, $newPointsRequired points.");
            }
         } catch (e) {
            Get.snackbar('Error', 'Failed to update program: $e');
             if (kDebugMode) {
               print("Error updating program for $restaurantUid: $e");
             }
         } finally {
            isLoading.value = false;
         }
      }
    }
