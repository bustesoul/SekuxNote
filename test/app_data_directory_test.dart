import 'package:flutter_test/flutter_test.dart';
import 'package:sekuxnote/app/storage/app_data_directory.dart';

void main() {
  test('iOS stores SekuxNote data in Documents', () {
    expect(usesDocumentsDataDirectory('ios'), isTrue);
  });

  test('other platforms retain Application Support', () {
    for (final operatingSystem in ['android', 'linux', 'macos', 'windows']) {
      expect(
        usesDocumentsDataDirectory(operatingSystem),
        isFalse,
        reason: operatingSystem,
      );
    }
  });
}
