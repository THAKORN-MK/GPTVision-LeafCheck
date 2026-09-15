import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gpt_vision_leaf_detect/constants/constants.dart';
import 'package:gpt_vision_leaf_detect/services/api_service.dart';
import 'history_page.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<double>? box;

  BoundingBoxPainter(this.box);

  @override
  void paint(Canvas canvas, Size size) {
    if (box == null || box!.length < 4) return;

    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final yMin = (box![0].clamp(0.0, 1.0)) * size.height;
    final xMin = (box![1].clamp(0.0, 1.0)) * size.width;
    final yMax = (box![2].clamp(0.0, 1.0)) * size.height;
    final xMax = (box![3].clamp(0.0, 1.0)) * size.width;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(xMin, yMin, xMax, yMax),
        const Radius.circular(12),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.box != box;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String diseaseName = '';
  String diseaseNameEnglish = '';
  String diseaseDescription = '';
  String diseasePrecautions = '';
  double? confidence;
  List<double> boundingBox = [];

  bool detecting = false;
  bool precautionLoading = false;
  bool isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (pickedFile == null) return;

      final imageBytes = await pickedFile.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = imageBytes;
        diseaseName = '';
        diseaseNameEnglish = '';
        diseaseDescription = '';
        diseasePrecautions = '';
        confidence = null;
        boundingBox = [];
      });
    } catch (error) {
      _showErrorSnackBar(error);
    }
  }

  Future<void> detectDisease() async {
    if (_selectedImage == null || detecting) return;

    setState(() {
      detecting = true;
    });

    try {
      final result = await apiService.sendImageToAPI(image: _selectedImage!);
      if (!mounted) return;

      final rawConfidence = result['confidence'];
      setState(() {
        diseaseName = (result['disease_th'] ?? result['disease'] ?? 'ไม่ทราบ')
            .toString()
            .trim();
        diseaseNameEnglish =
            (result['disease_en'] ?? 'Unknown').toString().trim();
        diseaseDescription = (result['description_th'] ?? '').toString().trim();
        confidence = rawConfidence is num
            ? rawConfidence.toDouble()
            : double.tryParse(rawConfidence?.toString() ?? '');

        final rawBox = result['box'];
        boundingBox = rawBox is List
            ? rawBox.map((e) => double.tryParse(e.toString()) ?? 0.0).toList()
            : [];
      });
    } catch (error) {
      if (mounted) _showErrorSnackBar(error);
    } finally {
      if (mounted) {
        setState(() {
          detecting = false;
        });
      }
    }
  }

  Future<void> showPrecautions() async {
    setState(() {
      precautionLoading = true;
    });

    try {
      if (diseasePrecautions.isEmpty) {
        diseasePrecautions = await apiService.sendDiseaseAdvice(
          diseaseName: diseaseName,
        );
      }
      if (mounted) _showSuccessDialog('คำแนะนำการดูแล', diseasePrecautions);
    } catch (error) {
      if (mounted) _showErrorSnackBar(error);
    } finally {
      if (mounted) {
        setState(() {
          precautionLoading = false;
        });
      }
    }
  }

  Future<void> _saveDataWithLocation() async {
    setState(() {
      isSaving = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('กรุณาเปิด GPS (Location Services) บนอุปกรณ์ของคุณ');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('สิทธิ์ถูกปฏิเสธอย่างถาวร กรุณาไปตั้งค่าในเครื่อง');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      _showSuccessDialog(
        'บันทึกข้อมูลสำเร็จ',
        'ชื่อโรค: $diseaseName ($diseaseNameEnglish)\n'
            'พิกัด: ${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}',
      );
    } catch (error) {
      if (mounted) _showErrorSnackBar(error);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackBar(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC62828),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  void _showSuccessDialog(String title, String content) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFE5F5E8),
            child: Icon(Icons.check_rounded, color: themeColor, size: 34),
          ),
          title: Text(title, textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.6),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: textColor,
              ),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 82,
        titleSpacing: 20,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        ),
        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.eco_rounded, color: textColor, size: 28),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Plant Disease AI',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ตรวจโรคพืชด้วย AI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 28),
            tooltip: 'เปิดประวัติการตรวจ',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HistoryPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth =
                constraints.maxWidth > 760 ? 760.0 : constraints.maxWidth;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildActionPanel(),
                      const SizedBox(height: 22),
                      _buildSectionHeading(
                        'ภาพสำหรับวิเคราะห์',
                        'เลือกภาพใบพืชที่เห็นอาการชัดเจนที่สุด',
                      ),
                      const SizedBox(height: 10),
                      _buildImagePreview(),
                      const SizedBox(height: 18),
                      if (_selectedImage != null && diseaseName.isEmpty)
                        _buildAnalyzeArea(),
                      if (diseaseName.isNotEmpty) _buildResultCard(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [themeColor, themeColorLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: textColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เริ่มตรวจสุขภาพพืช',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'วิเคราะห์อาการจากภาพใบพืชได้ง่ายในไม่กี่ขั้นตอน',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildSourceButton(
                  icon: Icons.photo_library_rounded,
                  title: 'เลือกภาพ',
                  subtitle: 'OPEN GALLERY',
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSourceButton(
                  icon: Icons.camera_alt_rounded,
                  title: 'เปิดกล้อง',
                  subtitle: 'START CAMERA',
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: appBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: themeColor, size: 22),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: inkColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: mutedTextColor,
                        fontSize: 9,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeading(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: inkColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: mutedTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.eco_rounded, color: themeColorLight, size: 24),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImageBytes == null) {
      return Container(
        height: 270,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD7E9D9), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: appBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_search_rounded,
                color: themeColorLight,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ยังไม่ได้เลือกภาพ',
              style: TextStyle(
                color: inkColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'เลือกภาพใบพืชเพื่อเริ่มตรวจ',
              style: TextStyle(color: mutedTextColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                _selectedImageBytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
              if (boundingBox.isNotEmpty)
                CustomPaint(
                  painter: BoundingBoxPainter(boundingBox),
                ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.52),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: accentColor, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'ภาพพร้อมวิเคราะห์',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeArea() {
    if (detecting) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD7E9D9)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitThreeBounce(color: themeColor, size: 24),
            SizedBox(width: 14),
            Text(
              'กำลังวิเคราะห์ภาพ...',
              style: TextStyle(
                color: inkColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 58,
      child: FilledButton.icon(
        onPressed: detectDisease,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text(
          'เริ่มวิเคราะห์',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final confidenceText = confidence == null
        ? ''
        : 'ความมั่นใจ ${(confidence!.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFB9DDBD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F5E8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: themeColor,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ผลการวิเคราะห์',
                  style: TextStyle(
                    color: inkColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F5E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ประเมินแล้ว',
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            diseaseName,
            style: const TextStyle(
              color: inkColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          if (diseaseNameEnglish.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              diseaseNameEnglish,
              style: const TextStyle(
                color: mutedTextColor,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (confidenceText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.insights_rounded,
                    color: themeColorLight, size: 18),
                const SizedBox(width: 6),
                Text(
                  confidenceText,
                  style: const TextStyle(
                    color: themeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appBackgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'คำอธิบายอาการ',
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  diseaseDescription.isEmpty
                      ? 'ยังไม่มีคำอธิบายเพิ่มเติมจากระบบ'
                      : diseaseDescription,
                  style: const TextStyle(
                    color: inkColor,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: precautionLoading ? null : showPrecautions,
                  icon: precautionLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text('คำแนะนำ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeColor,
                    side: const BorderSide(color: themeColorLight, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSaving ? null : _saveDataWithLocation,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: textColor,
                          ),
                        )
                      : const Icon(Icons.bookmark_add_outlined),
                  label: const Text('บันทึก'),
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
