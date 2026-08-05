import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Posizione GPS dell'utente, con gestione dei permessi.
class LocationService {
  /// Restituisce la posizione attuale, oppure null se il permesso è negato
  /// o il GPS è spento. Non lancia eccezioni: l'app deve restare usabile.
  Future<LatLng?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permesso = await Geolocator.checkPermission();
      if (permesso == LocationPermission.denied) {
        permesso = await Geolocator.requestPermission();
      }
      if (permesso == LocationPermission.denied ||
          permesso == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
