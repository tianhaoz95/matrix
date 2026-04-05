import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msp/msp.dart';
import '../providers.dart';
import '../main.dart';
import 'package:rust/rust.dart' as rust;

class CodingAgent {
  final Ref ref;

  CodingAgent(this.ref);

  Future<String> executeWithReasoning(MatrixTask task, {String? workingDir}) async {
    final logs = ref.read(logsProvider.notifier);
    final rustCore = ref.read(rustProvider);
    final settings = ref.read(modelSettingsProvider);
    
    logs.addLog('> [CodingAgent] Starting task with standardized executor: ${task.title}');

    // 1. Context Retrieval (Optional grounding)
    String codebaseMap = '';
    if (workingDir != null) {
      logs.addLog('> [CodingAgent] Mapping codebase for context...');
      codebaseMap = await rustCore.generateCodebaseMap(path: workingDir);
      logs.addLog('> [CodingAgent] Codebase map generated.');
    }

    // 2. Map Provider
    final provider = _mapProvider(settings);
    
    // 3. Prepare Prompt
    final prompt = '''
TASK: "${task.title}"
INSTRUCTIONS: "${task.description}"
WORKING_DIRECTORY: ${workingDir ?? 'Current'}

CODEBASE_CONTEXT:
$codebaseMap

GOAL:
Execute the instructions provided. Use 'run_shell_command' to explore, build, test, and modify the code.
If you need to report progress or status back to the HQ, use the 'matrix_update_task' tool.
When you are completely finished, provide a final summary of your work.
''';


    try {
      logs.addLog('> [CodingAgent] Spawning AI Backend: ${settings.selectedCodingAgent}...');
      
      final result = await rustCore.runAgentTask(
        provider: provider,
        prompt: prompt,
        workingDir: workingDir ?? '.',
      );
      
      return result;
    } catch (e) {
      logs.addLog('> [CodingAgent] Critical Error: $e');
      return 'Execution Failed: $e';
    }
  }

  rust.MatrixAIProvider _mapProvider(ModelSettings settings) {
    final name = settings.selectedCodingAgent.toLowerCase();
    if (name.contains('claude')) return rust.MatrixAIProvider.claude;
    if (name.contains('codex')) return rust.MatrixAIProvider.codex;
    return rust.MatrixAIProvider.gemini;
  }
}

final codingAgentProvider = Provider((ref) => CodingAgent(ref));
