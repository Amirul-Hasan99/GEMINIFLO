class RegisterRequest {
  final String name;
  final String? username;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String? phone;
  final String? avatar;

  const RegisterRequest({
    required this.name,
    this.username,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phone,
    this.avatar,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (username != null) 'username': username,
    'email': email,
    'password': password,
    'password_confirmation': passwordConfirmation,
    if (phone != null) 'phone': phone,
    if (avatar != null) 'avatar': avatar,
  };
}
