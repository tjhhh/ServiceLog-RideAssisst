import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../models/motorcycle.dart';
import '../models/service_interval.dart';
import '../models/service_record.dart';
import '../providers/motorcycle_provider.dart';
import '../providers/service_interval_provider.dart';
import '../providers/service_provider.dart';

class MotorcycleDetailScreen extends ConsumerStatefulWidget {
  final Motorcycle motorcycle;

  const MotorcycleDetailScreen({super.key, required this.motorcycle});

  @override
  ConsumerState<MotorcycleDetailScreen> createState() =>
      _MotorcycleDetailScreenState();
}

class _MotorcycleDetailScreenState
    extends ConsumerState<MotorcycleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.motorcycle.id != null) {
        ref
            .read(serviceIntervalProvider.notifier)
            .fetchIntervals(widget.motorcycle.id!, widget.motorcycle.type);
      }
    });
  }

  Color _getColorForRemainingKm(int remainingKm, int intervalKm) {
    if (remainingKm <= 0) return Colors.red;
    if (intervalKm <= 0) return Colors.red;

    double ratio =
        remainingKm / intervalKm; // 1.0 (baru/jauh), 0.0 (perlu servis)
    if (ratio > 1.0) ratio = 1.0;

    return Color.lerp(Colors.red, Colors.blue, ratio) ?? Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final motorcycles = ref.watch(motorcycleProvider);
    final motor = motorcycles.firstWhere(
      (m) => m.id == widget.motorcycle.id,
      orElse: () => widget.motorcycle,
    );

    final allRecords = ref.watch(serviceRecordsProvider);
    final intervals = ref.watch(serviceIntervalProvider);

    final motorRecords = allRecords
        .where((r) => r.motorcycleId == motor.id)
        .toList();

    ImageProvider imageProvider;
    if (motor.imageUrl.startsWith('http')) {
      imageProvider = NetworkImage(motor.imageUrl);
    } else {
      imageProvider = FileImage(File(motor.imageUrl));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('${motor.brand} ${motor.name}'),
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image & Info
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      motor.brand,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      motor.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildDetailChip(Icons.speed, '${motor.odometer} KM'),
                        const SizedBox(width: 12),
                        _buildDetailChip(
                          Icons.two_wheeler,
                          motor.type.toUpperCase(),
                        ),
                        const SizedBox(width: 12),
                        _buildDetailChip(
                          Icons.health_and_safety,
                          motor.healthStatus,
                          color: _getHealthColor(motor.healthPercentage),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Odometer Update Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.speed,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Odometer',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${motor.odometer} KM',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            _showUpdateOdometerDialog(context, motor),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('UPDATE'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Service Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _confirmResetAllServices(context, intervals, motor),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset All'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            if (intervals.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: intervals.length,
                itemBuilder: (context, index) {
                  final interval = intervals[index];

                  // Get specific records for this interval
                  final specificRecords = motorRecords
                      .where(
                        (r) =>
                            r.serviceType.toLowerCase() ==
                            interval.serviceItem.toLowerCase(),
                      )
                      .toList();
                  specificRecords.sort(
                    (a, b) => b.mileage.compareTo(a.mileage),
                  );

                  int lastServiceMileage = 0;
                  DateTime? lastServiceDate;
                  if (specificRecords.isNotEmpty) {
                    lastServiceMileage = specificRecords.first.mileage;
                    lastServiceDate = specificRecords.first.date;
                  }

                  int kmSinceLastService = motor.odometer - lastServiceMileage;
                  if (lastServiceMileage == 0 && motor.odometer > 0) {
                    kmSinceLastService = motor.odometer;
                  }
                  if (kmSinceLastService < 0) kmSinceLastService = 0;

                  int remainingKm = interval.intervalKm - kmSinceLastService;

                  Color itemColor = _getColorForRemainingKm(
                    remainingKm,
                    interval.intervalKm,
                  );

                  double progressValue = remainingKm > 0
                      ? (remainingKm / interval.intervalKm)
                      : 0.0;
                  if (progressValue > 1.0) progressValue = 1.0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100, width: 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      title: Text(
                        interval.serviceItem,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            remainingKm > 0
                                ? 'Remaining: $remainingKm KM'
                                : 'Overdue by: ${remainingKm.abs()} KM',
                            style: TextStyle(
                              color: itemColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Last Replaced: $lastServiceMileage KM',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (lastServiceDate != null)
                                Text(
                                  '${lastServiceDate.day.toString().padLeft(2, '0')}/${lastServiceDate.month.toString().padLeft(2, '0')}/${lastServiceDate.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: Colors.grey.shade200,
                              color: itemColor,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Interval: ${interval.intervalKm} KM',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.refresh_rounded, color: itemColor),
                        onPressed: () =>
                            _confirmResetService(context, interval, motor),
                        tooltip: 'Reset Service',
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color ?? Colors.white.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(int percentage) {
    if (percentage <= 20) return Colors.deepOrange;
    if (percentage <= 50) return Colors.orange;
    if (percentage <= 80) return Colors.blue;
    return Colors.green;
  }

  Future<void> _showUpdateOdometerDialog(
    BuildContext context,
    Motorcycle motor,
  ) async {
    final TextEditingController odometerController = TextEditingController(
      text: motor.odometer.toString(),
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Odometer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update the current mileage of your motorcycle:'),
              const SizedBox(height: 16),
              TextField(
                controller: odometerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Odometer',
                  border: OutlineInputBorder(),
                  suffixText: 'KM',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final newOdo = int.tryParse(odometerController.text);
                if (newOdo != null && newOdo >= motor.odometer) {
                  final updatedMotor = motor.copyWith(odometer: newOdo);
                  ref
                      .read(motorcycleProvider.notifier)
                      .updateMotorcycle(updatedMotor);
                  Navigator.pop(context);

                  // Also update our state reference if using widget.motorcycle
                  // Normally riverpod handles this if we watch it or we can just pop the route or let the UI handle it since we are reading from provider, but wait - the widget.motorcycle might be stale.
                  // We should ideally read the motorcycle from provider in build.
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Invalid odometer reading. Must be greater than or equal to current.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('UPDATE ODOMETER'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmResetService(
    BuildContext context,
    ServiceInterval interval,
    Motorcycle motor,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Service Interval?'),
        content: Text(
          'Are you sure you have completed "${interval.serviceItem}" at ${motor.odometer} KM? This will record a new service log.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('CONFIRM', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final newRecord = ServiceRecord(
        motorcycleId: motor.id,
        serviceType: interval.serviceItem,
        mileage: motor.odometer,
        date: DateTime.now(),
        cost: 0.0,
        notes: 'Recorded via interval reset',
      );

      await ref.read(serviceRecordsProvider.notifier).addRecord(newRecord);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${interval.serviceItem} has been reset at ${motor.odometer} KM',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmResetAllServices(
    BuildContext context,
    List<ServiceInterval> intervals,
    Motorcycle motor,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Services?'),
        content: Text(
          'Are you sure you want to reset all service intervals at ${motor.odometer} KM? This will record new service logs for all items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('CONFIRM', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final interval in intervals) {
        final newRecord = ServiceRecord(
          motorcycleId: motor.id,
          serviceType: interval.serviceItem,
          mileage: motor.odometer,
          date: DateTime.now(),
          cost: 0.0,
          notes: 'Recorded via interval reset',
        );
        await ref.read(serviceRecordsProvider.notifier).addRecord(newRecord);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All services have been reset at ${motor.odometer} KM',
            ),
          ),
        );
      }
    }
  }
}
