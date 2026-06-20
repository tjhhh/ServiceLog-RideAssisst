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
    final themeColor = Theme.of(context).colorScheme.primary;

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
            fontWeight: FontWeight.w500,
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
              itemBuilder: (context) {
                final isAllSelected = selectedMotorcycleId == null;
                return [
                  PopupMenuItem<String>(
                    value: '-1',
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.all_inclusive_rounded,
                            color: isAllSelected
                                ? themeColor
                                : Colors.grey.shade500,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'All Motors',
                              style: TextStyle(
                                color: isAllSelected
                                    ? themeColor
                                    : Colors.black87,
                                fontWeight: isAllSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isAllSelected)
                            Icon(
                              Icons.check_circle,
                              color: themeColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                  ...motorcycles.map((motor) {
                    final isSelected = motor.id == selectedMotorcycleId;
                    return PopupMenuItem<String>(
                      value: motor.id ?? '-1',
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.two_wheeler_outlined,
                              color: isSelected
                                  ? themeColor
                                  : Colors.grey.shade500,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${motor.brand} ${motor.name}',
                                style: TextStyle(
                                  color: isSelected
                                      ? themeColor
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: themeColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ];
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedMotorName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, color: themeColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
