import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/service_record.dart';
import '../models/motorcycle.dart';
import '../providers/service_provider.dart';
import '../providers/motorcycle_provider.dart';
import '../widgets/history/service_detail_sheet.dart';
import 'add_service_screen.dart';

class FullHistoryScreen extends ConsumerStatefulWidget {
  const FullHistoryScreen({super.key});

  @override
  ConsumerState<FullHistoryScreen> createState() => _FullHistoryScreenState();
}

class _FullHistoryScreenState extends ConsumerState<FullHistoryScreen> {
  String? _selectedMotorcycleId; // State untuk filter motor
  String _searchQuery = '';
  String _sortBy = 'Date (Newest)';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motorcycles = ref.watch(motorcycleProvider);

    // 1. Dapatkan daftar history riil dari Provider
    final allRecords = ref.watch(serviceRecordsProvider);
    final activeMotorcycleIds = motorcycles.map((m) => m.id).toSet();

    // Filter by selected motorcycle if any, and ensure we only show active ones when "All" is selected
    var records = _selectedMotorcycleId == null
        ? allRecords
              .where((r) => activeMotorcycleIds.contains(r.motorcycleId))
              .toList()
        : allRecords
              .where((r) => r.motorcycleId == _selectedMotorcycleId)
              .toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      records = records.where((r) {
        return r.serviceType.toLowerCase().contains(query) ||
            r.notes.toLowerCase().contains(query) ||
            (r.location != null && r.location!.toLowerCase().contains(query));
      }).toList();
    }

    switch (_sortBy) {
      case 'Date (Newest)':
        records.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Date (Oldest)':
        records.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Cost (Highest)':
        records.sort((a, b) => b.cost.compareTo(a.cost));
        break;
      case 'Cost (Lowest)':
        records.sort((a, b) => a.cost.compareTo(b.cost));
        break;
    }

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
    String lastServiceAgo = 'N/A';
    String lastServiceUnit = '';
    if (records.isNotEmpty) {
      final latestRecord = records.reduce(
        (a, b) => a.date.isAfter(b.date) ? a : b,
      );
      final difference = DateTime.now().difference(latestRecord.date).inDays;
      if (difference == 0) {
        lastServiceAgo = 'Today';
      } else {
        lastServiceAgo = '${difference.abs()}d';
        lastServiceUnit = 'ago';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(motorcycles),
                  const SizedBox(height: 24),
                  _buildSummaryCard(
                    totalSpentText,
                    lastServiceAgo,
                    lastServiceUnit,
                  ),
                  const SizedBox(height: 24),
                  _buildSearchBar(),
                  const SizedBox(height: 32),
                  _buildTimeline(records),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F9FB),
      elevation: 0,
      title: const Text(
        'Full History',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildHeader(List<Motorcycle> motorcycles) {
    String selectedMotorName = 'All Motors';
    if (_selectedMotorcycleId != null) {
      try {
        final m = motorcycles.firstWhere(
          (motor) => motor.id == _selectedMotorcycleId,
        );
        selectedMotorName = '${m.brand} ${m.name}';
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 4),
        const Text(
          'Service History',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: Colors.black87,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        // Dropdown untuk filter motor
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              initialValue: _selectedMotorcycleId ?? '-1',
              tooltip: 'Select Motor',
              elevation: 4,
              shadowColor: Colors.black12,
              surfaceTintColor: Colors.white,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              position: PopupMenuPosition.under,
              onSelected: (value) {
                setState(() {
                  _selectedMotorcycleId = value == '-1' ? null : value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: '-1',
                  child: Text('All Motors'),
                ),
                ...motorcycles.map((motor) {
                  return PopupMenuItem<String>(
                    value: motor.id ?? '-1',
                    child: Text('${motor.brand} ${motor.name}'),
                  );
                }),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedMotorName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.indigo),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String totalSpent,
    String lastServiceAgo,
    String lastServiceUnit,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL SPENT',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    totalSpent,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST SERVICE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        lastServiceAgo,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lastServiceUnit,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey, size: 20),
                hintText: 'Search service title, parts, or notes...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          initialValue: _sortBy,
          tooltip: 'Sort Options',
          elevation: 4,
          shadowColor: Colors.black12,
          surfaceTintColor: Colors.white,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          position: PopupMenuPosition.under,
          onSelected: (value) {
            setState(() {
              _sortBy = value;
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'Date (Newest)',
              child: Text('Date (Newest)'),
            ),
            const PopupMenuItem<String>(
              value: 'Date (Oldest)',
              child: Text('Date (Oldest)'),
            ),
            const PopupMenuItem<String>(
              value: 'Cost (Highest)',
              child: Text('Cost (Highest)'),
            ),
            const PopupMenuItem<String>(
              value: 'Cost (Lowest)',
              child: Text('Cost (Lowest)'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(List<ServiceRecord> records) {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40.0),
        child: Center(
          child: Text(
            'No service records yet.\nTap (+) to add one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.5),
          ),
        ),
      );
    }

    return Column(
      children: records.asMap().entries.map((entry) {
        final index = entry.key;
        final record = entry.value;
        final isLast = index == records.length - 1;

        // Tentukan warna UI berdasarkan tipe layanan
        Color typeColor;
        Color typeTextColor;
        Color dotColor;

        switch (record.serviceType.toLowerCase()) {
          case 'oil':
          case 'filter':
          case 'chain':
            typeColor = Colors.blue.shade100;
            typeTextColor = Colors.blue.shade700;
            dotColor = Theme.of(context).colorScheme.primary;
            break;
          case 'tires':
          case 'brakes':
            typeColor = Colors.indigo.shade100;
            typeTextColor = Colors.indigo.shade700;
            dotColor = Colors.indigo;
            break;
          default:
            typeColor = Colors.orange.shade100;
            typeTextColor = Colors.deepOrange.shade700;
            dotColor = Colors.deepOrange;
        }

        final currencyFormat = NumberFormat.currency(
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        return _buildTimelineItem(
          type: record.serviceType.toUpperCase(),
          typeColor: typeColor,
          typeTextColor: typeTextColor,
          dotColor: dotColor,
          title: '${record.serviceType} Maintenance',
          price: currencyFormat.format(record.cost),
          location: record.location, // Kirim lokasi ke timeline item
          description: record.notes.isNotEmpty
              ? record.notes
              : 'No additional notes provided.',
          imageUrl: record.receiptImagePath, // ini path lokal
          isLast: isLast,
          date: DateFormat('MMM dd, yyyy').format(record.date),
          onTap: () => showServiceDetailSheet(context, record),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineItem({
    required String type,
    required Color typeColor,
    required Color typeTextColor,
    required Color dotColor,
    required String title,
    required String price,
    required String description,
    required String date,
    String? location,
    String? imageUrl,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dot and Line Column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dotColor.withOpacity(0.3),
                      width: 4,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1.5, color: Colors.grey.shade300),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade100, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: typeTextColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (location != null && location.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.indigo,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (imageUrl != null && imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(imageUrl),
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 140,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_rounded,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Gambar tidak ditemukan',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
