import 'package:cloud_firestore/cloud_firestore.dart';

import 'item.dart';
import 'plan.dart';

String _tgl(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime _parseTgl(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

Kategori _kategori(Object? name) => Kategori.values.firstWhere(
      (k) => k.name == name,
      orElse: () => Kategori.wisata,
    );

Map<String, dynamic> _entryToMap(PlanEntry e) => {
      'itemId': e.itemId,
      'nama': e.nama,
      'kategori': e.kategori.name,
      'jam': e.jam,
      'biaya': e.biaya,
      'lat': e.lat,
      'lng': e.lng,
    };

PlanEntry _entryFromMap(Map<String, dynamic> m) => PlanEntry(
      itemId: m['itemId'] as String? ?? '',
      nama: m['nama'] as String? ?? '',
      kategori: _kategori(m['kategori']),
      jam: m['jam'] as String? ?? '',
      biaya: (m['biaya'] as num?)?.toInt() ?? 0,
      lat: (m['lat'] as num?)?.toDouble() ?? 0,
      lng: (m['lng'] as num?)?.toDouble() ?? 0,
    );

PlanDay _dayFromMap(Map<String, dynamic> m) => PlanDay(
      tanggal: _parseTgl(m['tanggal'] as String),
      entries: [
        for (final e in (m['entries'] as List<dynamic>? ?? const []))
          _entryFromMap(e as Map<String, dynamic>),
      ],
    );

/// Kolom yang ditulis ke Firestore, di luar 'createdAt' (ditambah repository).
/// Harus sama dengan daftar kolom di Firestore rules.
Map<String, dynamic> planToMap(Plan p) => {
      'mulai': _tgl(p.input.mulai),
      'durasi': p.hari.length,
      'anggaran': p.input.anggaran,
      'kategori': p.input.kategori.map((k) => k.name).toList(),
      'minat': p.input.minat.toList(),
      'malam': p.malam,
      'total': p.total,
      'penginapan': p.penginapan == null ? null : _entryToMap(p.penginapan!),
      'hari': [
        for (final d in p.hari)
          {
            'tanggal': _tgl(d.tanggal),
            'entries': [for (final e in d.entries) _entryToMap(e)],
          },
      ],
      'catatan': p.catatan,
    };

Plan planFromMap(Map<String, dynamic> m) {
  final hari = [
    for (final h in (m['hari'] as List<dynamic>? ?? const []))
      _dayFromMap(h as Map<String, dynamic>),
  ];
  final input = PlanInput(
    mulai: _parseTgl(m['mulai'] as String),
    durasi: (m['durasi'] as num?)?.toInt() ?? hari.length,
    anggaran: (m['anggaran'] as num?)?.toInt() ?? 0,
    kategori: {
      for (final k in (m['kategori'] as List<dynamic>? ?? const []))
        _kategori(k),
    },
    minat: {
      for (final t in (m['minat'] as List<dynamic>? ?? const [])) t as String,
    },
  );
  final inap = m['penginapan'];
  return Plan(
    input: input,
    hari: hari,
    malam: (m['malam'] as num?)?.toInt() ?? (hari.length - 1),
    penginapan:
        inap == null ? null : _entryFromMap(inap as Map<String, dynamic>),
    catatan: [
      for (final c in (m['catatan'] as List<dynamic>? ?? const [])) c as String,
    ],
  );
}

class SavedPlan {
  const SavedPlan({required this.id, required this.plan, this.dibuat});

  final String id;
  final Plan plan;
  final DateTime? dibuat;

  /// null kalau dokumennya rusak, supaya satu data buruk tidak merusak daftar.
  static SavedPlan? tryParse(String id, Map<String, dynamic> data) {
    try {
      final ts = data['createdAt'];
      return SavedPlan(
        id: id,
        plan: planFromMap(data),
        dibuat: ts is Timestamp ? ts.toDate() : null,
      );
    } catch (_) {
      return null;
    }
  }
}