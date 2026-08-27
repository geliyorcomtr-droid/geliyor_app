import 'package:cloud_firestore/cloud_firestore.dart';

/// Ürün son kullanma tarihi (SKT) — sadece ay + yıl.
/// Gösterim: `11.2027` (ay rakam).
class ProductSkt {
  ProductSkt._();

  /// Admin seçicide ay adları (gösterim yine rakam olur).
  static const monthsTr = <String>[
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  /// Depolama: `2027-11` (ASCII, Firestore’da güvenli).
  static String storage(int month, int year) {
    final m = month.clamp(1, 12);
    return '$year-${m.toString().padLeft(2, '0')}';
  }

  /// Gösterim: `11.2027`
  static String format(int month, int year) {
    final m = month.clamp(1, 12);
    return '${m.toString().padLeft(2, '0')}.$year';
  }

  /// Kartlarda `SKT: 11.2027`. Boşsa `SKT: —`.
  static String label(String? raw) {
    final value = display(raw);
    return value.isEmpty ? 'SKT: —' : 'SKT: $value';
  }

  /// Sadece `11.2027` (veya boş).
  static String display(String? raw) {
    final parsed = parse(raw);
    if (parsed == null) {
      final trimmed = raw?.trim() ?? '';
      if (trimmed.isEmpty || trimmed == '—' || trimmed == '-') return '';
      if (trimmed.startsWith('SKT:')) {
        return display(trimmed.substring(4).trim());
      }
      return trimmed;
    }
    return format(parsed.month, parsed.year);
  }

  /// Firestore dokümanından SKT okur (string / ay-yıl sayıları / Timestamp).
  static String fromFirestore(Map<String, dynamic> data) {
    final month = _asInt(data['sktMonth'] ?? data['skt_month']);
    final year = _asInt(data['sktYear'] ?? data['skt_year']);
    if (month != null &&
        year != null &&
        month >= 1 &&
        month <= 12 &&
        year >= 2000) {
      return format(month, year);
    }

    final label = data['sktLabel'] ?? data['skt_label'];
    if (label != null) {
      final shown = display('$label');
      if (shown.isNotEmpty) return shown;
    }

    final skt = data['skt'] ?? data['SKT'] ?? data['expiry'];
    if (skt is Timestamp) {
      final d = skt.toDate();
      return format(d.month, d.year);
    }
    if (skt is DateTime) {
      return format(skt.month, skt.year);
    }
    if (skt != null) {
      final shown = display('$skt');
      if (shown.isNotEmpty) return shown;
    }
    return '';
  }

  /// Firestore’a yazılacak alanlar.
  static Map<String, Object> toFirestoreFields(String? raw) {
    final parsed = parse(raw);
    if (parsed == null) {
      final trimmed = raw?.trim() ?? '';
      return {
        'skt': trimmed,
        'sktLabel': trimmed,
        'sktMonth': 0,
        'sktYear': 0,
      };
    }
    final shown = format(parsed.month, parsed.year);
    return {
      'skt': storage(parsed.month, parsed.year),
      'sktLabel': shown,
      'sktMonth': parsed.month,
      'sktYear': parsed.year,
    };
  }

  static ({int month, int year})? parse(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;

    // "Kasım 2027" / "kasim 2027" (eski kayıtlar)
    final named = RegExp(
      r'^([A-Za-zÇĞİÖŞÜçğıöşü]+)\s+(\d{4})$',
      unicode: true,
    ).firstMatch(text);
    if (named != null) {
      final month = _monthIndex(named.group(1)!);
      final year = int.tryParse(named.group(2)!);
      if (month != null && year != null) {
        return (month: month, year: year);
      }
    }

    // "11.2027" / "11/2027" / "11-2027"
    final my = RegExp(r'^(\d{1,2})[./-](\d{4})$').firstMatch(text);
    if (my != null) {
      final month = int.tryParse(my.group(1)!);
      final year = int.tryParse(my.group(2)!);
      if (month != null && year != null && month >= 1 && month <= 12) {
        return (month: month, year: year);
      }
    }

    // Eski tam tarih: "12.08.2026" / "12/08/2026"
    final dmy = RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{4})$').firstMatch(text);
    if (dmy != null) {
      final month = int.tryParse(dmy.group(2)!);
      final year = int.tryParse(dmy.group(3)!);
      if (month != null && year != null && month >= 1 && month <= 12) {
        return (month: month, year: year);
      }
    }

    // ISO: "2027-11" / "2027-11-01"
    final iso = RegExp(r'^(\d{4})-(\d{1,2})(?:-\d{1,2})?$').firstMatch(text);
    if (iso != null) {
      final year = int.tryParse(iso.group(1)!);
      final month = int.tryParse(iso.group(2)!);
      if (month != null && year != null && month >= 1 && month <= 12) {
        return (month: month, year: year);
      }
    }

    return null;
  }

  static int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  static int? _monthIndex(String name) {
    final n = _fold(name);
    for (var i = 0; i < monthsTr.length; i++) {
      if (_fold(monthsTr[i]) == n) return i + 1;
    }
    return null;
  }

  static String _fold(String name) {
    return name
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }
}
