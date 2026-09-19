import 'dart:convert';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_mock_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthMockDataSource mockDataSource;
  final SecureStorageService secureStorage;
  final LocalStorageService localStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.mockDataSource,
    required this.secureStorage,
    required this.localStorage,
  });

  @override
  Future<User> login({required String email, required String password}) async {
    final Map<String, dynamic> result;
    if (AppConfig.useMockData) {
      result = await mockDataSource.login(email: email, password: password);
    } else {
      result = await remoteDataSource.login(email: email, password: password);
    }

    final user = result['user'] as UserModel;
    final token = result['token'] as String;

    await secureStorage.saveToken(token);
    await localStorage.saveUserRole(user.role);
    await localStorage.setString(AppConstants.keyUserData, jsonEncode(user.toJson()));

    return user;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    final Map<String, dynamic> result;
    if (AppConfig.useMockData) {
      result = await mockDataSource.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );
    } else {
      result = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );
    }

    final user = result['user'] as UserModel;
    final token = result['token'] as String;

    await secureStorage.saveToken(token);
    await localStorage.saveUserRole(user.role);
    await localStorage.setString(AppConstants.keyUserData, jsonEncode(user.toJson()));

    return user;
  }

  @override
  Future<void> logout() async {
    try {
      if (!AppConfig.useMockData) {
        await remoteDataSource.logout();
      } else {
        await mockDataSource.logout();
      }
    } catch (_) {}

    await secureStorage.clearAuthData();
    await localStorage.remove(AppConstants.keyUserRole);
    await localStorage.remove(AppConstants.keyUserData);
  }

  @override
  Future<void> forgotPassword(String email) async {
    if (AppConfig.useMockData) {
      await mockDataSource.forgotPassword(email);
    } else {
      await remoteDataSource.forgotPassword(email);
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (AppConfig.useMockData) {
      await mockDataSource.resetPassword(
        email: email,
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    } else {
      await remoteDataSource.resetPassword(
        email: email,
        token: token,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await secureStorage.getToken();
    if (token == null) return null;

    final cachedUserJson = localStorage.getString(AppConstants.keyUserData);
    if (cachedUserJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(cachedUserJson));
      } catch (_) {}
    }

    try {
      final UserModel user;
      if (AppConfig.useMockData) {
        user = await mockDataSource.getProfile();
      } else {
        user = await remoteDataSource.getProfile();
      }
      await localStorage.setString(AppConstants.keyUserData, jsonEncode(user.toJson()));
      await localStorage.saveUserRole(user.role);
      return user;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  }) async {
    final UserModel updatedUser;
    if (AppConfig.useMockData) {
      updatedUser = await mockDataSource.updateProfile(name: name, phone: phone, avatar: avatar);
    } else {
      updatedUser = await remoteDataSource.updateProfile(name: name, phone: phone, avatar: avatar);
    }

    await localStorage.setString(AppConstants.keyUserData, jsonEncode(updatedUser.toJson()));
    return updatedUser;
  }
}
