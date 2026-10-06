import 'dart:convert';
import 'dart:typed_data';

const _prefix = 'data:image/jpeg;base64,';

String encodeFoto(Uint8List bytes) => '$_prefix${base64Encode(bytes)}';

/// null kalau bukan data foto tersimpan (misalnya tautan http atau kosong).
Uint8List? decodeFoto(String? s) {
  if (s == null || !s.startsWith('data:image')) return null;
  final i = s.indexOf(',');
  if (i < 0) return null;
  try {
    return base64Decode(s.substring(i + 1));
  } catch (_) {
    return null;
  }
}