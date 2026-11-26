import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> downloadReportFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required String subject,
  required String text,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: mimeType)],
      fileNameOverrides: [fileName],
      subject: subject,
      text: text,
    ),
  );
}
