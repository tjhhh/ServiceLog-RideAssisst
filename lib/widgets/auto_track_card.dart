import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tracking_provider.dart';
import '../providers/motorcycle_provider.dart';
import '../providers/trip_provider.dart';
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
  bool _isStopping = false; // guard double-tap race condition

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Info / Start dialog ───────────────────────────────────────────────────
  void _showInfoDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoRow('📍',
                  'Menggunakan GPS HP, akurasi mungkin sedikit berbeda dengan speedometer karena sinyal.'),
              const SizedBox(height: 14),
              _buildInfoRow('🏍️',
                  'Jarak tetap terhitung walaupun fitur ini menyala saat kamu naik mobil/kendaraan lain.'),
              const SizedBox(height: 14),
              _buildInfoRow('⚡',
                  'Kecepatan di atas 120 km/h dan jarak < 5 meter secara otomatis difilter untuk akurasi.'),
              const SizedBox(height: 14),
              _buildInfoRow('🛑',
                  'Wajib tekan tombol Selesai setelah kamu sampai di tujuan!'),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Stop + Save ───────────────────────────────────────────────────────────
  Future<void> _stopTrackingAndSave() async {
    // Guard: abaikan tap berikutnya sampai proses selesai
    if (_isStopping) return;
    if (mounted) setState(() => _isStopping = true);

    _pulseController.stop();
    _pulseController.reset();

    // Capture current state BEFORE stopping
    final distanceMeters =
        ref.read(trackingProvider).trackedDistanceMeters;
    final kmAdded = (distanceMeters / 1000).round();

    // Stops GPS, saves trip record, returns the saved TripRecord
    final savedTrip =
        await ref.read(trackingProvider.notifier).stopTracking();

    // Reload trip list if we have the provider
    if (savedTrip != null) {
      ref.invalidate(tripProvider);
    }

    // Update odometer if ≥ 1 km
    if (kmAdded > 0) {
      final updatedMotor = widget.activeMotor.copyWith(
        odometer: widget.activeMotor.odometer + kmAdded,
      );
      await ref.read(motorcycleProvider.notifier).updateMotorcycle(updatedMotor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Perjalanan $kmAdded KM telah ditambah ke Odometer!${savedTrip != null ? ' Trip tersimpan.' : ''}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Jarak terlalu dekat (< 1 KM), odometer tidak ditambah.'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    if (mounted) setState(() => _isStopping = false);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toInt()} m';
    return '${(meters / 1000).toStringAsFixed(2)} KM';
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final isTrackingOtherMotor = trackingState.isTracking &&
        trackingState.activeMotorId != widget.activeMotor.id;

    // ── Locked state (tracking another motor) ──
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

    // ── Active tracking state ──
    if (trackingState.isTracking) {
      // Sync pulse animation
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }

      final isMoving = trackingState.status == TrackingStatus.moving;
      final statusColor = isMoving ? Colors.green : Colors.orange;
      final statusLabel = isMoving ? 'Bergerak' : 'Berhenti';
      final statusIcon = isMoving ? Icons.directions_bike : Icons.pause_circle;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B),
              const Color(0xFF0F172A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background glow effect
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.withOpacity(0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ──
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.gps_fixed,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AUTO TRACK AKTIF',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withOpacity(0.4), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Main distance display ──
                  Text(
                    _formatDistance(trackingState.trackedDistanceMeters),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'jarak terdeteksi',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),

                  const SizedBox(height: 20),

                  // ── Stats row ──
                  Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.timer_outlined,
                        label: 'Durasi',
                        value: _formatDuration(trackingState.elapsed),
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        icon: Icons.speed,
                        label: 'Kecepatan',
                        value:
                            '${trackingState.currentSpeedKmh.toStringAsFixed(1)} km/h',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Stop button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isStopping ? null : _stopTrackingAndSave,
                      icon: _isStopping
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            )
                          : const Icon(Icons.stop_circle_outlined, size: 20),
                      label: Text(_isStopping ? 'Menyimpan...' : 'Selesai & Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Idle / Start state ──
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

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white54, size: 13),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
