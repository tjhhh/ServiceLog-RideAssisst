import 'package:flutter/material.dart';
import '../../models/motorcycle.dart';

class HistoryHeader extends StatelessWidget {
  final List<Motorcycle> motorcycles;
  final String? selectedMotorcycleId;
  final ValueChanged<String?> onMotorcycleSelected;

  const HistoryHeader({
    super.key,
    required this.motorcycles,
    this.selectedMotorcycleId,
    required this.onMotorcycleSelected,
  });

  @override
  Widget build(BuildContext context) {
    String selectedMotorName = 'All Motors';
    if (selectedMotorcycleId != null) {
      try {
        final m = motorcycles.firstWhere(
          (motor) => motor.id == selectedMotorcycleId,
        );
        selectedMotorName = '${m.brand} ${m.name}';
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 4),
        const Text(
          'Service History',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: Colors.black87,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        // Dropdown untuk filter motor
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              initialValue: selectedMotorcycleId ?? '-1',
              tooltip: 'Select Motor',
              elevation: 4,
              shadowColor: Colors.black12,
              surfaceTintColor: Colors.white,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              position: PopupMenuPosition.under,
              onSelected: (value) {
                onMotorcycleSelected(value == '-1' ? null : value);
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: '-1',
                  child: Text('All Motors'),
                ),
                ...motorcycles.map((motor) {
                  return PopupMenuItem<String>(
                    value: motor.id ?? '-1',
                    child: Text('${motor.brand} ${motor.name}'),
                  );
                }),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedMotorName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.indigo),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
