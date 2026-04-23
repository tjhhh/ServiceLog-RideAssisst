import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import '../providers/service_provider.dart';
import '../providers/motorcycle_provider.dart';
import '../widgets/history/history_header.dart';
import '../widgets/history/history_summary_card.dart';
import '../widgets/history/history_timeline.dart';
import '../widgets/history/history_load_more.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String? _selectedMotorcycleId; // State untuk filter motor

  @override
  Widget build(BuildContext context) {
    final motorcycles = ref.watch(motorcycleProvider);

    // 1. Dapatkan daftar history riil dari Provider
    final allRecords = ref.watch(serviceRecordsProvider);
    final activeMotorcycleIds = motorcycles.map((m) => m.id).toSet();

    // Filter by selected motorcycle if any, and ensure we only show active ones when "All" is selected
    final records = _selectedMotorcycleId == null
        ? allRecords
              .where((r) => activeMotorcycleIds.contains(r.motorcycleId))
              .toList()
        : allRecords
              .where((r) => r.motorcycleId == _selectedMotorcycleId)
              .toList();

    // 2. Hitung Total Pengeluaran
    final totalSpent = records.fold<double>(
      0.0,
      (sum, item) => sum + item.cost,
    );
    final totalSpentText = NumberFormat.currency(
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(totalSpent);

    // 3. Kalkulasi Kapan Servis Terakhir
    String lastServiceAgo = '--';
    String lastServiceUnit = '';
    if (records.isNotEmpty) {
      final latestRecord = records.reduce(
        (a, b) => a.date.isAfter(b.date) ? a : b,
      );
      final difference = DateTime.now().difference(latestRecord.date).inDays;
      if (difference == 0) {
        lastServiceAgo = 'Today';
      } else {
        lastServiceAgo = '${difference}d';
        lastServiceUnit = 'ago';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('lib/assets/logo_ra.png', width: 24, height: 24),
            const SizedBox(width: 8),
            const Text(
              'RideAssist',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.indigo.shade100,
              backgroundImage:
                  FirebaseAuth.instance.currentUser?.photoURL != null &&
                      File(
                        FirebaseAuth.instance.currentUser!.photoURL!,
                      ).existsSync()
                  ? FileImage(
                          File(FirebaseAuth.instance.currentUser!.photoURL!),
                        )
                        as ImageProvider
                  : null,
              child:
                  (FirebaseAuth.instance.currentUser?.photoURL == null ||
                      !File(
                        FirebaseAuth.instance.currentUser!.photoURL!,
                      ).existsSync())
                  ? const Icon(Icons.person, size: 24, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  HistoryHeader(
                    motorcycles: motorcycles,
                    selectedMotorcycleId: _selectedMotorcycleId,
                    onMotorcycleSelected: (id) {
                      setState(() {
                        _selectedMotorcycleId = id;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  HistorySummaryCard(
                    totalSpent: totalSpentText,
                    lastServiceAgo: lastServiceAgo,
                    lastServiceUnit: lastServiceUnit,
                  ),
                  const SizedBox(height: 24),
                  HistoryTimeline(records: records.take(3).toList()),
                  const SizedBox(height: 100), // Spacing for FAB and Load More
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: HistoryLoadMore(),
          ),
        ],
      ),
    );
  }
}
