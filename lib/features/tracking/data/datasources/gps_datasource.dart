import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location_point.dart';

/// DataSource para GPS
///
/// EXPLICACIÓN DIDÁCTICA:
/// - Combina MethodChannel (operaciones puntuales)
/// - Con EventChannel (stream de ubicaciones)
abstract class GpsDataSource {
  Future<LocationPoint?> getCurrentLocation();
  Stream<LocationPoint> get locationStream;
  Future<bool> isGpsEnabled();
  Future<bool> requestPermissions();
}

class GpsDataSourceImpl implements GpsDataSource {
  @override
  Future<bool> isGpsEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> requestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<LocationPoint?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationPoint.fromPosition(position);
    } catch (e) {
      print('GpsDataSource.getCurrentLocation error: $e');
      return null;
    }
  }

  @override
  Stream<LocationPoint> get locationStream {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // metros mínimos entre actualizaciones
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) => LocationPoint.fromPosition(position));
  }
}
