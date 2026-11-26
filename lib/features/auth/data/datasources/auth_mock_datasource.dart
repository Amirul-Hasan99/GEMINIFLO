import '../models/user_model.dart';

class AuthMockDataSource {
  static const UserModel adminUser = UserModel(
    id: 'ADM-001',
    name: 'Admin Florist',
    username: 'admin',
    email: 'admin@geminiflo.com',
    phone: '+62 811-9988-7711',
    role: 'admin',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=400',
  );

  static const UserModel defaultUser = UserModel(
    id: 'USR-001',
    name: 'Sarah Anindya (User Klien)',
    username: 'user',
    email: 'user@geminiflo.com',
    phone: '+62 812-9876-5432',
    role: 'user',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
  );

  // In-memory registered user storage
  final Map<String, UserModel> _registeredUsers = {
    'admin': adminUser,
    'admin@geminiflo.com': adminUser,
    'user': defaultUser,
    'user@geminiflo.com': defaultUser,
    'sarah.anindya@gmail.com': defaultUser,
  };

  UserModel _currentUser = defaultUser;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final normalized = email.trim().toLowerCase();

    // Check if admin
    if (normalized == 'admin' || normalized == 'admin@geminiflo.com') {
      _currentUser = adminUser;
      return {'user': adminUser, 'token': 'mock_admin_bearer_token_778899'};
    }

    // Check registered accounts
    if (_registeredUsers.containsKey(normalized)) {
      _currentUser = _registeredUsers[normalized]!;
      return {
        'user': _currentUser,
        'token': 'mock_user_bearer_token_${_currentUser.id}',
      };
    }

    // If new username/email, create dynamic session as user
    final displayName = normalized.contains('@')
        ? normalized.split('@').first
        : normalized;

    final formattedName = displayName.isNotEmpty
        ? '${displayName[0].toUpperCase()}${displayName.substring(1)}'
        : 'User Klien';

    final newUser = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
      name: formattedName,
      username: normalized.contains('@') ? null : normalized,
      email: normalized.contains('@')
          ? normalized
          : '$normalized@geminiflo.com',
      phone: '+62 812-9876-5432',
      role: 'user',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
    );

    _registeredUsers[normalized] = newUser;
    _currentUser = newUser;

    return {
      'user': _currentUser,
      'token': 'mock_user_bearer_token_${_currentUser.id}',
    };
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? username,
    String? phone,
    String? avatar,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username?.trim().toLowerCase();
    if (normalizedUsername != null &&
        normalizedUsername.isNotEmpty &&
        _registeredUsers.containsKey(normalizedUsername)) {
      throw StateError(
        'Username sudah digunakan. Silakan pilih username lain.',
      );
    }
    if (_registeredUsers.containsKey(normalizedEmail)) {
      throw StateError('Email sudah terdaftar. Silakan gunakan email lain.');
    }
    final newUser = UserModel(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isNotEmpty ? name.trim() : 'Pengguna Baru',
      username: normalizedUsername ?? normalizedEmail.split('@').first,
      email: normalizedEmail.contains('@')
          ? normalizedEmail
          : '$normalizedEmail@geminiflo.com',
      phone: phone,
      role: 'user',
      avatar: avatar,
    );

    _registeredUsers[normalizedEmail] = newUser;
    if (normalizedUsername != null && normalizedUsername.isNotEmpty) {
      _registeredUsers[normalizedUsername] = newUser;
    }
    _currentUser = newUser;

    return {
      'user': _currentUser,
      'token': 'mock_token_registered_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<UserModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }

  Future<UserModel> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = UserModel(
      id: _currentUser.id,
      name: name,
      username: _currentUser.username,
      email: _currentUser.email,
      phone: phone ?? _currentUser.phone,
      role: _currentUser.role,
      avatar: avatar ?? _currentUser.avatar,
    );
    return _currentUser;
  }
}
