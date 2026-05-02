import 'package:cloud_firestore/cloud_firestore.dart';

enum CouponStatus { active, redeemed, given }

class Coupon {
  final String id;
  final String code;           // unique code e.g. "NAIL-A3X9"
  final String ownerId;
  final String ownerName;
  final String discount;       // "10% off"
  final CouponStatus status;
  final String? givenToId;     // if given to friend
  final String? givenToName;
  final String? givenById;     // if received from friend
  final String? givenByName;   // "Given by - Sarah"
  final String? promoSource;   // "SMS", "Flyer", "Event" — for SMS/flyer codes
  final DateTime createdAt;
  final DateTime? redeemedAt;
  final String? notes;

  Coupon({
    required this.id,
    required this.code,
    required this.ownerId,
    required this.ownerName,
    required this.discount,
    required this.status,
    this.givenToId,
    this.givenToName,
    this.givenById,
    this.givenByName,
    this.promoSource,
    required this.createdAt,
    this.redeemedAt,
    this.notes,
  });

  factory Coupon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Coupon(
      id: doc.id,
      code: data['code'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      discount: data['discount'] ?? '10% off',
      status: CouponStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CouponStatus.active,
      ),
      givenToId: data['givenToId'],
      givenToName: data['givenToName'],
      givenById: data['givenById'],
      givenByName: data['givenByName'],
      promoSource: data['promoSource'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      redeemedAt: data['redeemedAt'] != null
          ? (data['redeemedAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'code': code,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'discount': discount,
        'status': status.name,
        'givenToId': givenToId,
        'givenToName': givenToName,
        'givenById': givenById,
        'givenByName': givenByName,
        'promoSource': promoSource,
        'createdAt': Timestamp.fromDate(createdAt),
        'redeemedAt': redeemedAt != null ? Timestamp.fromDate(redeemedAt!) : null,
        'notes': notes,
      };

  // Display label for "already redeemed" section
  String get statusLabel {
    switch (status) {
      case CouponStatus.redeemed:
        return 'Redeemed';
      case CouponStatus.given:
        return givenToName != null ? 'Given to $givenToName' : 'Given to Friend';
      case CouponStatus.active:
        return 'Active';
    }
  }
}

// Promo code model (SMS/flyer codes created by salon owner)
class PromoCode {
  final String id;
  final String code;
  final String discount;
  final String description;    // "Valentine's Day Special"
  final String source;         // "SMS", "Flyer", "Event"
  final bool isActive;
  final DateTime? validUntil;

  PromoCode({
    required this.id,
    required this.code,
    required this.discount,
    required this.description,
    required this.source,
    required this.isActive,
    this.validUntil,
  });

  factory PromoCode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromoCode(
      id: doc.id,
      code: data['code'] ?? '',
      discount: data['discount'] ?? '',
      description: data['description'] ?? '',
      source: data['source'] ?? 'SMS',
      isActive: data['isActive'] ?? true,
      validUntil: data['validUntil'] != null
          ? (data['validUntil'] as Timestamp).toDate()
          : null,
    );
  }
}
