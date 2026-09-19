import '../models/user_model.dart';

class AuthMockDataSource {
  UserModel _currentUser = const UserModel(
    id: 'USR-001',
    name: 'Sarah Anindya',
    email: 'sarah.anindya@gmail.com',
    phone: '+62 812-9876-5432',
    role: 'user',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
  );

  static const UserModel adminUser = UserModel(
    id: 'ADM-001',
    name: 'Pak Bram (Florist Ops)',
    email: 'admin@geminiflo.com',
    phone: '+62 811-9988-7711',
    role: 'admin',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=400',
  );

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (email.contains('admin')) {
      _currentUser = adminUser;
      return {
        'user': adminUser,
        'token': 'mock_admin_bearer_token_778899',
      };
    } else {
      _currentUser = UserModel(
        id: 'USR-001',
        name: email.startsWith('sarah') ? 'Sarah Anindya' : 'Penyewa Geminiflo',
        email: email,
        phone: '+62 812-9876-5432',
        role: 'user',
        avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
      );
      return {
        'user': _currentUser,
        'token': 'mock_user_bearer_token_112233',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone ?? '+62 812-0000-0000',
      role: 'user',
    );
    return {
      'user': _currentUser,
      'token': 'mock_token_registered_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<UserModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  Future<UserModel> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = UserModel(
      id: _currentUser.id,
      name: name,
      email: _currentUser.email,
      phone: phone ?? _currentUser.phone,
      role: _currentUser.role,
      avatar: avatar ?? _currentUser.avatar,
    );
    return _currentUser;
  }
}
