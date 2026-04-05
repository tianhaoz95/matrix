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
    List<String> files = [];
    if (workingDir != null) {
      logs.addLog('> [CodingAgent] Contextualizing isolated worktree...');
      files = await rustCore.listFilesRecursive(path: workingDir);
      logs.addLog('> [CodingAgent] Grounded with ${files.length} files.');
    }

    // 2. Map Provider
    final provider = _mapProvider(settings);
    
    // 3. Prepare Prompt
    final prompt = '''
Task: "${task.title}"
Instructions: "${task.description}"
Working Directory: ${workingDir ?? 'Current'}

Files in scope:
${files.take(20).join('\n')}
${files.length > 20 ? '... and ${files.length - 20} more' : ''}

Please fulfill this task using the available tools.
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
