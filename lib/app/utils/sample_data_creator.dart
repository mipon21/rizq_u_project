import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_plan_model.dart';

class SampleDataCreator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create sample subscription plans for testing
  static Future<void> createSampleSubscriptionPlans() async {
    try {
      final samplePlans = [
        SubscriptionPlanModel(
          id: '',
          name: 'Starter Plan',
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
        ),
        SubscriptionPlanModel(
          id: '',
          name: 'Business Plan',
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
            'Priority phone & email support',
            'Custom branding & white-labeling',
            'API access for integrations',
            'Dedicated account manager',
            'Multi-location support'
          ],
        ),
        SubscriptionPlanModel(
          id: '',
          name: 'Weekly Trial',
          description: 'Short-term trial for new users',
          scanLimit: 50,
          durationDays: 7,
          price: 29.99,
          currency: 'MAD',
          isActive: true,
          createdAt: DateTime.now(),
          features: [
            'Up to 50 customer scans',
            'Basic analytics',
            'Email support',
            'Perfect for testing'
          ],
        ),
      ];

      for (final plan in samplePlans) {
        await _firestore
            .collection('custom_subscription_plans')
            .add(plan.toFirestore());
      }

      print('Sample subscription plans created successfully!');
    } catch (e) {
      print('Error creating sample subscription plans: $e');
    }
  }

  // Clear all custom subscription plans (for testing)
  static Future<void> clearAllCustomPlans() async {
    try {
      final snapshot = await _firestore
          .collection('custom_subscription_plans')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('All custom subscription plans cleared!');
    } catch (e) {
      print('Error clearing custom subscription plans: $e');
    }
  }
} 