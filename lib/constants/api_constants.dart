/// UP AI Connect uses an OpenAI-compatible API endpoint.
///
/// Keep the API key out of the source tree. Pass it at runtime with:
/// `--dart-define=UPAI_API_KEY=...`
const String apiBaseUrl = String.fromEnvironment(
  'UPAI_BASE_URL',
  defaultValue: 'https://gen.ai.kku.ac.th/upacth/api/v1',
);

const String apiKey = String.fromEnvironment('UPAI_API_KEY');

const String defaultModel = String.fromEnvironment(
  'UPAI_MODEL',
  defaultValue: 'gpt-5.6-luna-pro',
);
