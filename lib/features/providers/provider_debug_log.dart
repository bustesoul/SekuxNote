import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Local-only diagnostics for provider integration debugging.
///
/// Entries deliberately exclude API keys, request bodies, and transcripts.
abstract final class ProviderDebugLog {
  static const _fileName = 'provider_debug.log';

  static Future<void> record(
    String event, {
    Map<String, Object?> details = const {},
  }) async {
    try {
      final directory = await getApplicationSupportDirectory();
      final entry = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'event': event,
        'details': details.map(
          (key, value) => MapEntry(key, _redact(value?.toString() ?? '')),
        ),
      });
      await File(
        '${directory.path}/$_fileName',
      ).writeAsString('$entry\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Diagnostics must never disrupt a provider request.
    }
  }

  static String _redact(String value) => value
      .replaceAll(
        RegExp(r'Bearer\s+\S+', caseSensitive: false),
        'Bearer [redacted]',
      )
      .replaceAll(RegExp(r'gsk_[A-Za-z0-9_-]+'), '[redacted]')
      .replaceAll(RegExp(r'\bsk-[A-Za-z0-9_-]+'), '[redacted]')
      .replaceAll(
        RegExp(
          r'((?:OSSAccessKeyId|Signature|policy)=)[^&;\s]+',
          caseSensitive: false,
        ),
        r'$1[redacted]',
      );
}
