import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/motorcycle.dart';
import '../providers/motorcycle_provider.dart';

class AddMotorcycleScreen extends ConsumerStatefulWidget {
  const AddMotorcycleScreen({super.key});

  @override
  ConsumerState<AddMotorcycleScreen> createState() =>
      _AddMotorcycleScreenState();
}

class _AddMotorcycleScreenState extends ConsumerState<AddMotorcycleScreen> {
  final _brandController = TextEditingController();
  final _nameController = TextEditingController();
  final _odometerController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _brandController.dispose();
    _nameController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
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
    if (_brandController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _odometerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String imageUrl =
        'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=800&auto=format&fit=crop'; // Default placeholder
    if (_selectedImage != null) {
      final savedPath = await _saveImageLocally(_selectedImage!);
      if (savedPath != null) {
        imageUrl = savedPath;
      }
    }

    final newMotorcycle = Motorcycle(
      brand: _brandController.text.trim(),
      name: _nameController.text.trim(),
      imageUrl: imageUrl,
      odometer: int.tryParse(_odometerController.text.trim()) ?? 0,
      healthPercentage: 100, // Default for new
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
          : SingleChildScrollView(
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
                    label: 'Brand / Make',
                    hintText: 'e.g. Honda, Yamaha, Kawasaki',
                    controller: _brandController,
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    label: 'Model / Name',
                    hintText: 'e.g. CB650R, MT-07',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    label: 'Current Odometer (KM)',
                    hintText: 'e.g. 1500',
                    controller: _odometerController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveMotorcycle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
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
