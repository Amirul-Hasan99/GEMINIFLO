import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isCircle;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = false,
    this.isCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4E8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA8435C).withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.04),
        child: ClipOval(
          child: Image.asset(
            'assets/images/app_logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => GeminifloVectorLogo(size: size),
          ),
        ),
      ),
    );

    if (!showText) return logoWidget;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoWidget,
        const SizedBox(height: 12),
        const Text(
          'GEMINIFLO_',
          style: TextStyle(
            color: Color(0xFFA8435C),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'EXPRESSED WITH ELEGANCE.',
          style: TextStyle(
            color: Color(0xFFB8526F),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

/// Compact Logo Badge optimized for dark green headers (HomeScreen, AdminDashboard, Login)
class AppHeaderLogo extends StatelessWidget {
  final double size;

  const AppHeaderLogo({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4E8),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC5A059), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: Image.asset(
            'assets/images/app_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.local_florist,
              color: Color(0xFFA8435C),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Vector fallback logo when asset is missing or loading
class GeminifloVectorLogo extends StatelessWidget {
  final double size;

  const GeminifloVectorLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    final scale = size / 100.0;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(10 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4E8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA8435C).withValues(alpha: 0.2),
            blurRadius: 10 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            color: const Color(0xFFA8435C),
            size: 24 * scale,
          ),
          SizedBox(height: 2 * scale),
          Text(
            'GEMINIFLO_',
            style: TextStyle(
              color: const Color(0xFFA8435C),
              fontSize: 12 * scale,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2 * scale,
              fontFamily: 'serif',
            ),
          ),
          SizedBox(height: 1 * scale),
          Text(
            'EXPRESSED WITH ELEGANCE.',
            style: TextStyle(
              color: const Color(0xFFB8526F),
              fontSize: 5.5 * scale,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0 * scale,
            ),
          ),
        ],
      ),
    );
  }
}
