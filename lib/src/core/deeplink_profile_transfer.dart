import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

/// Share sheet export and file picker import. Kept apart from storage so the
/// storage layer stays unit-testable.
class DeeplinkProfileTransfer {
  const DeeplinkProfileTransfer();

  Future<void> share(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Deeplink tester profile',
      ),
    );
  }

  /// Opens the system "save as" dialog so the user can put the file in
  /// Downloads (or any folder). Returns the chosen path, or `null` when
  /// cancelled.
  Future<String?> saveToDevice(String fileName, Uint8List bytes) {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save deeplink profile',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );
  }

  /// Returns the picked file's text, or `null` when the user cancelled.
  Future<String?> pickJsonText() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    final picked = result?.files.firstOrNull;
    if (picked == null) return null;
    final bytes = picked.bytes;
    if (bytes != null) return String.fromCharCodes(bytes);
    final path = picked.path;
    if (path == null) return null;
    return File(path).readAsString();
  }
}
