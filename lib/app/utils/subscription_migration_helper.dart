import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_plan_model.dart';

class SubscriptionMigrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates default subscription plans to replace the hardcoded system
  static Future<void> createDefaultPlans() async {
    try {
      final defaultPlans = [
        SubscriptionPlanModel(
          id: '',
          name: 'Free Trial',
          description: 'Free trial period for new restaurants',
          scanLimit: 100,
          durationDays: 30,
          price: 0.0,
          currency: 'MAD',
          isActive: true,
          createdAt: DateTime.now(),
          features: [
            'Up to 100 customer scans',
            'Basic analytics',
            'Email support',
            'Perfect for testing the platform'
          ],
          planType: 'free_trial',
        ),
        SubscriptionPlanModel(
          id: '',
          name: 'Basic Plan',
          description: 'Perfect for small cafes and restaurants',
          scanLimit: 100,
          durationDays: 30,
          price: 99.99,
          currency: 'MAD',
          isActive: true,
          createdAt: DateTime.now(),
          features: [
            'Up to 100 customer scans',
            'Basic analytics dashboard',
            'Email support',
            'QR code generation',
            'Customer loyalty tracking'
          ],
          planType: 'regular',
        ),
        SubscriptionPlanModel(
          id: '',
          name: 'Standard Plan',
          description: 'Ideal for growing restaurants',
          scanLimit: 250,
          durationDays: 30,
          price: 199.99,
          currency: 'MAD',
          isActive: true,
          createdAt: DateTime.now(),
          features: [
            'Up to 250 customer scans',
            'Advanced analytics & reporting',
            'Priority email support',
            'Custom branding options',
            'Detailed customer insights',
            'Export data to CSV'
          ],
          planType: 'regular',
        ),
        SubscriptionPlanModel(
          id: '',
          name: 'Premium Plan',
          description: 'For large restaurant chains',
          scanLimit: -1, // Unlimited
          durationDays: 30,
          price: 299.99,
          currency: 'MAD',
          isActive: true,
          createdAt: DateTime.now(),
          features: [
            'Unlimited customer scans',
            'Advanced analytics & reporting',
            'Priority email support',
            'Custom branding & white-labeling',
            'API access for integrations',
            'Dedicated account manager',
            'Multi-location support'
          ],
          planType: 'regular',
        ),
      ];

      for (final plan in defaultPlans) {
        await _firestore
            .collection('custom_subscription_plans')
            .add(plan.toFirestore());
      }

      print('Default subscription plans created successfully!');
    } catch (e) {
      print('Error creating default plans: $e');
    }
  }

  /// Migrates restaurants from hardcoded plans to custom plans
  static Future<void> migrateRestaurantsToCustomPlans() async {
    try {
      // Get all restaurants
      final restaurantsSnapshot =
          await _firestore.collection('restaurants').get();

      // Get custom plans for mapping
      final plansSnapshot =
          await _firestore.collection('custom_subscription_plans').get();

      final plans = <String, String>{}; // old plan ID -> new plan ID
      String? freeTrialPlanId;

      for (var doc in plansSnapshot.docs) {
        final plan = SubscriptionPlanModel.fromFirestore(doc);
        
        // Store free trial plan ID
        if (plan.isFreeTrial) {
          freeTrialPlanId = plan.id;
        }
        
        // Map old plan IDs to new plan IDs
        if (plan.name == 'Basic Plan') {
          plans['plan_100'] = plan.id;
        } else if (plan.name == 'Standard Plan') {
          plans['plan_250'] = plan.id;
        } else if (plan.name == 'Premium Plan') {
          plans['plan_unlimited'] = plan.id;
        }
      }

      int migratedCount = 0;

      for (var doc in restaurantsSnapshot.docs) {
        final data = doc.data();
        final currentPlan = data['subscriptionPlan'] as String?;

        // Handle free trial migration
        if (currentPlan == 'free_trial' && freeTrialPlanId != null) {
          await _firestore.collection('restaurants').doc(doc.id).update({
            'subscriptionPlan': freeTrialPlanId,
            'updatedAt': Timestamp.now(),
          });
          migratedCount++;
          continue;
        }

        // Handle other plan migrations
        if (currentPlan != null &&
            (currentPlan == 'plan_100' ||
                currentPlan == 'plan_250' ||
                currentPlan == 'plan_unlimited')) {
          final newPlanId = plans[currentPlan];
          if (newPlanId != null) {
            await _firestore.collection('restaurants').doc(doc.id).update({
              'subscriptionPlan': newPlanId,
              'updatedAt': Timestamp.now(),
            });
            migratedCount++;
          }
        }
      }

      print(
          'Successfully migrated $migratedCount restaurants to custom plans!');
    } catch (e) {
      print('Error migrating restaurants: $e');
    }
  }

  /// Cleans up old subscription_plans collection
  static Future<void> cleanupLegacySubscriptionPlans() async {
    try {
      await _firestore.collection('subscription_plans').doc('default').delete();
      print('Legacy subscription_plans collection cleaned up successfully!');
    } catch (e) {
      print('Error cleaning up legacy subscription plans: $e');
    }
  }

  /// Full migration process
  static Future<void> performFullMigration() async {
    print('Starting subscription system migration...');

    // Step 1: Create default plans
    await createDefaultPlans();

    // Step 2: Migrate restaurants
    await migrateRestaurantsToCustomPlans();

    // Step 3: Clean up legacy data
    await cleanupLegacySubscriptionPlans();

    print('Migration completed successfully!');
  }
}
