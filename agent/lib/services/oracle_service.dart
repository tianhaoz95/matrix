import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:msp/msp.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers.dart';
import '../main.dart';

class OracleService {
  final Ref ref;
  late final GenerativeModel _model;
  bool _initialized = false;

  OracleService(this.ref);

  void _init() {
    if (_initialized) return;
    String apiKey = '';
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (_) {
      // DotEnv not initialized
    }
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);
      _initialized = true;
    }
  }

  Future<void> runOracle(MatrixTask draft) async {
    _init();
    final logs = ref.read(logsProvider.notifier);
    final data = ref.read(dataProvider);
    
    logs.addLog('> [Oracle] Interpreting high-level intent: ${draft.title}');

    if (!_initialized) {
      logs.addLog('> [Oracle] Error: GEMINI_API_KEY not found. Using mock brief.');
      await data.updateTask(draft.copyWith(
        status: 'Interpreted',
        description: '${draft.description}\n\n## Technical Brief (Mocked)\nThis is a mocked technical brief because no API key was provided.',
      ));
      return;
    }

    final prompt = '''
You are the Oracle of the Matrix. Your job is to take a vague human intent and translate it into a detailed Technical Brief.

Human Intent: "${draft.title}"
Context: "${draft.description}"

Output a comprehensive markdown Technical Brief that includes:
1. Objective
2. Technical Requirements
3. Proposed Architecture
4. Potential Challenges
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final brief = response.text ?? 'Failed to generate brief.';

      await data.updateTask(draft.copyWith(
        status: 'Interpreted',
        description: brief,
      ));
      logs.addLog('> [Oracle] Interpretation complete. Status set to "Interpreted".');
    } catch (e) {
      logs.addLog('> [Oracle] Error: $e');
    }
  }
}

final oracleServiceProvider = Provider((ref) => OracleService(ref));
