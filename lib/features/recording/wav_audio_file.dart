import 'dart:io';
import 'dart:typed_data';

class WavAudioFormat {
  const WavAudioFormat({
    this.sampleRate = 16000,
    this.channels = 1,
    this.bitsPerSample = 16,
  });

  final int sampleRate;
  final int channels;
  final int bitsPerSample;

  int get blockAlign => channels * (bitsPerSample ~/ 8);
  int get bytesPerSecond => sampleRate * blockAlign;
}

class WavValidation {
  const WavValidation({
    required this.isValid,
    required this.code,
    required this.fileBytes,
    this.dataBytes = 0,
    this.sampleRate = 0,
    this.channels = 0,
    this.bitsPerSample = 0,
  });

  final bool isValid;
  final String code;
  final int fileBytes;
  final int dataBytes;
  final int sampleRate;
  final int channels;
  final int bitsPerSample;

  int get durationMilliseconds {
    final blockAlign = channels * (bitsPerSample ~/ 8);
    if (!isValid || sampleRate <= 0 || blockAlign <= 0) return 0;
    return (dataBytes * 1000) ~/ (sampleRate * blockAlign);
  }
}

abstract final class WavAudioFile {
  static const recordingFormat = WavAudioFormat();

  static Future<WavValidation> validate(
    File file, {
    bool requireCanonicalHeader = false,
  }) async {
    if (!await file.exists()) {
      return const WavValidation(isValid: false, code: 'missing', fileBytes: 0);
    }
    final length = await file.length();
    if (length < 12 || length > 0xFFFFFFFF) {
      return WavValidation(
        isValid: false,
        code: 'invalidLength',
        fileBytes: length,
      );
    }
    final handle = await file.open(mode: FileMode.read);
    try {
      final bytes = await handle.read(length < 4096 ? length : 4096);
      return validateBytes(
        Uint8List.fromList(bytes),
        actualFileBytes: length,
        requireCanonicalHeader: requireCanonicalHeader,
      );
    } finally {
      await handle.close();
    }
  }

  static WavValidation validateBytes(
    Uint8List bytes, {
    int? actualFileBytes,
    bool requireCanonicalHeader = false,
  }) {
    final fileBytes = actualFileBytes ?? bytes.length;
    if (bytes.length < 12 ||
        !_asciiEquals(bytes, 0, 'RIFF') ||
        !_asciiEquals(bytes, 8, 'WAVE')) {
      return WavValidation(
        isValid: false,
        code: 'invalidRiffHeader',
        fileBytes: fileBytes,
      );
    }
    final view = ByteData.sublistView(bytes);
    final riffSize = view.getUint32(4, Endian.little);
    if (riffSize != fileBytes - 8) {
      return WavValidation(
        isValid: false,
        code: 'riffSizeMismatch',
        fileBytes: fileBytes,
      );
    }

    var offset = 12;
    var audioFormat = 0;
    var channels = 0;
    var sampleRate = 0;
    var bitsPerSample = 0;
    var dataBytes = -1;
    var dataOffset = -1;
    while (offset + 8 <= bytes.length) {
      final chunkSize = view.getUint32(offset + 4, Endian.little);
      final payloadOffset = offset + 8;
      if (_asciiEquals(bytes, offset, 'fmt ') && chunkSize >= 16) {
        if (payloadOffset + 16 > bytes.length) break;
        audioFormat = view.getUint16(payloadOffset, Endian.little);
        channels = view.getUint16(payloadOffset + 2, Endian.little);
        sampleRate = view.getUint32(payloadOffset + 4, Endian.little);
        bitsPerSample = view.getUint16(payloadOffset + 14, Endian.little);
      } else if (_asciiEquals(bytes, offset, 'data')) {
        dataBytes = chunkSize;
        dataOffset = payloadOffset;
        break;
      }
      final next = payloadOffset + chunkSize + (chunkSize.isOdd ? 1 : 0);
      if (next <= offset || next > fileBytes) break;
      if (next > bytes.length) {
        return WavValidation(
          isValid: false,
          code: 'headerTooLarge',
          fileBytes: fileBytes,
        );
      }
      offset = next;
    }

    final blockAlign = channels * (bitsPerSample ~/ 8);
    final valid =
        audioFormat == 1 &&
        channels > 0 &&
        sampleRate > 0 &&
        bitsPerSample > 0 &&
        bitsPerSample % 8 == 0 &&
        dataBytes > 0 &&
        dataOffset >= 0 &&
        dataOffset + dataBytes <= fileBytes &&
        blockAlign > 0 &&
        dataBytes % blockAlign == 0 &&
        (!requireCanonicalHeader ||
            (dataOffset == 44 && dataBytes == fileBytes - 44));
    return WavValidation(
      isValid: valid,
      code: valid ? 'valid' : 'invalidPcmData',
      fileBytes: fileBytes,
      dataBytes: dataBytes < 0 ? 0 : dataBytes,
      sampleRate: sampleRate,
      channels: channels,
      bitsPerSample: bitsPerSample,
    );
  }

