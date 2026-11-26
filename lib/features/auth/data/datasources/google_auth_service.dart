import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initialization;

  Future<String> signInAndGetFirebaseToken() async {
    _initialization ??= _initialize();
    await _initialization;
    final account = await _googleSignIn.authenticate();
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

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> _initialize() async {
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
