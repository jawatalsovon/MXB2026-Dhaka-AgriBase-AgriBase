import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationProvider extends ChangeNotifier {
  double? _latitude;
  double? _longitude;
  String? _status;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get status => _status;
  String? _districtName;
  String? get districtName => _districtName;

  // Fallback: Nagarpur (Tangail) approximate
  static const double fallbackLat = 24.0833;
  static const double fallbackLon = 89.9167;

  Future<void> requestLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _status = 'Location services disabled. Using fallback.';
        _latitude = fallbackLat;
        _longitude = fallbackLon;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _status = 'Permission denied. Using fallback.';
        _latitude = fallbackLat;
        _longitude = fallbackLon;
        notifyListeners();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      _status = 'ok';
      // Attempt to resolve a human-readable district name for UI
      await _fetchDistrictName();
      notifyListeners();
    } catch (e) {
      _status = 'Error getting location: $e';
      _latitude = fallbackLat;
      _longitude = fallbackLon;
      _districtName = 'Nāgarpur';
      notifyListeners();
    }
  }

  Future<void> _fetchDistrictName() async {
    try {
      if (_latitude == null || _longitude == null) return;
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$_latitude&lon=$_longitude&zoom=10&addressdetails=1',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final addr = json['address'] as Map<String, dynamic>?;
        String? district;
        if (addr != null) {
          // Try multiple field names for district-level administrative divisions
          // Bangladesh and other regions use different OSM tagging
          district =
              addr['district'] as String? ??
              addr['county'] as String? ??
              addr['city'] as String? ??
              addr['state_district'] as String? ??
              addr['administrative'] as String?;
        }
        _districtName = district ?? 'Location';
      } else {
        _districtName = 'Location';
      }
    } catch (_) {
      _districtName = 'Location';
    }
    notifyListeners();
  }
}
