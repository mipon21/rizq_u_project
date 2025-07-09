import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantRegistrationModel {
  final String uid;
  final String email;
  final String restaurantName;
  final String ownerName;
  final String phoneNumber;
  final String postalAddress;
  final String? supportEmail;
  final String? bankDetails;
  final String? ibanNumber;
  final String logoUrl;
  final String approvalStatus; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  RestaurantRegistrationModel({
    required this.uid,
    required this.email,
    required this.restaurantName,
    required this.ownerName,
    required this.phoneNumber,
    required this.postalAddress,
    this.supportEmail,
    this.bankDetails,
    this.ibanNumber,
    required this.logoUrl,
    this.approvalStatus = 'pending',
    this.rejectionReason,
    this.approvedAt,
    this.rejectedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantRegistrationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return RestaurantRegistrationModel(
      uid: data['uid'] ?? snapshot.id,
      email: data['email'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      ownerName: data['ownerName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      postalAddress: data['postalAddress'] ?? '',
      supportEmail: data['supportEmail'],
      bankDetails: data['bankDetails'],
      ibanNumber: data['ibanNumber'],
      logoUrl: data['logoUrl'] ?? '',
      approvalStatus: data['approvalStatus'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'restaurantName': restaurantName,
      'ownerName': ownerName,
      'phoneNumber': phoneNumber,
      'postalAddress': postalAddress,
      'supportEmail': supportEmail,
      'bankDetails': bankDetails,
      'ibanNumber': ibanNumber,
      'logoUrl': logoUrl,
      'approvalStatus': approvalStatus,
      'rejectionReason': rejectionReason,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RestaurantRegistrationModel copyWith({
    String? uid,
    String? email,
    String? restaurantName,
    String? ownerName,
    String? phoneNumber,
    String? postalAddress,
    String? supportEmail,
    String? bankDetails,
    String? ibanNumber,
    String? logoUrl,
    String? approvalStatus,
    String? rejectionReason,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantRegistrationModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      restaurantName: restaurantName ?? this.restaurantName,
      ownerName: ownerName ?? this.ownerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      postalAddress: postalAddress ?? this.postalAddress,
      supportEmail: supportEmail ?? this.supportEmail,
      bankDetails: bankDetails ?? this.bankDetails,
      ibanNumber: ibanNumber ?? this.ibanNumber,
      logoUrl: logoUrl ?? this.logoUrl,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => approvalStatus == 'pending';
  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';
}
