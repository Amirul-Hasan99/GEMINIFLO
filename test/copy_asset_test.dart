import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copy asset file', () {
    final source = File('icon_geminiflow.jpeg');
    if (source.existsSync()) {
      source.copySync('assets/images/app_logo.png');
    }
    expect(File('assets/images/app_logo.png').existsSync(), isTrue);
  });
}