  static Future<WavValidation> finalizePcm({
    required File pcmFile,
    required File wavFile,
    WavAudioFormat format = recordingFormat,
  }) async {
    if (!await pcmFile.exists()) {
      return const WavValidation(
        isValid: false,
        code: 'missingPcm',
        fileBytes: 0,
      );
    }
    final pcmBytes = await pcmFile.length();
    if (pcmBytes <= 0 || pcmBytes % format.blockAlign != 0) {
      return WavValidation(
        isValid: false,
        code: 'invalidPcmData',
        fileBytes: pcmBytes,
        dataBytes: pcmBytes,
      );
    }
    final temporary = File('${wavFile.path}.tmp');
    if (await temporary.exists()) await temporary.delete();
    final sink = temporary.openWrite(mode: FileMode.writeOnly);
    sink.add(header(pcmBytes, format: format));
    await sink.addStream(pcmFile.openRead());
    await sink.flush();
    await sink.close();
    final validation = await validate(temporary, requireCanonicalHeader: true);
    if (!validation.isValid) return validation;

    if (await wavFile.exists()) {
      final existing = await validate(wavFile, requireCanonicalHeader: true);
      if (existing.isValid) {
        await temporary.delete();
        await pcmFile.delete();
        return existing;
      }
      final backup = File('${wavFile.path}.invalid.bak');
      if (await backup.exists()) await backup.delete();
      await wavFile.rename(backup.path);
      try {
        await temporary.rename(wavFile.path);
        await backup.delete();
      } catch (_) {
        if (!await wavFile.exists() && await backup.exists()) {
          await backup.rename(wavFile.path);
        }
        rethrow;
      }
    } else {
      await temporary.rename(wavFile.path);
    }
    await pcmFile.delete();
    return validate(wavFile, requireCanonicalHeader: true);
  }

  static Future<WavValidation> recoverLegacyInterruptedFile(
    File wavFile,
  ) async {
    if (!await wavFile.exists() || await wavFile.length() <= 44) {
      return validate(wavFile, requireCanonicalHeader: true);
    }
    final handle = await wavFile.open(mode: FileMode.read);
    final first = await handle.read(44);
    await handle.close();
    if (first.length < 44 ||
        !_asciiEquals(first, 0, 'RIFF') ||
        !_asciiEquals(first, 8, 'WAVE') ||
        !_asciiEquals(first, 36, 'data')) {
      return validate(wavFile, requireCanonicalHeader: true);
    }
    final temporaryPcm = File('${wavFile.path}.legacy.pcm.part');
    if (await temporaryPcm.exists()) await temporaryPcm.delete();
    final sink = temporaryPcm.openWrite(mode: FileMode.writeOnly);
    await sink.addStream(wavFile.openRead(44));
    await sink.flush();
    await sink.close();
    return finalizePcm(pcmFile: temporaryPcm, wavFile: wavFile);
  }

  static Uint8List header(
    int dataBytes, {
    WavAudioFormat format = recordingFormat,
  }) {
    final data = ByteData(44);
    void ascii(int offset, String value) {
      for (var index = 0; index < value.length; index += 1) {
        data.setUint8(offset + index, value.codeUnitAt(index));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + dataBytes, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, format.channels, Endian.little);
    data.setUint32(24, format.sampleRate, Endian.little);
    data.setUint32(28, format.bytesPerSecond, Endian.little);
    data.setUint16(32, format.blockAlign, Endian.little);
    data.setUint16(34, format.bitsPerSample, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, dataBytes, Endian.little);
    return data.buffer.asUint8List();
  }

  static bool _asciiEquals(List<int> bytes, int offset, String expected) {
    if (offset < 0 || offset + expected.length > bytes.length) return false;
    for (var index = 0; index < expected.length; index += 1) {
      if (bytes[offset + index] != expected.codeUnitAt(index)) return false;
    }
    return true;
  }
}
