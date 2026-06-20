import '../models/motorcycle.dart';
import '../models/service_interval.dart';
import '../models/service_record.dart';
import '../models/trip_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_service.dart';

abstract class FirestoreRepository {
  Future<List<Motorcycle>> getAllMotorcycles();
  Future<String> insertMotorcycle(Motorcycle motor);
  Future<void> updateMotorcycle(Motorcycle motor);
  Future<void> deleteMotorcycle(String id);
  Future<List<ServiceRecord>> getAllServiceRecords();
  Future<String> insertServiceRecord(ServiceRecord record);
  Future<void> updateServiceRecord(ServiceRecord record);
  Future<void> deleteServiceRecord(String id);
  Future<List<ServiceInterval>> getServiceIntervalsByMotorcycle(
    String motorcycleId,
  );
  Future<String> insertServiceInterval(ServiceInterval interval);
  Future<void> updateServiceInterval(ServiceInterval interval);
  Future<void> deleteServiceInterval(String id);
  Future<List<TripRecord>> getAllTripRecords();
  Future<List<TripRecord>> getTripRecordsByMotorcycle(String motorcycleId);
  Future<String> insertTripRecord(TripRecord trip);
  Future<void> deleteTripRecord(String id);
}

class FirestoreServiceRepository implements FirestoreRepository {
  final FirestoreService _service;

  FirestoreServiceRepository([FirestoreService? service])
    : _service = service ?? FirestoreService.instance;

  @override
  Future<List<Motorcycle>> getAllMotorcycles() => _service.getAllMotorcycles();

  @override
  Future<String> insertMotorcycle(Motorcycle motor) =>
      _service.insertMotorcycle(motor);

  @override
  Future<void> updateMotorcycle(Motorcycle motor) =>
      _service.updateMotorcycle(motor);

  @override
  Future<void> deleteMotorcycle(String id) => _service.deleteMotorcycle(id);

  @override
  Future<List<ServiceRecord>> getAllServiceRecords() =>
      _service.getAllServiceRecords();

  @override
  Future<String> insertServiceRecord(ServiceRecord record) =>
      _service.insertServiceRecord(record);

  @override
  Future<void> updateServiceRecord(ServiceRecord record) =>
      _service.updateServiceRecord(record);

  @override
  Future<void> deleteServiceRecord(String id) =>
      _service.deleteServiceRecord(id);

  @override
  Future<List<ServiceInterval>> getServiceIntervalsByMotorcycle(
    String motorcycleId,
  ) => _service.getServiceIntervalsByMotorcycle(motorcycleId);

  @override
  Future<String> insertServiceInterval(ServiceInterval interval) =>
      _service.insertServiceInterval(interval);

  @override
  Future<void> updateServiceInterval(ServiceInterval interval) =>
      _service.updateServiceInterval(interval);

  @override
  Future<void> deleteServiceInterval(String id) =>
      _service.deleteServiceInterval(id);

  @override
  Future<List<TripRecord>> getAllTripRecords() => _service.getAllTripRecords();

  @override
  Future<List<TripRecord>> getTripRecordsByMotorcycle(String motorcycleId) =>
      _service.getTripRecordsByMotorcycle(motorcycleId);

  @override
  Future<String> insertTripRecord(TripRecord trip) =>
      _service.insertTripRecord(trip);

  @override
  Future<void> deleteTripRecord(String id) => _service.deleteTripRecord(id);
}

final firestoreRepositoryProvider = Provider<FirestoreRepository>(
  (ref) => FirestoreServiceRepository(),
);
