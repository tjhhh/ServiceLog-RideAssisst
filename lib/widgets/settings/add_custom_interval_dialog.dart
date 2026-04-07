import 'package:flutter/material.dart';
import '../../models/service_interval.dart';

class AddCustomIntervalDialog extends StatefulWidget {
  final String motorcycleId;
  final Function(ServiceInterval) onAdd;

  const AddCustomIntervalDialog({
    super.key,
    required this.motorcycleId,
    required this.onAdd,
  });

  @override
  State<AddCustomIntervalDialog> createState() =>
      _AddCustomIntervalDialogState();
}

class _AddCustomIntervalDialogState extends State<AddCustomIntervalDialog> {
  final _formKey = GlobalKey<FormState>();
  String _serviceItem = '';
  int _intervalKm = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Service'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify a new service part or type unique to your motorcycle.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Service Name (e.g. Racing Roller)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a service name';
                }
                return null;
              },
              onSaved: (value) => _serviceItem = value!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Interval (Km)',
                border: OutlineInputBorder(),
                suffixText: 'Km',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter interval';
                }
                if (int.tryParse(value) == null) {
                  return 'Must be a valid number';
                }
                return null;
              },
              onSaved: (value) => _intervalKm = int.parse(value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.onAdd(
                ServiceInterval(
                  motorcycleId: widget.motorcycleId,
                  serviceItem: _serviceItem,
                  intervalKm: _intervalKm,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add Service'),
        ),
      ],
    );
  }
}
