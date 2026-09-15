import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gpt_vision_leaf_detect/constants/constants.dart';

class DiseaseRecord {
  final String diseaseNameThai;
  final String diseaseNameEnglish;
  final double latitude;
  final double longitude;
  final DateTime dateSaved;

  const DiseaseRecord({
    required this.diseaseNameThai,
    required this.diseaseNameEnglish,
    required this.latitude,
    required this.longitude,
    required this.dateSaved,
  });
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<DiseaseRecord> _records = [
    DiseaseRecord(
      diseaseNameThai: 'โรคสแคปแอปเปิ้ล',
      diseaseNameEnglish: 'Apple Scab',
      latitude: 19.0296,
      longitude: 99.8944,
      dateSaved: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DiseaseRecord(
      diseaseNameThai: 'โรคใบไหม้มะเขือเทศ',
      diseaseNameEnglish: 'Tomato Late Blight',
      latitude: 19.0305,
      longitude: 99.8950,
      dateSaved: DateTime.now().subtract(const Duration(days: 3)),
    ),
    DiseaseRecord(
      diseaseNameThai: 'โรคใบไหม้ข้าวโพด',
      diseaseNameEnglish: 'Corn Leaf Blight',
      latitude: 19.0250,
      longitude: 99.8890,
      dateSaved: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ประวัติการตรวจ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: _records.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                const Text(
                  'ผลการตรวจล่าสุด',
                  style: TextStyle(
                    color: inkColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'รายการโรคพืชที่บันทึกไว้ในอุปกรณ์นี้',
                  style: TextStyle(color: mutedTextColor, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ..._records.map(_buildRecordCard),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFE5F5E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                color: themeColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'ยังไม่มีประวัติการตรวจ',
              style: TextStyle(
                color: inkColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'ผลการวิเคราะห์ที่บันทึกจะแสดงที่นี่',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(DiseaseRecord record) {
    final formattedDate =
        DateFormat('dd MMM yyyy, HH:mm').format(record.dateSaved);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E9D9)),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F5E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_florist_rounded,
              color: themeColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.diseaseNameThai,
                  style: const TextStyle(
                    color: inkColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.diseaseNameEnglish,
                  style: const TextStyle(
                    color: mutedTextColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 14, color: themeColorLight),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                            color: mutedTextColor, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: themeColorLight),
                    const SizedBox(width: 5),
                    Text(
                      '${record.latitude.toStringAsFixed(4)}, '
                      '${record.longitude.toStringAsFixed(4)}',
                      style:
                          const TextStyle(color: mutedTextColor, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined, color: themeColor),
            tooltip: 'ดูพิกัดบนแผนที่',
            onPressed: () => _openMap(record.latitude, record.longitude),
          ),
        ],
      ),
    );
  }

  void _openMap(double lat, double lng) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('พิกัด: $lat, $lng'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'ปิด',
          onPressed: () {},
        ),
      ),
    );
  }
}
