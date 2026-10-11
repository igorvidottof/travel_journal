import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Shared app-private JSON storage. Rename commits a complete, flushed snapshot.
class StorageServiceLocal {
  Future<Directory> directory(String relativePath) async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/travel_journal/$relativePath');
  }

  Future<Object?> readJson(String relativePath) async {
    final root = await directory('');
    final file = File('${root.path}/$relativePath');
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded == null) {
      throw const FormatException('Invalid storage snapshot');
    }
    return decoded;
  }

  Future<void> writeJson(String relativePath, Object value) async {
    final root = await directory('');
    final file = File('${root.path}/$relativePath');
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(value), flush: true);
    await temporary.rename(file.path);
  }
}
