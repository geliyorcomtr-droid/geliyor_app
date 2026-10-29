import 'package:url_launcher/url_launcher.dart';

/// Müşterinin kaydettiği teslimat konumu.
abstract final class CustomerLocation {
  static double? read(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static bool isValid(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (latitude.abs() > 90 || longitude.abs() > 180) return false;
    return latitude != 0 || longitude != 0;
  }

  static String format(double? latitude, double? longitude) {
    if (!isValid(latitude, longitude)) return '';
    return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }

  static Uri? mapsUri(double? latitude, double? longitude) {
    if (!isValid(latitude, longitude)) return null;
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
  }

  static Future<bool> open(double? latitude, double? longitude) async {
    final uri = mapsUri(latitude, longitude);
    if (uri == null) return false;
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return launchUrl(uri);
  }
}
