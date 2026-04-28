import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../providers/motorcycle_provider.dart';
import '../providers/service_provider.dart';
import '../models/motorcycle.dart';
import 'add_motorcycle_screen.dart';
import 'motorcycle_detail_screen.dart';

class ManageScreen extends ConsumerWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motorcycles = ref.watch(motorcycleProvider);
    final allRecords = ref.watch(serviceRecordsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        title: const Text(
          'Manage Garage',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: motorcycles.isEmpty
          ? const Center(
              child: Text(
                'No motorcycles found.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: motorcycles.length,
              itemBuilder: (context, index) {
                final motor = motorcycles[index];
                final motorRecords = allRecords
                    .where((r) => r.motorcycleId == motor.id)
                    .toList();

                motorRecords.sort((a, b) => b.date.compareTo(a.date));

                ImageProvider imageProvider;
                if (motor.imageUrl.startsWith('http')) {
                  imageProvider = NetworkImage(motor.imageUrl);
                } else {
                  imageProvider = FileImage(File(motor.imageUrl));
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MotorcycleDetailScreen(motorcycle: motor),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            // Glassmorphism Bottom Panel
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: ClipRRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                motor.brand,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${motor.name} ${motor.year != null ? '(${motor.year})' : ''}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (motor.licensePlate != null &&
                                                  motor
                                                      .licensePlate!
                                                      .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      motor.licensePlate!,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              tooltip: 'Ubah foto motor',
                                              icon: const Icon(
                                                Icons.photo_library_outlined,
                                                color: Colors.white,
                                              ),
                                              onPressed: () =>
                                                  _showChangeImageSheet(
                                                    context,
                                                    ref,
                                                    motor,
                                                  ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.info_outline,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        MotorcycleDetailScreen(
                                                          motorcycle: motor,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () => _confirmDelete(
                                                context,
                                                ref,
                                                motor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMotorcycleScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Motorcycle motor,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Motorcycle?'),
        content: Text(
          'Are you sure you want to remove ${motor.brand} ${motor.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && motor.id != null) {
      await ref.read(motorcycleProvider.notifier).deleteMotorcycle(motor.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${motor.name} removed from Garage')),
        );
      }
    }
  }

  Future<void> _showChangeImageSheet(
    BuildContext context,
    WidgetRef ref,
    Motorcycle motor,
  ) async {
    File? selectedImage;
    bool isSaving = false;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final messenger = ScaffoldMessenger.of(context);

    Future<File?> pickAndCropImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return null;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo Motor',
            toolbarColor: primaryColor,
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

      return croppedFile == null ? null : File(croppedFile.path);
    }

    Future<String?> saveImageLocally(File image) async {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'motor_${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
        final savedImage = await image.copy('${directory.path}/$fileName');
        return savedImage.path;
      } catch (_) {
        return null;
      }
    }

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        ImageProvider displayImageProvider;
        if (selectedImage != null) {
          displayImageProvider = FileImage(selectedImage!);
        } else if (motor.imageUrl.startsWith('http')) {
          displayImageProvider = NetworkImage(motor.imageUrl);
        } else if (File(motor.imageUrl).existsSync()) {
          displayImageProvider = FileImage(File(motor.imageUrl));
        } else {
          displayImageProvider = const NetworkImage(
            'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?q=80&w=800&auto=format&fit=crop',
          );
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> chooseImage() async {
              final image = await pickAndCropImage();
              if (image != null) {
                setSheetState(() {
                  selectedImage = image;
                });
              }
            }

            Future<void> saveChanges() async {
              if (selectedImage == null || isSaving) return;
              setSheetState(() {
                isSaving = true;
              });

              final savedPath = await saveImageLocally(selectedImage!);
              if (!sheetContext.mounted) return;

              if (savedPath == null) {
                setSheetState(() {
                  isSaving = false;
                });
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menyimpan gambar motor.'),
                  ),
                );
                return;
              }

              await ref
                  .read(motorcycleProvider.notifier)
                  .updateMotorcycle(motor.copyWith(imageUrl: savedPath));

              if (!sheetContext.mounted) return;

              Navigator.pop(sheetContext);

              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Foto motor berhasil diperbarui.'),
                ),
              );
            }

            return SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Ubah Foto Motor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih gambar baru, lalu simpan jika sudah cocok. Perubahan hanya berlaku setelah kamu menekan Simpan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: displayImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                selectedImage == null
                                    ? 'Gambar saat ini'
                                    : 'Pratinjau gambar baru',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: isSaving ? null : chooseImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Pilih Foto Baru'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedImage == null || isSaving
                                ? null
                                : saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
