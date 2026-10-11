import 'dart:convert';
import 'package:crypto/crypto.dart';

class DevFormatters {
  // --- JSON ---
  static String formatJson(String input) {
    try {
      final decoded = jsonDecode(input);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (e) {
      throw FormatException('Invalid JSON: $e');
    }
  }

  static String minifyJson(String input) {
    try {
      final decoded = jsonDecode(input);
      return jsonEncode(decoded);
    } catch (e) {
      throw FormatException('Invalid JSON: $e');
    }
  }

  static String jsonToCsv(String input) {
    try {
      final decoded = jsonDecode(input);
      if (decoded is! List || decoded.isEmpty) {
        throw const FormatException('Input must be a JSON array of objects');
      }
      final first = decoded.first as Map<String, dynamic>;
      final headers = first.keys.toList();
      final buffer = StringBuffer();
      buffer.writeln(headers.join(','));

      for (final item in decoded) {
        if (item is Map) {
          final row = headers.map((h) => '"${item[h]?.toString().replaceAll('"', '""') ?? ""}"');
          buffer.writeln(row.join(','));
        }
      }
      return buffer.toString();
    } catch (e) {
      throw FormatException('CSV conversion failed: $e');
    }
  }

  // --- Encoders / Decoders ---
  static String base64EncodeText(String text) => base64Encode(utf8.encode(text));
  static String base64DecodeText(String encoded) => utf8.decode(base64Decode(encoded));

  static String urlEncodeText(String text) => Uri.encodeComponent(text);
  static String urlDecodeText(String encoded) => Uri.decodeComponent(encoded);

  static String hexEncodeText(String text) =>
      utf8.encode(text).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static String hexDecodeText(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return utf8.decode(bytes);
  }

  static String md5Hash(String text) => md5.convert(utf8.encode(text)).toString();
  static String sha256Hash(String text) => sha256.convert(utf8.encode(text)).toString();

  // --- Timestamp Helpers ---
  static DateTime epochToDateTime(int epochSeconds) =>
      DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);

  static int dateTimeToEpoch(DateTime dt) => dt.millisecondsSinceEpoch ~/ 1000;

  // --- Word / Char Count ---
  static Map<String, dynamic> analyzeText(String text) {
    final chars = text.length;
    final charsNoSpaces = text.replaceAll(RegExp(r'\s+'), '').length;
    final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    final lines = text.isEmpty ? 0 : text.split('\n').length;
    final readingTimeMinutes = (words / 200).ceil(); // ~200 WPM

    return {
      'characters': chars,
      'charactersNoSpaces': charsNoSpaces,
      'words': words,
      'lines': lines,
      'readingTimeMinutes': readingTimeMinutes,
    };
  }

  // --- Text Diff ---
  static List<DiffLine> computeDiff(String oldText, String newText) {
    final oldLines = oldText.split('\n');
    final newLines = newText.split('\n');
    final result = <DiffLine>[];

    var i = 0, j = 0;
    while (i < oldLines.length && j < newLines.length) {
      if (oldLines[i] == newLines[j]) {
        result.add(DiffLine(type: DiffType.unchanged, text: oldLines[i]));
        i++;
        j++;
      } else {
        result.add(DiffLine(type: DiffType.removed, text: oldLines[i]));
        result.add(DiffLine(type: DiffType.added, text: newLines[j]));
        i++;
        j++;
      }
    }
    while (i < oldLines.length) {
      result.add(DiffLine(type: DiffType.removed, text: oldLines[i]));
      i++;
    }
    while (j < newLines.length) {
      result.add(DiffLine(type: DiffType.added, text: newLines[j]));
      j++;
    }
    return result;
  }
}

enum DiffType { unchanged, added, removed }

class DiffLine {
  final DiffType type;
  final String text;
  DiffLine({required this.type, required this.text});
}
