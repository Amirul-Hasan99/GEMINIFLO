import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/firebase_client_config.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initialization;

  Future<void> initializeGoogleSignIn() async {
    _initialization ??= _googleSignIn.initialize(
      clientId: kIsWeb ? FirebaseClientConfig.googleWebClientId : null,
    );
    await _initialization;
  }

  Future<String> signInAndGetFirebaseToken() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Gunakan tombol Google resmi pada halaman untuk login di web.',
      );
    }
    await _initializeNativeFirebase();
    await initializeGoogleSignIn();
    final account = await _googleSignIn.authenticate();
    return signInNativeAccount(account);
  }

  Future<String> signInNativeAccount(GoogleSignInAccount account) async {
    final credential = GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final token = await userCredential.user?.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('Firebase tidak memberikan token autentikasi.');
    }
    return token;
  }

  Future<String> exchangeWebGoogleToken(String googleIdToken) async {
    final apiKey = FirebaseClientConfig.webApiKey;
    if (apiKey.isEmpty) {
      throw StateError(
        'FIREBASE_WEB_API_KEY belum diisi saat build web. Jalankan '
        'npm run web:run atau npm run web:build agar key dibaca dari konfigurasi Firebase.',
      );
    }

    try {
      final response = await Dio().post<Map<String, dynamic>>(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp',
        queryParameters: {'key': apiKey},
        data: {
          'postBody':
              'id_token=${Uri.encodeQueryComponent(googleIdToken)}&providerId=google.com',
          'requestUri': Uri.base.origin,
          'returnIdpCredential': true,
          'returnSecureToken': true,
        },
      );
      final firebaseToken = response.data?['idToken']?.toString();
      if (firebaseToken == null || firebaseToken.isEmpty) {
        throw StateError('Firebase tidak memberikan token autentikasi.');
      }
      return firebaseToken;
    } on DioException catch (error) {
      final details = error.response?.data;
      final firebaseError = details is Map
          ? (details['error'] is Map
                ? (details['error'] as Map)['message']?.toString()
                : null)
          : null;
      if (firebaseError?.contains('OPERATION_NOT_ALLOWED') ?? false) {
        throw StateError(
          'Provider Google belum diaktifkan pada Firebase Authentication.',
        );
      }
      throw StateError(
        firebaseError == null
            ? 'Google belum dapat dihubungkan ke Firebase. Periksa provider Google dan domain yang diizinkan.'
            : 'Google gagal masuk ke Firebase ($firebaseError). Periksa provider dan konfigurasi domain.',
      );
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb && Firebase.apps.isNotEmpty) {
      await FirebaseAuth.instance.signOut();
    }
    await _googleSignIn.signOut();
  }

  Future<void> _initializeNativeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } on FirebaseException catch (error) {
      throw StateError(
        'Firebase Android belum dikonfigurasi (${error.code}). Tambahkan google-services.json dan aktifkan Google Sign-In di Firebase Console.',
      );
    }
    await _googleSignIn.initialize();
  }
}
