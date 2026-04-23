import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/motorcycle.dart';
import '../models/service_interval.dart';
import '../models/service_record.dart';
import '../providers/service_provider.dart';
import '../providers/motorcycle_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_item.dart';
import '../widgets/odometer_update_sheet.dart';
import 'add_motorcycle_screen.dart';
import 'motorcycle_detail_screen.dart';
import 'account_screen.dart';
import '../widgets/auto_track_card.dart';
import '../providers/tracking_provider.dart';

class AttentionItem {
  final String serviceName;
  final int intervalKm;
  final int kmSinceLastService;
  final DateTime? lastReplacedDate;
  final int lastReplacedOdo;
  final int lastReplacedCycle;

  AttentionItem({
    required this.serviceName,
    required this.intervalKm,
    required this.kmSinceLastService,
    this.lastReplacedDate,
    required this.lastReplacedOdo,
    this.lastReplacedCycle = 0,
  });

  bool get isCritical => kmSinceLastService >= intervalKm;
  bool get isWarning =>
      kmSinceLastService >= (intervalKm * 0.85); // 85% mendekati limit
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentMotorIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motorcycles = ref.watch(motorcycleProvider);
    final allRecords = ref.watch(serviceRecordsProvider);
    final settings = ref.watch(settingsProvider);
    final notifications = ref.watch(notificationProvider);

