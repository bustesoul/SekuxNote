import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Returns the root directory for SekuxNote's local data.
///
/// iOS keeps user data in Documents. Other platforms retain the existing
/// Application Support location.
Future<Directory> getSekuxNoteDataDirectory() {
  if (usesDocumentsDataDirectory(Platform.operatingSystem)) {
    return getApplicationDocumentsDirectory();
  }
  return getApplicationSupportDirectory();
}

bool usesDocumentsDataDirectory(String operatingSystem) =>
    operatingSystem == 'ios';
