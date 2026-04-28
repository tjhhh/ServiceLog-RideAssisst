import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/service_record.dart';
import '../models/motorcycle.dart';
import '../providers/service_provider.dart';
import '../providers/motorcycle_provider.dart';
import '../models/service_interval.dart';
import '../providers/service_interval_provider.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  const AddServiceScreen({super.key});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  // Input Controllers
  final _odometerController = TextEditingController();
  final _locationController =
      TextEditingController(); // Added location controller
  final _dateController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _customServiceTypeController =
      TextEditingController(); // For custom service types
  final _customIntervalController =
      TextEditingController(); // For custom intervals

  String? _odometerError;
  String? _costError;

  String? _selectedMotorcycleId;
  String? _selectedServiceType;
  int? _selectedCycle;

  // We'll no longer use _serviceTypes static list, we'll build it from provider

  DateTime? _selectedDate;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _odometerController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _customServiceTypeController.dispose();
    _customIntervalController.dispose();
    super.dispose();
  }

  void _validateOdometer(String value) {
    if (value.isEmpty) {
      setState(() => _odometerError = 'Odometer is required');
      return;
    }

    final parsed = int.tryParse(value);
    if (parsed == null) {
      setState(() => _odometerError = 'Please enter a valid number');
      return;
    }

    setState(() => _odometerError = null);
  }

  void _validateCost(String value) {
    if (value.isNotEmpty) {
      final parsed = double.tryParse(value);
      if (parsed == null) {
        setState(() => _costError = 'Please enter a valid number');
        return;
      }
    }
    setState(() => _costError = null);
  }

  // File Picker Method
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Date Picker Method
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('MM/dd/yyyy').format(pickedDate);
      });
    }
  }

  // Save File to local storage (Documents Directory)
  Future<String?> _saveImageLocally(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
      final savedImage = await image.copy('${directory.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      return null;
    }
  }

  // Core Save Logic to SQLite via Riverpod
  Future<void> _saveRecord() async {
    final effectiveServiceType = _selectedServiceType == '+ Other'
        ? _customServiceTypeController.text.trim()
        : _selectedServiceType;
    final location = _locationController.text.trim();
    final customServiceType = _customServiceTypeController.text.trim();
    final customInterval = _customIntervalController.text.trim();

    // Validate inputs
    _validateOdometer(_odometerController.text);
    _validateCost(_costController.text);

    if (_odometerError != null ||
        _costError != null ||
        _odometerController.text.isEmpty ||
        location.isEmpty ||
        _selectedDate == null ||
        _selectedServiceType == null ||
        effectiveServiceType == null ||
        effectiveServiceType.isEmpty ||
        (_selectedServiceType == '+ Other' &&
            (customServiceType.isEmpty || customInterval.isEmpty)) ||
        _selectedMotorcycleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? savedImagePath;
    if (_selectedImage != null) {
      savedImagePath = await _saveImageLocally(_selectedImage!);
    }

    final motors = ref.read(motorcycleProvider);
    final selectedMotor = motors.firstWhere(
      (m) => m.id == _selectedMotorcycleId,
      orElse: () => motors.first,
    );

    final newRecord = ServiceRecord(
      motorcycleId: _selectedMotorcycleId,
      serviceType: effectiveServiceType,
      mileage: int.tryParse(_odometerController.text) ?? 0,
      location: _locationController.text, // Add location to new record
      date: _selectedDate!,
      cost: double.tryParse(_costController.text) ?? 0.0,
      notes: _notesController.text,
      receiptImagePath: savedImagePath,
      cycle: _selectedCycle ?? selectedMotor.cycle,
    );

    // Save custom service type / interval if selected
    if (_selectedServiceType == '+ Other') {
      final intervalVal = int.tryParse(_customIntervalController.text) ?? 5000;
      final newInterval = ServiceInterval(
        motorcycleId: _selectedMotorcycleId!,
        serviceItem: effectiveServiceType,
        intervalKm: intervalVal,
      );
      await ref
          .read(serviceIntervalProvider.notifier)
          .addCustomInterval(newInterval);
    }

    // Adding record to db using Riverpod
    await ref.read(serviceRecordsProvider.notifier).addRecord(newRecord);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service record successfully saved!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final motorcycles = ref.watch(motorcycleProvider);
    final intervals = ref.watch(serviceIntervalProvider);

    // Auto-select the first motorcycle if not set yet
    if (_selectedMotorcycleId == null && motorcycles.isNotEmpty) {
      _selectedMotorcycleId = motorcycles.first.id;
      _selectedCycle = motorcycles.first.cycle;
      // Auto-fill odometer dengan data last updated motor
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_odometerController.text.isEmpty && mounted) {
          _odometerController.text = motorcycles.first.odometer.toString();
        }
        if (_selectedMotorcycleId != null) {
          ref
              .read(serviceIntervalProvider.notifier)
              .fetchIntervals(_selectedMotorcycleId!, motorcycles.first.type);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      body: _isLoading || motorcycles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildMotorcycleSelector(motorcycles),
                    const SizedBox(height: 24),
                    if (_selectedMotorcycleId != null) ...[
                      _buildCycleSelector(
                        motorcycles.firstWhere(
                          (m) => m.id == _selectedMotorcycleId,
                          orElse: () => motorcycles.first,
                        ),
                      ),
                    ],
                    _buildInputField(
                      label: 'Odometer Reading (km)',
                      hintText: 'e.g. 12450',
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      isRequired: true,
                      errorText: _odometerError,
                      onChanged: _validateOdometer,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'Location/Workshop',
                      hintText: 'e.g. Bengkel Resmi Honda',
                      controller: _locationController,
                      isRequired: true,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'Service Date',
                      hintText: 'mm/dd/yyyy',
                      icon: Icons.calendar_today_outlined,
                      controller: _dateController,
                      readOnly: true,
                      onTap: _pickDate,
                      isRequired: true,
                    ),
                    const SizedBox(height: 24),
                    _buildServiceTypeSelector(intervals),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'Total Investment (Rp)',
                      hintText: 'Rp 0',
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      errorText: _costError,
                      onChanged: _validateCost,
                    ),
                    const SizedBox(height: 24),
                    _buildNotesField(),
                    const SizedBox(height: 24),
                    _buildAttachmentSection(),
                    const SizedBox(height: 32),
                    _buildButtons(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F9FB),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.motorcycle,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'RideAssist',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Service\nRecord',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w300,
            color: Colors.black87,
            height: 1.1,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Keep your machine in peak condition. Log your latest maintenance details below.',
          style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildMotorcycleSelector(List<Motorcycle> motorcycles) {
    String selectedName = 'Select a motorcycle';
    if (_selectedMotorcycleId != null) {
      try {
        final m = motorcycles.firstWhere(
          (motor) => motor.id == _selectedMotorcycleId,
        );
        selectedName = '${m.brand} ${m.name}';
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Motorcycle', isRequired: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.indigo.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.shade50.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            initialValue: _selectedMotorcycleId,
            tooltip: 'Select a motorcycle',
            elevation: 8,
            shadowColor: Colors.black26,
            surfaceTintColor: Colors.white,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            constraints: const BoxConstraints(maxHeight: 350),
            position: PopupMenuPosition.under,
            onSelected: (value) {
              setState(() {
                _selectedMotorcycleId = value;
                _selectedServiceType = null;
                try {
                  final m = motorcycles.firstWhere(
                    (motor) => motor.id == value,
                  );
                  _odometerController.text = m.odometer.toString();
                  _selectedCycle = m.cycle;
                  _validateOdometer(_odometerController.text);

                  ref
                      .read(serviceIntervalProvider.notifier)
                      .fetchIntervals(m.id!, m.type);
                } catch (_) {}
              });
            },
            itemBuilder: (context) => motorcycles.map((motor) {
              final isSelected = motor.id == _selectedMotorcycleId;
              final name = '${motor.brand} ${motor.name}';
              return PopupMenuItem<String>(
                value: motor.id,
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
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade500,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
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
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedName,
                    style: TextStyle(
                      color: _selectedMotorcycleId == null
                          ? Colors.black54
                          : Colors.indigo.shade900,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.indigo.shade300,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    IconData? icon,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    String? errorText,
    void Function(String)? onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: errorText != null
                ? Colors.red.shade50.withOpacity(0.5)
                : Colors.indigo.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: errorText != null
                ? Border.all(color: Colors.red.shade200)
                : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            style: TextStyle(
              color: errorText != null ? Colors.red.shade900 : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: errorText != null ? Colors.red.shade300 : Colors.black38,
                fontSize: 16,
              ),
              border: InputBorder.none,
              suffixIcon: icon != null
                  ? Icon(
                      icon,
                      color: errorText != null
                          ? Colors.red.shade300
                          : Colors.grey,
                    )
                  : null,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        children: isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  Widget _buildCycleSelector(Motorcycle activeMotor) {
    if (activeMotor.cycle == 0) {
      return const SizedBox.shrink();
    }

    final List<int> cycleOptions = List.generate(
      activeMotor.cycle + 1,
      (index) => index,
    );
    final currentCycle = _selectedCycle ?? activeMotor.cycle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Cycle', isRequired: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.indigo.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.shade50.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PopupMenuButton<int>(
            initialValue: currentCycle,
            tooltip: 'Select Cycle',
            elevation: 8,
            shadowColor: Colors.black26,
            surfaceTintColor: Colors.white,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            position: PopupMenuPosition.under,
            onSelected: (val) {
              setState(() {
                _selectedCycle = val;
              });
            },
            itemBuilder: (context) => cycleOptions.map((c) {
              final isSelected = c == currentCycle;
              return PopupMenuItem<int>(
                value: c,
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
                        Icons.history,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade500,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cycle $c',
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
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
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Cycle $currentCycle',
                    style: TextStyle(
                      color: Colors.indigo.shade900,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.indigo.shade300,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maintenance Notes',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Describe the work performed or parts used...',
              hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTypeSelector(List<ServiceInterval> intervals) {
    // Generate the list of service types from intervals, and append '+ Other'
    final List<String> currentServiceTypes = [
      ...intervals.map((i) => i.serviceItem),
      '+ Other',
    ];

    // If _selectedServiceType is not in the list, default it to null
    if (_selectedServiceType != null &&
        !currentServiceTypes.contains(_selectedServiceType)) {
      _selectedServiceType = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Service Type', isRequired: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.indigo.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.shade50.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            initialValue: _selectedServiceType,
            tooltip: 'Select a service type',
            elevation: 8,
            shadowColor: Colors.black26,
            surfaceTintColor: Colors.white,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            constraints: const BoxConstraints(maxHeight: 350),
            position: PopupMenuPosition.under,
            onSelected: (value) {
              setState(() {
                _selectedServiceType = value;
              });
            },
            itemBuilder: (context) => currentServiceTypes.map((type) {
              final isSelected = type == _selectedServiceType;
              final isOther = type == '+ Other';
              return PopupMenuItem<String>(
                value: type,
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
                        isOther
                            ? Icons.add_circle_outline
                            : Icons.build_circle_outlined,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade500,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
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
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedServiceType ?? 'Select Service Type',
                    style: TextStyle(
                      color: _selectedServiceType == null
                          ? Colors.black54
                          : Colors.indigo.shade900,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.indigo.shade300,
                ),
              ],
            ),
          ),
        ),
        if (_selectedServiceType == '+ Other') ...[
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Custom Service Type',
            hintText: 'e.g. Ganti Spion',
            controller: _customServiceTypeController,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Service Interval (km)',
            hintText: 'e.g. 5000',
            controller: _customIntervalController,
            keyboardType: TextInputType.number,
            isRequired: true,
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentation',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: _selectedImage == null ? 32 : 12,
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: _selectedImage == null
                ? Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 32,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Attach Receipt Photo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'JPG, PNG OR PDF • MAX 10MB',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: Colors.grey,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.basename(_selectedImage!.path),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Tap to change image',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveRecord,
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: const Text(
              'Save Record',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.black54),
          child: const Text(
            'Discard Changes',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
