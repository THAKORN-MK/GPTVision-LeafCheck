import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:cross_file/cross_file.dart';

import '../constants/api_constants.dart';

Map<String, dynamic> _decodeApiBody(dynamic responseData) {
  if (responseData == null) {
    throw StateError('Empty response from API');
  }

  dynamic decoded = responseData;
  if (decoded is String) {
    final trimmed = decoded.trim();
    if (trimmed.isEmpty) {
      throw StateError('Empty response from API');
    }

    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      throw StateError(
        'API returned a non-JSON response: ${_previewText(trimmed)}',
      );
    }
  }

  if (decoded is! Map) {
    throw StateError('API returned an unexpected response format');
  }

  return Map<String, dynamic>.from(decoded);
}

String _previewText(String value) {
  const maxLength = 300;
  return value.length <= maxLength
      ? value
      : '${value.substring(0, maxLength)}...';
}

String _apiErrorMessage(dynamic error) {
  if (error is Map) {
    return error['message']?.toString() ?? error.toString();
  }
  return error.toString();
}

/// Extracts the assistant text from either a decoded JSON map or a JSON string.
String extractApiContent(dynamic responseData) {
  final body = _decodeApiBody(responseData);
  final error = body['error'];
  if (error != null) {
    throw StateError(_apiErrorMessage(error));
  }

  final choices = body['choices'];
  if (choices is! List || choices.isEmpty) {
    throw StateError('No response choices returned');
  }

  final firstChoice = choices.first;
  if (firstChoice is! Map) {
    throw StateError('Invalid response choice returned by API');
  }

  final message = firstChoice['message'];
  if (message is! Map) {
    throw StateError('Invalid message returned by API');
  }

  final content = message['content'];
  if (content is String && content.trim().isNotEmpty) {
    return content.trim();
  }

  if (content is List) {
    final text = content
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .join()
        .trim();
    if (text.isNotEmpty) return text;
  }

  throw StateError('Empty AI response');
}

Map<String, dynamic> parseDiseaseAnalysis(String responseText) {
  final cleanedText =
      responseText.replaceAll('```json', '').replaceAll('```', '').trim();

  final decoded = jsonDecode(cleanedText);
  if (decoded is! Map) {
    throw const FormatException('Disease analysis is not a JSON object');
  }

  return Map<String, dynamic>.from(decoded);
}

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout:
            const Duration(seconds: 30), // เผื่อเวลาให้ AI วิเคราะห์ภาพ
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<String> encodeImage(XFile image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<String> _postToAPI(Map<String, dynamic> data) async {
    if (apiKey.trim().isEmpty) {
      throw StateError(
        'ยังไม่ได้ตั้งค่า API key กรุณารันด้วย --dart-define=UPAI_API_KEY=...',
      );
    }

    try {
      final response = await _dio.post("/chat/completions", data: data);
      return extractApiContent(response.data);
    } on DioException catch (e) {
      final errorMsg = _dioErrorMessage(e);
      throw Exception('API request failed: $errorMsg');
    }
  }

  String _dioErrorMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData != null) {
      try {
        final body = _decodeApiBody(responseData);
        final apiError = body['error'];
        if (apiError != null) return _apiErrorMessage(apiError);
        if (body['message'] != null) return body['message'].toString();
      } on StateError {
        return _previewText(responseData.toString());
      }
    }

    return error.message ?? 'Unknown network error';
  }

  Future<String> sendDiseaseAdvice({
    required String diseaseName,
    String model = defaultModel,
  }) async {
    final data = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': 'คุณเป็นผู้เชี่ยวชาญด้านโรคพืชและให้คำแนะนำภาษาไทยเสมอ',
        },
        {
          'role': 'user',
          'content': "สำหรับอาการของพืช '$diseaseName' "
              'ให้คำแนะนำการดูแลและป้องกันจำนวน 3 ข้อเป็นภาษาไทยเท่านั้น '
              'แต่ละข้อเป็นประโยคสั้น กระชับ ปฏิบัติได้จริง '
              'ให้ขึ้นต้นทุกข้อด้วยเครื่องหมาย - และห้ามใส่คำอธิบายเพิ่มเติม '
              'หากกล่าวถึงสารเคมี ให้ระบุว่าใช้ตามฉลากและคำแนะนำของหน่วยงานเกษตรในพื้นที่',
        }
      ],
      'max_tokens': 200,
    };

    return _postToAPI(data);
  }

  // แก้ไขให้ส่งกลับเป็น Map เพื่อรับค่า JSON (ชื่อโรค + กรอบพิกัด)
  Future<Map<String, dynamic>> sendImageToAPI({
    required XFile image,
    int maxTokens = 250,
    String model = defaultModel,
  }) async {
    final String base64Image = await encodeImage(image);

    final data = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an expert plant pathologist. Analyze only evidence visible in the image. '
                  'Be conservative when the image is unclear and never invent a disease.',
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  '''Analyze this plant or leaf image carefully and return ONLY valid JSON.

First, identify the most likely visible condition. It may be a fungal disease, bacterial disease, viral disease, pest damage, nutrient deficiency, or environmental damage. Do not guess from the background or claim certainty when the visible evidence is insufficient.

Return exactly this schema:
{"disease_th":"ชื่อโรคภาษาไทย","disease_en":"English disease name","description_th":"คำอธิบายอาการที่เห็นเป็นภาษาไทยสั้น ๆ","confidence":0.0,"box":[ymin,xmin,ymax,xmax]}

Rules:
- Use the common Thai name and the standard English name when possible.
- confidence must be a number from 0.0 to 1.0 based only on visible evidence.
- box must cover the main visible symptomatic region and use normalized coordinates from 0.0 to 1.0 in the order [top, left, bottom, right].
- If the image is not clear enough, use disease_th "ไม่ทราบ", disease_en "Unknown", confidence 0.0, and box [].
- Do not use Markdown, code fences, extra keys, or explanations outside the JSON.''',
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
              },
            },
          ],
        },
      ],
      'max_tokens': maxTokens,
    };

    final responseText = await _postToAPI(data);

    try {
      return parseDiseaseAnalysis(responseText);
    } catch (e) {
      return {
        'disease_th': responseText,
        'disease_en': 'Unknown',
        'description_th': 'ไม่สามารถอ่านผลวิเคราะห์เป็น JSON ได้',
        'confidence': 0.0,
        'box': [],
      };
    }
  }
}
