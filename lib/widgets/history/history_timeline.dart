import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service_record.dart';
import 'service_detail_sheet.dart';

class HistoryTimeline extends StatelessWidget {
  final List<ServiceRecord> records;

  const HistoryTimeline({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
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

        return _TimelineItemCard(
          type: record.serviceType.toUpperCase(),
          typeColor: typeColor,
          typeTextColor: typeTextColor,
          dotColor: dotColor,
          title: '${record.serviceType} Maintenance',
          price: currencyFormat.format(record.cost),
          location: record.location,
          description: record.notes.isNotEmpty
              ? record.notes
              : 'No additional notes provided.',
          imageUrl: record.receiptImagePath,
          isLast: isLast,
          date: DateFormat('MMM dd, yyyy').format(record.date),
          onTap: () => showServiceDetailSheet(context, record),
        );
      }).toList(),
    );
  }
}

class _TimelineItemCard extends StatelessWidget {
  final String type;
  final Color typeColor;
  final Color typeTextColor;
  final Color dotColor;
  final String title;
  final String price;
  final String description;
  final String date;
  final String? location;
  final String? imageUrl;
  final bool isLast;
  final VoidCallback? onTap;

  const _TimelineItemCard({
    required this.type,
    required this.typeColor,
    required this.typeTextColor,
    required this.dotColor,
    required this.title,
    required this.price,
    required this.description,
    required this.date,
    this.location,
    this.imageUrl,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                  if (location != null && location!.isNotEmpty) ...[
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
                            location!,
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
                  if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(imageUrl!),
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
