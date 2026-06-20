import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/motorcycle.dart';
import '../../models/service_record.dart';

/// Off-screen widget that is captured by ScreenshotController and exported
/// as a branded, modern service-receipt image.
class HistoryExportTemplate extends StatelessWidget {
  final ServiceRecord record;
  final Motorcycle? motorcycle;
  final Color themeColor;

  const HistoryExportTemplate({
    super.key,
    required this.record,
    required this.motorcycle,
    required this.themeColor,
  });

  // ── helpers ──────────────────────────────────────────────────────────────

  static _ServiceTypeStyle _typeStyle(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'oil':
      case 'filter':
      case 'chain':
        return _ServiceTypeStyle(
          bgColor: const Color(0xFFDCEEFD),
          textColor: const Color(0xFF1565C0),
          icon: Icons.opacity_rounded,
        );
      case 'tires':
      case 'brakes':
        return _ServiceTypeStyle(
          bgColor: const Color(0xFFEDE7F6),
          textColor: const Color(0xFF4527A0),
          icon: Icons.circle_outlined,
        );
      default:
        return _ServiceTypeStyle(
          bgColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFE65100),
          icon: Icons.build_rounded,
        );
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(record.date);
    final exportDate = DateFormat('dd MMM yyyy • HH:mm').format(DateTime.now());
    final motorName =
        motorcycle != null
            ? '${motorcycle!.brand} ${motorcycle!.name}'
            : 'Unknown Motor';
    final typeStyle = _typeStyle(record.serviceType);

    return Container(
      width: 800,
      color: const Color(0xFFF0F4F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── HEADER GRADIENT ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 36),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor, themeColor.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Logo pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'lib/assets/logo_ra.png',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'RideAssist',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Export date
                    Text(
                      exportDate,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Service Receipt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  motorName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── BODY ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── COST + TYPE CARD ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: type badge + title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: typeStyle.bgColor,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    typeStyle.icon,
                                    size: 13,
                                    color: typeStyle.textColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    record.serviceType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: typeStyle.textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${record.serviceType} Maintenance',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right: cost
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: themeColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          currency.format(record.cost),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── DETAILS CARD ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _infoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Tanggal',
                        value: dateStr,
                        themeColor: themeColor,
                      ),
                      _divider(),
                      _infoRow(
                        icon: Icons.speed_rounded,
                        label: 'Odometer',
                        value:
                            '${NumberFormat('#,###').format(record.mileage)} KM'
                            '  •  Siklus ${record.cycle}',
                        themeColor: themeColor,
                      ),
                      if (record.location != null &&
                          record.location!.isNotEmpty) ...[
                        _divider(),
                        _infoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Lokasi',
                          value: record.location!,
                          themeColor: themeColor,
                        ),
                      ],
                      if (record.notes.isNotEmpty) ...[
                        _divider(),
                        _infoRow(
                          icon: Icons.notes_rounded,
                          label: 'Catatan',
                          value: record.notes,
                          themeColor: themeColor,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── RECEIPT IMAGE ─────────────────────────────────────────
                if (record.receiptImagePath != null &&
                    record.receiptImagePath!.isNotEmpty &&
                    File(record.receiptImagePath!).existsSync()) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 16,
                                color: themeColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Struk / Bukti Servis',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: themeColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: Image.file(
                            File(record.receiptImagePath!),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _receiptPlaceholder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── FOOTER WATERMARK ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      'lib/assets/logo_ra.png',
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dibuat dengan RideAssist',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 24,
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── sub-widgets ───────────────────────────────────────────────────────────

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color themeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: themeColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    height: 1,
    color: const Color(0xFFF1F5F9),
    margin: const EdgeInsets.symmetric(vertical: 2),
  );

  Widget _receiptPlaceholder() => Container(
    height: 140,
    color: const Color(0xFFF8FAFC),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_not_supported_rounded, color: Color(0xFFCBD5E1), size: 36),
        SizedBox(height: 8),
        Text(
          'Struk tidak tersedia',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// ── private data class ────────────────────────────────────────────────────────

class _ServiceTypeStyle {
  final Color bgColor;
  final Color textColor;
  final IconData icon;
  const _ServiceTypeStyle({
    required this.bgColor,
    required this.textColor,
    required this.icon,
  });
}
