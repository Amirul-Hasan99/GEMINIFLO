import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<User> login({required String email, required String password}) async {
    final result = await remoteDataSource.login(
      email: email,
      password: password,
    );
    final user = result['user'] as UserModel;
    await secureStorage.saveToken(result['token'] as String);
    return user;
  }

  @override
  Future<User> loginWithGoogle({required String idToken}) async {
    final result = await remoteDataSource.loginWithGoogle(idToken);
    final user = result['user'] as UserModel;
    await secureStorage.saveToken(result['token'] as String);
    return user;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? username,
    String? phone,
    String? avatar,
  }) async {
    final result = await remoteDataSource.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      username: username,
      phone: phone,
      avatar: avatar,
    );
    final user = result['user'] as UserModel;
    await secureStorage.saveToken(result['token'] as String);
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      await secureStorage.clearAuthData();
    }
  }

  @override
  Future<void> forgotPassword(String email) =>
      remoteDataSource.forgotPassword(email);

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) => remoteDataSource.resetPassword(
    email: email,
    token: token,
    password: password,
    passwordConfirmation: passwordConfirmation,
  );

  @override
  Future<User?> getCurrentUser() async {
    if (await secureStorage.getToken() == null) return null;
    try {
      return await remoteDataSource.getProfile();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  }) =>
      remoteDataSource.updateProfile(name: name, phone: phone, avatar: avatar);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => remoteDataSource.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );
}
