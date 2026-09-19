import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  });
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  });
  Future<User?> getCurrentUser();
  Future<User> updateProfile({required String name, String? phone, String? avatar});
}
