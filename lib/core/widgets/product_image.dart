import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Displays bundled, network, data-URI, and Android-local product images.
class ProductImage extends StatelessWidget {
  final String? source;
  final BoxFit fit;
  final Widget? placeholder;

  const ProductImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  Widget _fallback(BuildContext context) =>
      placeholder ??
      const Center(
        child: Icon(Icons.local_florist, color: AppColors.primary, size: 40),
      );

  @override
  Widget build(BuildContext context) {
    final imageSource = source?.trim() ?? '';
    if (imageSource.isEmpty) return _fallback(context);

    final ImageProvider<Object>? provider;
    if (imageSource.startsWith('assets/')) {
      provider = AssetImage(imageSource);
    } else if (imageSource.startsWith('data:image/')) {
      final separator = imageSource.indexOf(',');
      if (separator < 0) return _fallback(context);
      try {
        provider = MemoryImage(
          base64Decode(imageSource.substring(separator + 1)),
        );
      } on FormatException {
        return _fallback(context);
      }
    } else {
      final uri = Uri.tryParse(imageSource);
      if (uri == null) return _fallback(context);
      if (uri.scheme == 'http' ||
          uri.scheme == 'https' ||
          uri.scheme == 'blob') {
        provider = NetworkImage(imageSource);
      } else if (uri.scheme == 'file' && !kIsWeb) {
        provider = FileImage(File.fromUri(uri));
      } else if (uri.scheme.isEmpty && !kIsWeb) {
        provider = FileImage(File(imageSource));
      } else {
        return _fallback(context);
      }
    }

    return Image(
      image: provider,
      fit: fit,
      errorBuilder: (_, _, _) => _fallback(context),
    );
  }
}
