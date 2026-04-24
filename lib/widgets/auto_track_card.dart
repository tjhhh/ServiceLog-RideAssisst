import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tracking_provider.dart';
import '../providers/motorcycle_provider.dart';
import '../models/motorcycle.dart';

class AutoTrackCard extends ConsumerStatefulWidget {
  final Motorcycle activeMotor;

  const AutoTrackCard({super.key, required this.activeMotor});

  @override
  ConsumerState<AutoTrackCard> createState() => _AutoTrackCardState();
}

class _AutoTrackCardState extends ConsumerState<AutoTrackCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Catatan Penting Auto Track',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                  '📍', 'Menggunakan GPS HP, akurasi mungkin sedikit berbeda dengan speedometer karena sinyal.'),
              const SizedBox(height: 16),
              _buildInfoRow(
                  '🏍️', 'Jarak tetap terhitung walaupun fitur ini menyala saat kamu naik mobil/kendaraan lain.'),
              const SizedBox(height: 16),
              _buildInfoRow(
                  '🛑', 'Wajib tekan tombol Selesai setelah kamu sampai di tujuan!'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final errorMsg = await ref
                        .read(trackingProvider.notifier)
                        .startTracking(widget.activeMotor.id!);
                    if (errorMsg == null) {
                      _pulseController.repeat(reverse: true);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMsg),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Mengerti, Mulai Track',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _stopTrackingAndSave(WidgetRef ref, double distanceMeters) async {
    _pulseController.stop();

    // convert to string and back to int effectively flooring/rounding
    double km = distanceMeters / 1000;
    int kmAdded = km.round();

    if (kmAdded > 0) {
      final updatedMotor = widget.activeMotor.copyWith(
        odometer: widget.activeMotor.odometer + kmAdded,
      );
      
      // Update state immediately if needed, or rely on db refresh
      await ref.read(motorcycleProvider.notifier).updateMotorcycle(updatedMotor);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil, perjalanan $kmAdded KM telah ditambah ke Odometer!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jarak terlalu dekat (di bawah 1 KM), odometer tidak ditambah.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    
    ref.read(trackingProvider.notifier).stopTracking();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);

    // If tracking is active on another motor, don't show or disable it
    final isTrackingOtherMotor = trackingState.isTracking &&
        trackingState.activeMotorId != widget.activeMotor.id;

    if (isTrackingOtherMotor) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Auto Track sedang aktif di motor lain.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    if (trackingState.isTracking) {
      double km = trackingState.trackedDistanceMeters / 1000;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.indigo.shade200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sedang Melacak...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    Text(
                      trackingState.trackedDistanceMeters < 1000 
                          ? '${trackingState.trackedDistanceMeters.toInt()} Meter'
                          : '${km.toStringAsFixed(1)} KM',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _stopTrackingAndSave(ref, trackingState.trackedDistanceMeters),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Selesai'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      child: InkWell(
        onTap: () => _showInfoDialog(context, ref),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.gps_fixed, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai Auto Track',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Update odometer via GPS otomatis',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
