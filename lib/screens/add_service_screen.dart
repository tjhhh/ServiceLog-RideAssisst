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

  String? _selectedMotorcycleId;
  String? _selectedServiceType;
  final List<String> _serviceTypes = [
    '+ Other',
    'Oli Mesin',
    'Oli Gardan',
    'Servis Ringan / Tune Up',
    'Servis CVT',
    'Ganti V-Belt & Roller',
    'Ganti Kampas Ganda & Mangkok',
    'Ganti Busi',
    'Ganti Filter Udara',
    'Ganti Kampas Rem',
    'Ganti Air Radiator',
    'Ganti Minyak Rem',
    'Ganti Oli Shockbreaker',
    'Stel & Lumasi Rantai',
    'Ganti Gear Set',
    'Ganti Kampas Kopling',
  ];

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
    super.dispose();
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

    if (_odometerController.text.isEmpty ||
        _selectedDate == null ||
        effectiveServiceType == null ||
        effectiveServiceType.isEmpty ||
        _selectedMotorcycleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please field all required fields (Motorcycle, Service Type, Odometer, and Date)!',
          ),
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

    final newRecord = ServiceRecord(
      motorcycleId: _selectedMotorcycleId,
      serviceType: effectiveServiceType,
      mileage: int.tryParse(_odometerController.text) ?? 0,
      location: _locationController.text, // Add location to new record
      date: _selectedDate!,
      cost: double.tryParse(_costController.text) ?? 0.0,
      notes: _notesController.text,
      receiptImagePath: savedImagePath,
    );

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

    // Auto-select the first motorcycle if not set yet
    if (_selectedMotorcycleId == null && motorcycles.isNotEmpty) {
      _selectedMotorcycleId = motorcycles.first.id;
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
                    _buildInputField(
                      label: 'Odometer Reading (km)',
                      hintText: 'e.g. 12450',
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'Location/Workshop',
                      hintText: 'e.g. Bengkel Resmi Honda',
                      controller: _locationController,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'Service Date',
                      hintText: 'mm/dd/yyyy',
                      icon: Icons.calendar_today_outlined,
                      controller: _dateController,
                      readOnly: true,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 24),
                    _buildServiceTypeSelector(),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'Total Investment (Rp)',
                      hintText: 'Rp 0',
                      controller: _costController,
                      keyboardType: TextInputType.number,
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
        const Text(
          'Motorcycle',
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 16),
              border: InputBorder.none,
              suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            ),
          ),
        ),
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

  Widget _buildServiceTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Type',
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
            itemBuilder: (context) => _serviceTypes.map((type) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _customServiceTypeController,
              decoration: const InputDecoration(
                hintText: 'Enter custom service type...',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
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
