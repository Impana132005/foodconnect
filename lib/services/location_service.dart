import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  // Request permission and get current location
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  // Open maps intent to navigate to coordinates
  Future<bool> openMapDirections(double destLat, double destLng) async {
    // 1. Try standard Android geo URI (opens native Google Maps or preferred maps app)
    final geoUri = Uri.parse('geo:$destLat,$destLng?q=$destLat,$destLng');
    try {
      if (await canLaunchUrl(geoUri)) {
        final success = await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
        if (success) return true;
      }
    } catch (_) {}

    // 2. Try Google Maps Universal Web / App Link
    final googleMapsWebUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$destLat,$destLng',
    );
    try {
      final success = await launchUrl(
        googleMapsWebUri,
        mode: LaunchMode.externalApplication,
      );
      if (success) return true;
    } catch (_) {}

    // 3. Platform default fallback
    try {
      return await launchUrl(
        googleMapsWebUri,
        mode: LaunchMode.platformDefault,
      );
    } catch (_) {
      return false;
    }
  }

  // Calculate approximate distance between two points in km
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    return distanceInMeters / 1000.0;
  }
}
