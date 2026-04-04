import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'database_service.dart';
import '../models/order_model.dart';

class RiderService {
  final DatabaseService _db = DatabaseService();

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    } 

    return true;
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<void> updateRiderLocation(String uid, Position position) async {
    await _db.updateUserFields(uid, {
      'latitude': position.latitude,
      'longitude': position.longitude,
    });
  }

  Future<void> updateRiderAvailability(String uid, bool isAvailable) async {
    await _db.updateUserFields(uid, {
      'isAvailable': isAvailable,
    });
  }

  Stream<List<OrderModel>> getPendingJobsStream() {
    return _db.getPendingJobsStream();
  }

  Future<void> claimJob(String orderId, String riderId) async {
    await _db.claimJob(orderId, riderId);
  }
}
