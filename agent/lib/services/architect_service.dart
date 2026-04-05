import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:msp/msp.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers.dart';
import '../main.dart';

class ArchitectService {
  final Ref ref;
  late final GenerativeModel _model;
  bool _initialized = false;

  ArchitectService(this.ref);

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

  Future<void> runArchitect(MatrixTask req) async {
    _init();
    final logs = ref.read(logsProvider.notifier);
    final data = ref.read(dataProvider);
    
    logs.addLog('> [Architect] Decomposing technical brief: ${req.title}');

    if (!_initialized) {
      logs.addLog('> [Architect] Error: GEMINI_API_KEY not found. Using mock decomposition.');
      await _createMockTasks(req);
      return;
    }

    final prompt = '''
You are the Architect of the Matrix. You translate technical briefs into a list of granular, actionable coding tasks.

Brief: 
"${req.description}"

Output a JSON array of tasks where each object has:
- title: Short, actionable title.
- description: Detailed instructions for a coding agent.
- priority: "high", "medium", or "low".

Format: [{"title": "...", "description": "...", "priority": "..."}]
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '[]';
      
      final List<dynamic> taskData = jsonDecode(jsonStr);
      
      for (var t in taskData) {
        final newTask = MatrixTask(
          id: '', // Will be generated
          workspaceId: req.workspaceId,
          title: t['title'] ?? 'Task from Architect',
          description: t['description'] ?? '',
          status: 'Backlog',
          priority: t['priority'] ?? 'medium',
          parentTaskId: req.id,
          repositoryUrl: req.repositoryUrl,
        );
        await data.createTask(newTask);
      }

      await data.updateTask(req.copyWith(
        status: 'Complete',
      ));
      logs.addLog('> [Architect] Decomposition complete. Created ${taskData.length} sub-tasks.');
    } catch (e) {
      logs.addLog('> [Architect] Error: $e');
    }
  }

  Future<void> _createMockTasks(MatrixTask req) async {
    final data = ref.read(dataProvider);
    final mockTasks = [
      {'title': 'Sub-task 1', 'description': 'Analyze requirements.', 'priority': 'high'},
      {'title': 'Sub-task 2', 'description': 'Implement core logic.', 'priority': 'high'},
    ];

    for (var t in mockTasks) {
       await data.createTask(MatrixTask(
          id: '',
          workspaceId: req.workspaceId,
          title: t['title']!,
          description: t['description']!,
          status: 'Backlog',
          priority: t['priority']!,
          parentTaskId: req.id,
          repositoryUrl: req.repositoryUrl,
        ));
    }
    
    await data.updateTask(req.copyWith(status: 'Complete'));
  }
}

final architectServiceProvider = Provider((ref) => ArchitectService(ref));
