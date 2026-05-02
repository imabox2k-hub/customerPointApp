import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/coupon_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collections ────────────────────────────────────────────────
  CollectionReference get _customers => _db.collection('customers');
  CollectionReference get _coupons   => _db.collection('coupons');
  CollectionReference get _promoCodes => _db.collection('promo_codes');

  // ─── NEW CUSTOMER ────────────────────────────────────────────────

  Future<Customer> createCustomer({
    required String name,
    required String phone,
    String? email,
    DateTime? birthday,
    String? referredBy,
    required String howFound,
  }) async {
    final docRef = _customers.doc();
    final customer = Customer(
      id: docRef.id,
      name: name,
      phone: phone,
      email: email,
      birthday: birthday,
      referredBy: referredBy,
      howFound: howFound,
      points: 0,
      createdAt: DateTime.now(),
    );
    await docRef.set(customer.toFirestore());
    return customer;
  }

  // ─── EXISTING CUSTOMER LOGIN ─────────────────────────────────────

  Future<Customer?> findCustomerByPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final snap = await _customers
        .where('phone', isEqualTo: clean)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Customer.fromFirestore(snap.docs.first);
  }

  Future<List<Customer>> searchCustomersByName(String name) async {
    final snap = await _customers
        .where('name', isGreaterThanOrEqualTo: name)
        .where('name', isLessThan: '${name}z')
        .limit(10)
        .get();
    return snap.docs.map((d) => Customer.fromFirestore(d)).toList();
  }

  // ─── POINTS ─────────────────────────────────────────────────────

  /// Add 1 point per visit. Every 5 visits earns a reward automatically.
  Future<Map<String, dynamic>> addVisitPoint(Customer customer) async {
    final newPoints = customer.points + 1;
    final isRewardMilestone = newPoints % 5 == 0;

    // If milestone, reset points back to 0 after earning reward
    final pointsToSave = isRewardMilestone ? 0 : newPoints;

    await _customers.doc(customer.id).update({'points': pointsToSave});

    Coupon? newCoupon;
    if (isRewardMilestone) {
      newCoupon = await _generateReward(customer);
    }

    return {'points': pointsToSave, 'newCoupon': newCoupon};
  }

  /// Creates a reward coupon — no code shown to customer, just goes into their redeemable slot
  Future<Coupon> _generateReward(Customer customer) async {
    final docRef = _coupons.doc();
    final coupon = Coupon(
      id: docRef.id,
      code: docRef.id, // internal tracking only, never shown to customer
      ownerId: customer.id,
      ownerName: customer.name,
      discount: '10% off',
      status: CouponStatus.active,
      createdAt: DateTime.now(),
      notes: 'Earned after 5 visits',
    );
    await docRef.set(coupon.toFirestore());
    return coupon;
  }

  // ─── COUPONS ─────────────────────────────────────────────────────

  Stream<List<Coupon>> streamCustomerCoupons(String customerId) {
    return _coupons
        .where('ownerId', isEqualTo: customerId)
        .snapshots()
        .map((snap) {
          final coupons = snap.docs.map((d) => Coupon.fromFirestore(d)).toList();
          // Sort in Dart to avoid needing a Firestore composite index
          coupons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return coupons;
        });
  }

  /// Customer redeems their own coupon at the salon
  Future<void> redeemCoupon(String couponId) async {
    await _coupons.doc(couponId).update({
      'status': CouponStatus.redeemed.name,
      'redeemedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Customer gives coupon to a friend
  Future<void> giveCouponToFriend({
    required Coupon coupon,
    required Customer friend,
  }) async {
    final batch = _db.batch();

    // Mark original coupon as "given"
    batch.update(_coupons.doc(coupon.id), {
      'status': CouponStatus.given.name,
      'givenToId': friend.id,
      'givenToName': friend.name,
      'redeemedAt': Timestamp.fromDate(DateTime.now()),
      'notes': 'Given to ${friend.name}',
    });

    // Create a new coupon in the friend's account
    final newDocRef = _coupons.doc();
    final friendCoupon = Coupon(
      id: newDocRef.id,
      code: coupon.code,
      ownerId: friend.id,
      ownerName: friend.name,
      discount: coupon.discount,
      status: CouponStatus.active,
      givenById: coupon.ownerId,
      givenByName: coupon.ownerName,
      createdAt: DateTime.now(),
      notes: 'Given by - ${coupon.ownerName}',
    );
    batch.set(newDocRef, friendCoupon.toFirestore());

    await batch.commit();
  }

  // ─── PROMO / SMS / FLYER CODES ───────────────────────────────────

  Future<PromoCode?> validatePromoCode(String code) async {
    final clean = code.trim().toUpperCase();
    final snap = await _promoCodes
        .where('code', isEqualTo: clean)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final promo = PromoCode.fromFirestore(snap.docs.first);
    // Check expiry
    if (promo.validUntil != null && promo.validUntil!.isBefore(DateTime.now())) {
      return null;
    }
    return promo;
  }

  /// Redeem a promo code for a customer — creates a coupon in their account
  Future<Coupon> redeemPromoCode({
    required Customer customer,
    required PromoCode promo,
  }) async {
    final docRef = _coupons.doc();
    final coupon = Coupon(
      id: docRef.id,
      code: promo.code,
      ownerId: customer.id,
      ownerName: customer.name,
      discount: promo.discount,
      status: CouponStatus.redeemed,
      promoSource: promo.source,
      createdAt: DateTime.now(),
      redeemedAt: DateTime.now(),
      notes: '${promo.source} promo: ${promo.description}',
    );
    await docRef.set(coupon.toFirestore());
    return coupon;
  }

  // ─── ADMIN: Create a promo code ──────────────────────────────────

  Future<void> createPromoCode({
    required String code,
    required String discount,
    required String description,
    required String source,
    DateTime? validUntil,
  }) async {
    await _promoCodes.doc(code.toUpperCase()).set({
      'code': code.toUpperCase(),
      'discount': discount,
      'description': description,
      'source': source,
      'isActive': true,
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil) : null,
    });
  }
}
