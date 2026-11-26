import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> loginWithGoogle({required String idToken});
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? username,
    String? phone,
    String? avatar,
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
  Future<User> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
