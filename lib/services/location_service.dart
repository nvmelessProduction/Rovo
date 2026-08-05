import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Posizione GPS dell'utente, con gestione dei permessi.
class LocationService {
  const LocationService();

  /// Flusso continuo di posizioni, per seguire l'utente durante la guida.
  /// Aggiorna ogni 5 metri di spostamento.
  Stream<Position> stream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    );
  }

  /// Chiede il permesso di posizione; true se concesso.
  Future<bool> assicuraPermesso() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var permesso = await Geolocator.checkPermission();
      if (permesso == LocationPermission.denied) {
        permesso = await Geolocator.requestPermission();
      }
      return permesso == LocationPermission.always ||
          permesso == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

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
