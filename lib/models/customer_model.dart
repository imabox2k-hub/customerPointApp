import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final DateTime? birthday;
  final String? referredBy;    // name of who referred them
  final String howFound;       // "Google", "Instagram", "Facebook", "Friend", "Walk-in", "Other"
  final int points;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.birthday,
    this.referredBy,
    required this.howFound,
    this.points = 0,
    required this.createdAt,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      birthday: data['birthday'] != null
          ? (data['birthday'] as Timestamp).toDate()
          : null,
      referredBy: data['referredBy'],
      howFound: data['howFound'] ?? 'Other',
      points: data['points'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'email': email,
        'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
        'referredBy': referredBy,
        'howFound': howFound,
        'points': points,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Customer copyWith({int? points}) => Customer(
        id: id,
        name: name,
        phone: phone,
        email: email,
        birthday: birthday,
        referredBy: referredBy,
        howFound: howFound,
        points: points ?? this.points,
        createdAt: createdAt,
      );
}
