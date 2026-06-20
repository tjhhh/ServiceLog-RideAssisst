import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/motorcycle.dart';
import '../providers/motorcycle_provider.dart';

class AddMotorcycleScreen extends ConsumerStatefulWidget {
  const AddMotorcycleScreen({super.key});

  @override
  ConsumerState<AddMotorcycleScreen> createState() =>
      _AddMotorcycleScreenState();
}

class _AddMotorcycleScreenState extends ConsumerState<AddMotorcycleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _nameController = TextEditingController();
  final _odometerController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _yearController = TextEditingController();

  String _selectedType = 'matic';
  final List<String> _motorTypes = ['matic', 'bebek', 'sport'];

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _brandController.dispose();
    _nameController.dispose();
    _odometerController.dispose();
    _licensePlateController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo Motor',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Photo Motor',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
      }
    }
  }

  Future<String?> _saveImageLocally(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'motor_${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
      final savedImage = await image.copy('${directory.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveMotorcycle() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String imageUrl =
        'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=800&auto=format&fit=crop';
    if (_selectedImage != null) {
      final savedPath = await _saveImageLocally(_selectedImage!);
      if (savedPath != null) {
        imageUrl = savedPath;
      }
    }

    final newMotorcycle = Motorcycle(
      brand: _brandController.text.trim(),
      name: _nameController.text.trim(),
      type: _selectedType,
      licensePlate: _licensePlateController.text.trim().isNotEmpty
          ? _normalizeLicensePlate(_licensePlateController.text)
          : null,
      year: _yearController.text.trim().isEmpty
          ? null
          : int.parse(_yearController.text.trim()),
      imageUrl: imageUrl,
      odometer: int.parse(_odometerController.text.trim()),
      healthPercentage: 100,
      healthStatus: 'OPTIMAL',
      nextService: 'General Inspection',
    );

    await ref.read(motorcycleProvider.notifier).addMotorcycle(newMotorcycle);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Motorcycle successfully added!')),
      );
      Navigator.pop(context);
    }
  }

  String? _validateOdometer(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return 'Current odometer wajib diisi';
    }

    if (!RegExp(r'^\d+$').hasMatch(trimmedValue)) {
      return 'Current odometer hanya boleh berisi angka';
    }

    return null;
  }

  String? _validateLicensePlate(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return null;
    }

    final normalizedValue = _normalizeLicensePlate(trimmedValue);
    if (!RegExp(r'^[A-Z]{1,2} \d{1,4} [A-Z]{2,3}$').hasMatch(normalizedValue)) {
      return 'Format plat: H 1234 ABC / HH 1 AB / HH 123 ABC';
    }

    return null;
  }

  String? _validateYear(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return null;
    }

    if (!RegExp(r'^\d+$').hasMatch(trimmedValue)) {
      return 'Year hanya boleh berisi angka';
    }

    return null;
  }

  String _normalizeLicensePlate(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Motorcycle',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.indigo.shade200,
                              width: 2,
                            ),
                            image: _selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _selectedImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Add Photo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInputField(
                      label: 'Brand',
                      hintText: 'e.g. Honda, Yamaha, Kawasaki',
                      controller: _brandController,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'Model',
                      hintText: 'e.g. CB650R, MT-07',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 24),
                    _buildTypeDropdown(),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'Current Odometer (KM)',
                      hintText: 'e.g. 1500',
                      controller: _odometerController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: _validateOdometer,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'License Plate (Opsional)',
                            hintText: 'e.g. B 1234 ABC',
                            controller: _licensePlateController,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9 ]'),
                              ),
                            ],
                            validator: _validateLicensePlate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            label: 'Year (Opsional)',
                            hintText: 'e.g. 2021',
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: _validateYear,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveMotorcycle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Motorcycle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Motorcycle Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              items: _motorTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type[0].toUpperCase() + type.substring(1),
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
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
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 16),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
