import 'dart:io';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<ShareResult> shareFile(
    File file, {
    required Rect sharePositionOrigin,
  }) => SharePlus.instance.share(
    ShareParams(
      // Share the persisted original, not the resized preview or picker file.
      files: [XFile(file.path)],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