    if (motorcycles.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // Slate 100
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.two_wheeler_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Garasi Masih Kosong',
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Yuk tambahkan motor pertamamu\ndan mulai kelola perawatannya!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMotorcycleScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Tambah Motor',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } // Akhir dari penutup if (motorcycles.isEmpty)

    // Pastikan index tidak out of bounds
    if (_currentMotorIndex >= motorcycles.length) {
      _currentMotorIndex = 0;
    }

    // Motor yang sedang aktif berdasarkan scroll/swipe PageView
    final activeMotor = motorcycles[_currentMotorIndex];
    final activeMotorRecords = allRecords
        .where((r) => r.motorcycleId == activeMotor.id)
        .toList();

    // Kalkulasi Attention & Health secara dinamis berdasarkan interval part
    final intervals = getDefaultIntervals(activeMotor.id!, activeMotor.type);
    List<AttentionItem> attentionItems = [];
    int lowestHealth = 100;

    for (var interval in intervals) {
      // Cari rekam medis servis yang sesuai/mengandung kata ini
      final relatedRecords =
          activeMotorRecords
              .where(
                (r) =>
                    r.serviceType.toLowerCase().contains(
                      interval.serviceItem.toLowerCase(),
                    ) ||
                    interval.serviceItem.toLowerCase().contains(
                      r.serviceType.toLowerCase(),
                    ),
              )
              .toList()
            ..sort((a, b) => b.mileage.compareTo(a.mileage)); // Sort terbaru

      int lastReplacedOdo = 0;
      DateTime? lastReplacedDate;
      int lastReplacedCycle = 0;

      if (relatedRecords.isNotEmpty) {
        lastReplacedOdo = relatedRecords.first.mileage;
        lastReplacedDate = relatedRecords.first.date;
        lastReplacedCycle = relatedRecords.first.cycle;
      }

      int activeFullOdo = (activeMotor.cycle * 100000) + activeMotor.odometer;
      int lastFullOdo = (lastReplacedCycle * 100000) + lastReplacedOdo;

      int kmSinceLastService = activeFullOdo - lastFullOdo;
      if (lastReplacedOdo == 0 && lastReplacedCycle == 0 && activeFullOdo > 0) {
        kmSinceLastService = activeFullOdo;
      }
      if (kmSinceLastService < 0) kmSinceLastService = 0;

      // Hitung presentase kesehatan spesifik part ini
      int partHealth =
          100 - (kmSinceLastService / interval.intervalKm * 100).toInt();
      if (partHealth < 0) partHealth = 0;
      if (partHealth > 100) partHealth = 100;

      if (partHealth < lowestHealth)
        lowestHealth =
            partHealth; // Kesehatan global ngikut part yg paling kritis

      final attentionItem = AttentionItem(
        serviceName: interval.serviceItem,
        intervalKm: interval.intervalKm,
        kmSinceLastService: kmSinceLastService,
        lastReplacedOdo: lastReplacedOdo,
        lastReplacedDate: lastReplacedDate,
        lastReplacedCycle: lastReplacedCycle,
      );

      if (attentionItem.isWarning || attentionItem.isCritical) {
        attentionItems.add(attentionItem);
      }
    }

    // Urutkan peringatan, utamakan yang paling kritis
    attentionItems.sort(
      (a, b) => b.kmSinceLastService.compareTo(a.kmSinceLastService),
    );

    String healthStatus = 'OPTIMAL';
    if (lowestHealth <= 20) {
      healthStatus = 'KRITIS';
    } else if (lowestHealth <= 50) {
      healthStatus = 'PERLU PERHATIAN';
    } else if (lowestHealth <= 80) {
      healthStatus = 'BAIK';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      appBar: _buildAppBar(notifications),
      extendBodyBehindAppBar: false,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 32),
            _buildMotorcycleCarousel(
              motorcycles,
              ref.watch(trackingProvider).isTracking,
            ),
            const SizedBox(height: 24),
            _buildPaginationDots(motorcycles),
            const SizedBox(height: 32),
            _buildStatsSection(activeMotor, lowestHealth, healthStatus),
            const SizedBox(height: 24),
            AutoTrackCard(activeMotor: activeMotor),
            if (attentionItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildAttentionRequired(activeMotor, attentionItems),
            ],
            const SizedBox(height: 24),
            _buildServiceLogs(activeMotor),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(List<NotificationItem> notifications) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset('lib/assets/logo_ra.png', width: 24, height: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'RideAssist',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF475569),
                ),
                onPressed: () =>
                    _showNotificationBottomSheet(context, notifications),
              ),
              if (notifications.isNotEmpty)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              );
            },
            child: CircleAvatar(
              radius: 18,
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
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Selamat Datang Kembali 👋',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hi, ${FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true ? FirebaseAuth.instance.currentUser!.displayName : 'Rider'}!',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildMotorcycleCarousel(
    List<Motorcycle> motorcycles,
    bool isTracking,
  ) {
    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: _pageController,
        physics: isTracking
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentMotorIndex = index;
          });
        },
        itemCount: motorcycles.length,
        itemBuilder: (context, index) {
          final motor = motorcycles[index];

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
              }
              return Transform.scale(
                scale: value,
                child: Opacity(opacity: value.clamp(0.6, 1.0), child: child),
              );
            },
            child: _buildMotorCard(motor),
          );
        },
      ),
    );
  }

  Widget _buildMotorCard(Motorcycle motor) {
    ImageProvider imageProvider;
    if (motor.imageUrl.startsWith('http')) {
      imageProvider = NetworkImage(motor.imageUrl);
    } else {
      imageProvider = FileImage(File(motor.imageUrl));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFF0F172A).withOpacity(0.9),
            ],
            stops: const [0.3, 1.0],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                motor.brand.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${motor.name} ${motor.year != null ? '(${motor.year})' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                letterSpacing: -0.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (motor.licensePlate != null && motor.licensePlate!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        motor.licensePlate!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationDots(List<Motorcycle> motorcycles) {
    if (motorcycles.length <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        motorcycles.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: _currentMotorIndex == index ? 24 : 6,
          decoration: BoxDecoration(
            color: _currentMotorIndex == index
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    Motorcycle motor,
    int healthPercentage,
    String healthStatus,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.speed,
                title: motor.cycle > 0
                    ? 'ODO (CYCLE ${motor.cycle})'
                    : 'TOTAL ODOMETER',
                value: '${motor.odometer}',
                unit: 'KM',
                onTap: () => _showUpdateOdometerDialog(context, motor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildHealthCard(healthPercentage, healthStatus)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                if (onTap != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(int healthPercentage, String healthStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 72,
                width: 72,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: healthPercentage / 100),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    color: _getHealthColor(healthPercentage),
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$healthPercentage',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: -0.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    '%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'KONDISI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getHealthColor(healthPercentage).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              healthStatus,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getHealthColor(healthPercentage),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(int percentage) {
    if (percentage <= 20) return Colors.deepOrange;
    if (percentage <= 50) return Colors.orange;
    if (percentage <= 80) return Colors.blue;
    return Theme.of(context).colorScheme.primary;
  }

  Widget _buildAttentionRequired(
    Motorcycle motor,
    List<AttentionItem> attentionItems,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Light red/orange
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFECACA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'PERHATIAN DIBUTUHKAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ...attentionItems.take(3).map((item) {
            String dateLabel = item.lastReplacedDate != null
                ? DateFormat('dd MMM yyyy').format(item.lastReplacedDate!)
                : 'Belum Pernah';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.serviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.kmSinceLastService} / ${item.intervalKm} KM',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: item.isCritical
                              ? Colors.red
                              : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Terakhir diganti: $dateLabel (Odo: ${item.lastReplacedOdo} KM${item.lastReplacedCycle > 0 ? ' - Cycle ${item.lastReplacedCycle}' : ''})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          if (attentionItems.length > 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                '+ ${attentionItems.length - 3} item lainnya...',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MotorcycleDetailScreen(motorcycle: motor),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Detail & Servis',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFFDC2626),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceLogs(Motorcycle motor) {
    return Consumer(
      builder: (context, ref, child) {
        final records = ref.watch(serviceRecordsProvider);
        // Filter catatan servis sesuai motor yang sedang aktif
        final recentRecords =
            records.where((r) => r.motorcycleId == motor.id).toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        final displayRecords = recentRecords.take(3).toList();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Logs',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Riwayat perawatan terakhirmu',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MotorcycleDetailScreen(motorcycle: motor),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'See All',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (displayRecords.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada riwayat servis',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...displayRecords.map(
                  (record) => _buildLogItem(
                    record.serviceType,
                    DateFormat('dd MMM yyyy').format(record.date),
                    '${record.mileage} KM${record.cycle > 0 ? '\nCyc ${record.cycle}' : ''}',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogItem(String title, String date, String mileage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              color: Colors.black87,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              mileage,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateOdometerDialog(
    BuildContext context,
    Motorcycle motor,
  ) async {
    await showOdometerUpdateSheet(
      context,
      motor,
      onSaveKm: (newOdo) async {
        final updated = motor.copyWith(odometer: newOdo);
        ref.read(motorcycleProvider.notifier).updateMotorcycle(updated);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Odometer diperbarui ke $newOdo KM'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      onSaveCycle: (newOdo) async {
        final updated = motor.copyWith(
          odometer: newOdo,
          cycle: motor.cycle + 1,
        );
        ref.read(motorcycleProvider.notifier).updateMotorcycle(updated);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cycle diperbarui ke ${motor.cycle + 1}. Histori direset.',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
    );
  }

  void _showNotificationBottomSheet(
    BuildContext context,
    List<NotificationItem> notifications,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Notifikasi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Semua beres! Tidak ada notifikasi perawatan saat ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      Color bgColor;
                      Color iconColor;
                      IconData icon;

                      switch (item.type) {
                        case NotificationType.OdometerLimit:
                        case NotificationType.Critical:
                          bgColor = Colors.red.shade50;
                          iconColor = Colors.red;
                          icon = item.type == NotificationType.OdometerLimit
                              ? Icons.speed
                              : Icons.warning_amber_rounded;
                          break;
                        case NotificationType.Warning:
                          bgColor = Colors.orange.shade50;
                          iconColor = Colors.orange;
                          icon = Icons.info_outline_rounded;
                          break;
                      }

                      final dateLabel = DateFormat(
                        'dd MMM yyyy',
                      ).format(item.date);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: bgColor,
                              child: Icon(icon, color: iconColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        dateLabel,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.motorcycleName,
                                      style: TextStyle(
                                        color: Colors.indigo.shade700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
