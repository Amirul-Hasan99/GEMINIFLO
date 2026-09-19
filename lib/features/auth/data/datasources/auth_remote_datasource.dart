import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    final data = apiResponse.data!;
    return {
      'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
      'token': data['token'].toString(),
    };
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone': phone,
      },
    );

    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );

    final data = apiResponse.data!;
    return {
      'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
      'token': data['token'].toString(),
    };
  }

  Future<void> logout() async {
    await _apiClient.post(ApiConstants.logout);
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _apiClient.post(
      ApiConstants.resetPassword,
      data: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiConstants.profile);
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }

  Future<UserModel> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.profile,
      data: {
        'name': name,
        'phone': phone,
        'avatar': avatar,
      },
    );
    final apiResponse = ApiResponse.fromJson(
      response.data,
      (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
    return apiResponse.data!;
  }
}
