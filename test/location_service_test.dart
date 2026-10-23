import 'package:flutter_test/flutter_test.dart';
import 'package:foodconnect/services/location_service.dart';

void main() {
  group('LocationService.calculateDistance', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    test('returns 0 for identical coordinates', () {
      final distance = locationService.calculateDistance(
        28.6139,
        77.2090, // Delhi
        28.6139,
        77.2090, // Delhi (same)
      );
      expect(distance, closeTo(0.0, 0.001));
    });

    test('calculates known distance between Delhi and Mumbai (~1150 km)', () {
      final distance = locationService.calculateDistance(
        28.6139,
        77.2090, // Delhi
        19.0760,
        72.8777, // Mumbai
      );
      // Approximate great-circle distance is ~1150 km
      expect(distance, greaterThan(1000.0));
      expect(distance, lessThan(1300.0));
    });

    test('calculates short distance correctly (~1 km)', () {
      // Two points ~1 km apart in Bangalore
      final distance = locationService.calculateDistance(
        12.9716,
        77.5946, // MG Road
        12.9796,
        77.5946, // ~900m north
      );
      expect(distance, greaterThan(0.5));
      expect(distance, lessThan(2.0));
    });

    test('is symmetric (A→B == B→A)', () {
      final ab = locationService.calculateDistance(
        28.6139,
        77.2090, // Delhi
        19.0760,
        72.8777, // Mumbai
      );
      final ba = locationService.calculateDistance(
        19.0760,
        72.8777, // Mumbai
        28.6139,
        77.2090, // Delhi
      );
      expect(ab, closeTo(ba, 0.001));
    });

    test('returns result in kilometers', () {
      // Distance from Equator (0,0) to (0,1) ≈ 111 km
      final distance = locationService.calculateDistance(0.0, 0.0, 0.0, 1.0);
      expect(distance, greaterThan(100.0));
      expect(distance, lessThan(120.0));
    });
  });
}
