import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlanModel {
  final String id;
  final String name;
  final String description;
  final int scanLimit;
  final int durationDays;
  final double price;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> features;
  final String planType; // 'regular' or 'free_trial'

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.scanLimit,
    required this.durationDays,
    required this.price,
    this.currency = 'MAD',
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    required this.features,
    this.planType = 'regular',
  });

  factory SubscriptionPlanModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return SubscriptionPlanModel(
      id: snapshot.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      scanLimit: data['scanLimit'] ?? 0,
      durationDays: data['durationDays'] ?? 30,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'MAD',
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      features: List<String>.from(data['features'] ?? []),
      planType: data['planType'] ?? 'regular',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'scanLimit': scanLimit,
      'durationDays': durationDays,
      'price': price,
      'currency': currency,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'features': features,
      'planType': planType,
    };
  }

  SubscriptionPlanModel copyWith({
    String? id,
    String? name,
    String? description,
    int? scanLimit,
    int? durationDays,
    double? price,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? features,
    String? planType,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      scanLimit: scanLimit ?? this.scanLimit,
      durationDays: durationDays ?? this.durationDays,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      features: features ?? this.features,
      planType: planType ?? this.planType,
    );
  }

  String get formattedPrice => planType == 'free_trial' ? 'Free' : '$price $currency';

  String get formattedDuration =>
      durationDays == 1 ? '1 day' : '$durationDays days';

  String get formattedScanLimit =>
      scanLimit == -1 ? 'Unlimited' : '$scanLimit scans';

  String get displayName =>
      '$name - $formattedScanLimit for $formattedDuration';

  bool get isFreeTrial => planType == 'free_trial';
}
