import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_vision_leaf_detect/constants/api_constants.dart';

void main() {
  test('uses the university API endpoint and requested default model', () {
    expect(apiBaseUrl, 'https://gen.ai.kku.ac.th/upacth/api/v1');
    expect(defaultModel, 'gpt-5.6-luna-pro');
  });

  test('does not contain a hard-coded API key by default', () {
    expect(apiKey, isEmpty);
  });
}
