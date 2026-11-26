import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

import '../../data/datasources/google_auth_service.dart';

class GoogleSignInWebButton extends StatefulWidget {
  const GoogleSignInWebButton({
    required this.enabled,
    required this.onIdToken,
    required this.onError,
    super.key,
  });

  final bool enabled;
  final ValueChanged<String> onIdToken;
  final ValueChanged<Object> onError;

  @override
  State<GoogleSignInWebButton> createState() => _GoogleSignInWebButtonState();
}

class _GoogleSignInWebButtonState extends State<GoogleSignInWebButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _ready = false;
  bool _failedToInitialize = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await GoogleAuthService.instance.initializeGoogleSignIn();
      _subscription = GoogleSignIn.instance.authenticationEvents.listen(
        _handleAuthenticationEvent,
        onError: (Object error) => widget.onError(error),
      );
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) {
        setState(() => _failedToInitialize = true);
        widget.onError(error);
      }
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    final idToken = event.user.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      widget.onError(
        StateError('Google tidak mengirim ID token. Periksa OAuth Web Client.'),
      );
      return;
    }
    widget.onIdToken(idToken);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failedToInitialize) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: Center(
          child: Text(
            'Google Sign-In web belum siap. Periksa OAuth Web Client.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (!_ready) {
      return const SizedBox(
        width: double.infinity,
        height: 48,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.55,
          child: google_web.renderButton(
            configuration: google_web.GSIButtonConfiguration(
              type: google_web.GSIButtonType.standard,
              theme: google_web.GSIButtonTheme.outline,
              size: google_web.GSIButtonSize.large,
              text: google_web.GSIButtonText.signinWith,
              shape: google_web.GSIButtonShape.rectangular,
              logoAlignment: google_web.GSIButtonLogoAlignment.left,
              minimumWidth: 280,
              locale: 'id',
            ),
          ),
        ),
      ),
    );
  }
}
