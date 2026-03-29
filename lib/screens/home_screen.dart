import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../models/motorcycle.dart';
import '../providers/service_provider.dart';
import '../providers/motorcycle_provider.dart';
import 'add_motorcycle_screen.dart';

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

    if (motorcycles.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

    // Asumsi interval ganti oli / service tiap 2000 KM
    final int interval = 2000;
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildMotorcycleCarousel(motorcycles),
            const SizedBox(height: 16),
            _buildPaginationDots(motorcycles),
            const SizedBox(height: 24),
            _buildStatsSection(activeMotor, healthPercentage, healthStatus),
            if (needsAttention) ...[
              const SizedBox(height: 24),
              _buildAttentionRequired(nextServiceDesc),
            ],
            const SizedBox(height: 24),
            _buildServiceLogs(activeMotor),
            const SizedBox(height: 24),
            _buildNextMajorService(activeMotor, nextServiceDesc),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F9FB),
      elevation: 0,
      title: Row(
        children: [
          Icon(Icons.motorcycle, color: Theme.of(context).colorScheme.primary),
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
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black87),
          onPressed: () {},
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 16,
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
          SizedBox(height: 16),
          Text(
            'WELCOME BACK',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hello, Alex',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Your machine is performing at its peak. Here's your current status and maintenance schedule.",
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorcycleCarousel(List<Motorcycle> motorcycles) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentMotorIndex = index;
          });
        },
        itemCount: motorcycles.length,
        itemBuilder: (context, index) {
          final motor = motorcycles[index];
          // Simple scale animation logic can be added here if desired
          return _buildMotorCard(motor);
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
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              motor.brand,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              motor.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationDots(List<Motorcycle> motorcycles) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        motorcycles.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentMotorIndex == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentMotorIndex == index
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(int healthPercentage, String healthStatus) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: healthPercentage / 100,
                  strokeWidth: 6,
                  color: _getHealthColor(healthPercentage),
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
              Text(
                '$healthPercentage%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'VEHICLE HEALTH',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            healthStatus,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getHealthColor(healthPercentage),
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

  Widget _buildAttentionRequired(String nextServiceInfo) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EE), // Light orange background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.deepOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ATTENTION REQUIRED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.deepOrange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            nextServiceInfo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Exceeded service interval or nearing schedule. Please plan maintenance soon.',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'View Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange.shade700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: Colors.deepOrange.shade700,
              ),
            ],
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
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
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

  Widget _buildNextMajorService(Motorcycle motor, String nextServiceDesc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEXT MAJOR SERVICE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nextServiceDesc.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recommended maintenance interval reached for ${motor.brand} ${motor.name}.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Pre-Order Parts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
