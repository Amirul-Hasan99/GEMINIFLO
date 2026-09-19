class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'user' or 'admin'
  final String? avatar;
  final DateTime? emailVerifiedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatar,
    this.emailVerifiedAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
}
