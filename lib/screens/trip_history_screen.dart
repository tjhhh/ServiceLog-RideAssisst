import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/trip_provider.dart';
import '../models/trip_record.dart';
import '../models/motorcycle.dart';

class TripHistoryScreen extends ConsumerStatefulWidget {
  final Motorcycle? filterMotorcycle; // null = show all

  const TripHistoryScreen({super.key, this.filterMotorcycle});

  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.filterMotorcycle != null) {
        ref
            .read(tripProvider.notifier)
            .loadByMotorcycle(widget.filterMotorcycle!.id!);
      } else {
        ref.read(tripProvider.notifier).loadAll();
      }
    });
  }

  String _formatDate(DateTime d) =>
      DateFormat('dd MMM yyyy • HH:mm').format(d.toLocal());

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h}j ${m}m' : '${m}m ${s}d';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toInt()} m';
    return '${(meters / 1000).toStringAsFixed(2)} KM';
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripProvider);
    final filtered = widget.filterMotorcycle == null
        ? trips
        : trips
            .where((t) => t.motorcycleId == widget.filterMotorcycle!.id)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Perjalanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            if (widget.filterMotorcycle != null)
              Text(
                widget.filterMotorcycle!.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: filtered.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // ── Summary banner ──
                if (filtered.isNotEmpty) _buildSummaryBanner(filtered),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _TripCard(
                          trip: filtered[index],
                          formatDate: _formatDate,
                          formatDuration: _formatDuration,
                          formatDistance: _formatDistance,
                          onDelete: () => _confirmDelete(filtered[index]),
                        ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryBanner(List<TripRecord> trips) {
    final totalKm = trips.fold(0.0, (s, t) => s + t.totalDistanceMeters) / 1000;
    final totalDurSec = trips.fold(0, (s, t) => s + t.durationSeconds);
    final avgSpeed = trips.isNotEmpty
        ? trips.fold(0.0, (s, t) => s + t.avgSpeedKmh) / trips.length
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBannerStat('${trips.length}', 'Perjalanan',
              Icons.route_outlined),
          _buildBannerStat(totalKm.toStringAsFixed(1), 'Total KM',
              Icons.straighten),
          _buildBannerStat(_formatDuration(totalDurSec), 'Total Waktu',
              Icons.timer_outlined),
          _buildBannerStat('${avgSpeed.toStringAsFixed(1)}', 'Avg km/h',
              Icons.speed),
        ],
      ),
    );
  }

  Widget _buildBannerStat(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.route_outlined,
                size: 56, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada perjalanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mulai Auto Track untuk merekam\nperjalanan pertama kamu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(TripRecord trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Perjalanan'),
        content:
            const Text('Perjalanan ini akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok == true && trip.id != null) {
      await ref.read(tripProvider.notifier).deleteTrip(trip.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perjalanan dihapus.')),
        );
      }
    }
  }
}

// ─── Trip Card ────────────────────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final TripRecord trip;
  final String Function(DateTime) formatDate;
  final String Function(int) formatDuration;
  final String Function(double) formatDistance;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.formatDate,
    required this.formatDuration,
    required this.formatDistance,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onLongPress: onDelete,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.route_outlined,
                          color: primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDate(trip.startTime),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Selesai ${formatDate(trip.endTime)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Distance badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        formatDistance(trip.totalDistanceMeters),
                        style: TextStyle(
                          color: primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // ── Stats row ──
                Row(
                  children: [
                    _buildStat(Icons.timer_outlined,
                        formatDuration(trip.durationSeconds), 'Durasi'),
                    const _Divider(),
                    _buildStat(Icons.speed,
                        '${trip.avgSpeedKmh.toStringAsFixed(1)} km/h',
                        'Rata-rata'),
                  ],
                ),

                const SizedBox(height: 8),
                const Text(
                  'Tahan lama untuk hapus perjalanan ini',
                  style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: const Color(0xFFF1F5F9),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
