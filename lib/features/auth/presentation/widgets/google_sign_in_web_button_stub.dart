import 'package:flutter/widgets.dart';

class GoogleSignInWebButton extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
