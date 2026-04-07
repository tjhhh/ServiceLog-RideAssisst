import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../models/motorcycle.dart';
import '../providers/service_provider.dart';
import '../providers/motorcycle_provider.dart';
import '../providers/settings_provider.dart';
import 'add_motorcycle_screen.dart';
import 'motorcycle_detail_screen.dart';

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
                child: Icon(Icons.two_wheeler_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
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

    // Dinamis kalkulasi Data Kesehatan
    // Cari servis oli terakhir
    final oilRecords = activeMotorRecords
        .where((r) => r.serviceType.toLowerCase().contains('oil'))
        .toList();
    int lastOilOdo = 0;
    if (oilRecords.isNotEmpty) {
      oilRecords.sort((a, b) => b.mileage.compareTo(a.mileage));
      lastOilOdo = oilRecords.first.mileage;
    } else if (activeMotorRecords.isNotEmpty) {
      activeMotorRecords.sort((a, b) => b.mileage.compareTo(a.mileage));
      lastOilOdo = activeMotorRecords.first.mileage;
    }

    int kmSinceLastService = activeMotor.odometer - lastOilOdo;
    if (lastOilOdo == 0 && activeMotor.odometer > 0)
      kmSinceLastService = activeMotor.odometer;
    if (kmSinceLastService < 0) kmSinceLastService = 0;

    // Asumsi interval ganti oli diambil dari Settings
    final int interval = settings.serviceInterval;
    int healthPercentage = 100 - (kmSinceLastService / interval * 100).toInt();
    if (healthPercentage < 0) healthPercentage = 0;
    if (healthPercentage > 100) healthPercentage = 100;

    String healthStatus = 'OPTIMAL';
    if (healthPercentage <= 20) {
      healthStatus = 'CRITICAL';
    } else if (healthPercentage <= 50) {
      healthStatus = 'NEEDS ATTENTION';
    } else if (healthPercentage <= 80) {
      healthStatus = 'GOOD';
    }

    String nextServiceDesc = 'Oil Change at ${lastOilOdo + interval} KM';
    bool needsAttention =
        healthPercentage <= 20 || kmSinceLastService >= interval;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      appBar: _buildAppBar(),
      extendBodyBehindAppBar: false,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 32),
            _buildMotorcycleCarousel(motorcycles),
            const SizedBox(height: 24),
            _buildPaginationDots(motorcycles),
            const SizedBox(height: 32),
            _buildStatsSection(activeMotor, healthPercentage, healthStatus),
            if (needsAttention) ...[
              const SizedBox(height: 24),
              _buildAttentionRequired(activeMotor, nextServiceDesc),
            ],
            const SizedBox(height: 24),
            _buildServiceLogs(activeMotor),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
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
            child: Icon(Icons.motorcycle, color: Theme.of(context).colorScheme.primary),
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
            child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF475569)),
            onPressed: () {},
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24),
          Text(
            'Selamat Datang Kembali 👋',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hi, Rider!',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -1.0,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Pantau performa dan jadwalkan perawatan motormu agar selalu dalam kondisi prima.",
            style: TextStyle(
              fontSize: 15, 
              color: Color(0xFF64748B), 
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorcycleCarousel(List<Motorcycle> motorcycles) {
    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
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
                child: Opacity(
                  opacity: value.clamp(0.6, 1.0),
                  child: child,
                ),
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
              const Color(0xFF0F172A).withOpacity(0.9)
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
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
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
              motor.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                letterSpacing: -0.5,
                fontWeight: FontWeight.bold,
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
                title: 'TOTAL ODOMETER',
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
                ),
                if (onTap != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF94A3B8)),
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

  Widget _buildAttentionRequired(Motorcycle motor, String nextServiceInfo) {
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
          Text(
            nextServiceInfo,
            style: const TextStyle(
              fontSize: 20,
              letterSpacing: -0.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Interval servis terlewati atau sudah dekat. Jadwalkan perawatan segera.',
            style: TextStyle(
              fontSize: 14, 
              color: Color(0xFF475569), 
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
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
                    'Lihat Detail',
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
                          'Review your last completed maintenance tasks.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'View All\nHistory',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (displayRecords.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: Text('Belum ada log servis.')),
                )
              else
                ...displayRecords.asMap().entries.map((entry) {
                  final index = entry.key;
                  final record = entry.value;
                  final isLast = index == displayRecords.length - 1;

                  return Column(
                    children: [
                      _buildLogItem(
                        icon: Icons.settings_suggest,
                        title: record.serviceType,
                        subtitle: 'Odometer: ${record.mileage} KM',
                        date: '${record.date.day}/${record.date.month}',
                        status: 'SUCCESS',
                      ),
                      if (!isLast)
                        const Divider(
                          height: 32,
                          thickness: 1,
                          color: Color(0xFFF0F0F0),
                        ),
                    ],
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
    required String status,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
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
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              date,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showUpdateOdometerDialog(
    BuildContext context,
    Motorcycle motor,
  ) async {
    final TextEditingController odometerController = TextEditingController(
      text: motor.odometer.toString(),
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Odometer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update the current mileage of your motorcycle:'),
              const SizedBox(height: 16),
              TextField(
                controller: odometerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Odometer',
                  border: OutlineInputBorder(),
                  suffixText: 'KM',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final newOdo = int.tryParse(odometerController.text);
                if (newOdo != null && newOdo >= motor.odometer) {
                  final updatedMotor = motor.copyWith(odometer: newOdo);
                  ref
                      .read(motorcycleProvider.notifier)
                      .updateMotorcycle(updatedMotor);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sistem gagal memproses! Odometer baru harus lebih besar atau sama dengan sebelumnya.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('UPDATE ODOMETER'),
            ),
          ],
        );
      },
    );
  }
}
