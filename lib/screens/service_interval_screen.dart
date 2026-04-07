import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/motorcycle.dart';
import '../models/service_interval.dart';
import '../providers/motorcycle_provider.dart';
import '../providers/service_interval_provider.dart';

class ServiceIntervalScreen extends ConsumerStatefulWidget {
  const ServiceIntervalScreen({super.key});

  @override
  ConsumerState<ServiceIntervalScreen> createState() =>
      _ServiceIntervalScreenState();
}

class _ServiceIntervalScreenState extends ConsumerState<ServiceIntervalScreen> {
  Motorcycle? _selectedMotor;

  // State untuk melacak perubahan form. Key: interval.id, Value: nilai km baru
  final Map<String, int> _editedValues = {};

  // State key untuk merekonstruksi form dan Dropdown ketika dibatalkan (Cancel)
  int _formResetKey = 0;

  @override
  Widget build(BuildContext context) {
    final motorcycles = ref.watch(motorcycleProvider);
    final intervals = ref.watch(serviceIntervalProvider);

    // Pastikan _selectedMotor selalu mengacu pada data yang fresh
    if (motorcycles.isNotEmpty) {
      if (_selectedMotor == null) {
        _selectedMotor = motorcycles.first;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(serviceIntervalProvider.notifier)
              .fetchIntervals(_selectedMotor!.id!, _selectedMotor!.type);
        });
      } else {
        try {
          _selectedMotor = motorcycles.firstWhere(
            (m) => m.id == _selectedMotor!.id,
          );
        } catch (e) {
          _selectedMotor = motorcycles.first;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Service Intervals',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF8F9FB),
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: motorcycles.isEmpty
          ? const Center(child: Text('No motorcycles found.'))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PILIH MOTOR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Motorcycle>(
                        value: _selectedMotor,
                        isExpanded: true,
                        items: motorcycles.map((Motorcycle motor) {
                          return DropdownMenuItem<Motorcycle>(
                            value: motor,
                            child: Text(
                              '${motor.brand} ${motor.name} (${motor.type})',
                            ),
                          );
                        }).toList(),
                        onChanged: (Motorcycle? newValue) {
                          if (newValue != null &&
                              newValue.id != _selectedMotor?.id) {
                            if (_editedValues.isNotEmpty) {
                              _showChangeMotorWarningDialog(newValue);
                            } else {
                              _switchMotor(newValue);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'FORM FIELD JENIS SERVICE (Ubah batas KM jika perlu)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: intervals.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            key: ValueKey(_formResetKey),
                            itemCount: intervals.length,
                            itemBuilder: (context, index) {
                              final interval = intervals[index];
                              return _buildIntervalField(interval);
                            },
                          ),
                  ),
                ],
              ),
            ),
      // Tombol mengambang di bawah akan muncul hanya saat _editedValues.isNotEmpty
      bottomNavigationBar: _editedValues.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showCancelDialog,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showSaveDialog,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildIntervalField(ServiceInterval interval) {
    // Dengan memisahkan Label (Text) dan Input (TextFormField) secara vertikal (Column),
    // teks tidak akan pernah tertimpa atau terpotong border warna box-nya.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            interval.serviceItem,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('${interval.id}_$_formResetKey'),
            initialValue:
                _editedValues[interval.id!]?.toString() ??
                interval.intervalKm.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: 'KM',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              final val = int.tryParse(value);
              setState(() {
                if (val != null && val != interval.intervalKm) {
                  _editedValues[interval.id!] = val; // simpan update baru
                } else {
                  _editedValues.remove(
                    interval.id,
                  ); // jika revert ke asli, buang dari list "edited"
                }
              });
            },
          ),
        ],
      ),
    );
  }

  void _switchMotor(Motorcycle newValue) {
    setState(() {
      _selectedMotor = newValue;
      _editedValues.clear();
      _formResetKey++;
    });
    ref
        .read(serviceIntervalProvider.notifier)
        .fetchIntervals(newValue.id!, newValue.type);
  }

  void _showChangeMotorWarningDialog(Motorcycle newMotor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pindah Motor?'),
        content: const Text(
          'Perubahan pada interval motor saat ini belum disimpan. Tetap pindah dan hapus perubahan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Jangan'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _switchMotor(newMotor);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Ya, Pindah',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan Perubahan?'),
        content: const Text(
          'Apakah kamu yakin ingin menyimpan perubahan interval servis ini secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveChanges();
            },
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Perubahan?'),
        content: const Text(
          'Semua perubahan yang belum disimpan akan dikembalikan ke nilai awal. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _editedValues.clear();
                _formResetKey++;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    final intervals = ref.read(serviceIntervalProvider);
    for (var interval in intervals) {
      if (_editedValues.containsKey(interval.id)) {
        final newValue = _editedValues[interval.id]!;
        final updatedInterval = interval.copyWith(intervalKm: newValue);
        ref
            .read(serviceIntervalProvider.notifier)
            .updateInterval(updatedInterval);
      }
    }

    setState(() {
      _editedValues.clear();
      _formResetKey++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan berhasil disimpan!')),
    );
  }
}
