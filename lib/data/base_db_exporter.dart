// lib/data/base_db_exporter.dart
import 'package:share_plus/share_plus.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'product_database_helper.dart';

class BaseDbExporter {
  static Future<void> shareBaseDb({String? subject}) async {
    final path = await ProductDatabaseHelper.instance.getBaseDbPath();
    final file = XFile(
      path,
      mimeType: lookupMimeType(path) ?? 'application/octet-stream',
      name: basename(path),
    );
    await Share.shareXFiles([file], subject: subject ?? 'vita_base_foods.db');
  }
}
