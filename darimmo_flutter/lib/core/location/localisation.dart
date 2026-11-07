// =====================================================================
// DarImmo - [6.4] Position actuelle du téléphone (geolocator)
// Membre C
//
// Demande l'autorisation au moment où l'utilisateur touche « Utiliser ma
// position » (jamais à l'ouverture de l'écran), avec un message clair pour
// chaque refus possible.
// =====================================================================
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocalisationException implements Exception {
  const LocalisationException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class Localisation {
  Future<LatLng> positionActuelle();
}

class GeolocatorLocalisation implements Localisation {
  const GeolocatorLocalisation();

  @override
  Future<LatLng> positionActuelle() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocalisationException('Activez la localisation (GPS) du téléphone puis réessayez.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocalisationException('Autorisez DarImmo à accéder à votre position pour utiliser ce bouton.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocalisationException(
          'Accès à la position refusé. Autorisez-le dans Paramètres > Applications > DarImmo > Autorisations.');
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      throw const LocalisationException('Position introuvable. Placez-vous à l’extérieur ou cherchez l’adresse.');
    }
  }
}
