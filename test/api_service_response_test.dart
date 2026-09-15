import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_vision_leaf_detect/services/api_service.dart';

void main() {
  test('extracts content when the API returns JSON as a string', () {
    const response = '{"choices":[{"message":{"content":"โรคราแป้ง"}}]}';

    expect(extractApiContent(response), 'โรคราแป้ง');
  });

  test('reports the API error message instead of a type error', () {
    const response = '{"error":{"message":"model does not support images"}}';

    expect(
      () => extractApiContent(response),
      throwsA(
        predicate<Object>(
          (error) => error.toString().contains('model does not support images'),
        ),
      ),
    );
  });

  test('parses bilingual disease analysis fields and the bounding box', () {
    const response = '''
    {
      "disease_th": "โรคราแป้ง",
      "disease_en": "Powdery mildew",
      "description_th": "พบคราบสีขาวกระจายบนผิวใบ",
      "box": [0.1, 0.2, 0.8, 0.9]
    }
    ''';

    final result = parseDiseaseAnalysis(response);

    expect(result['disease_th'], 'โรคราแป้ง');
    expect(result['disease_en'], 'Powdery mildew');
    expect(result['description_th'], 'พบคราบสีขาวกระจายบนผิวใบ');
    expect(result['box'], [0.1, 0.2, 0.8, 0.9]);
  });
}
