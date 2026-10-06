import 'package:geolocator/geolocator.dart';

enum LokasiStatus { ok, layananMati, ditolak, ditolakPermanen, gagal }

class LokasiHasil {
  const LokasiHasil(this.status, {this.lat, this.lng});

  final LokasiStatus status;
  final double? lat;
  final double? lng;
}

class LocationService {
  Future<LokasiHasil> ambil() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LokasiHasil(LokasiStatus.layananMati);
      }
      var izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.deniedForever) {
        return const LokasiHasil(LokasiStatus.ditolakPermanen);
      }
      if (izin == LocationPermission.denied) {
        return const LokasiHasil(LokasiStatus.ditolak);
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LokasiHasil(LokasiStatus.ok, lat: p.latitude, lng: p.longitude);
    } catch (_) {
      return const LokasiHasil(LokasiStatus.gagal);
    }
  }

  Future<void> bukaPengaturan() => Geolocator.openAppSettings();

  static double jarakMeter(double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
}