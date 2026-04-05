// ignore_for_file: avoid_print
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:msp/msp.dart';
import '../providers.dart';

class MatrixBrain {
  final Ref ref;
  late final GenerativeModel _model;
  bool _isProcessing = false;
  ProviderSubscription? _subscription;

  MatrixBrain(this.ref) {
    String apiKey = '';
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    } catch (_) {}

    if (apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      _isMock = true;
    } else {
      _model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);
    }
  }

  bool _isMock = false;

  void start() {
    _subscription?.close();
    _subscription = ref.listen(tasksStreamProvider, (previous, next) {
      final tasks = next.value;
      if (tasks != null) {
        processTasks(tasks);
      }
    }, fireImmediately: true);
    print('DEBUG: Matrix Brain started.');
  }

  void stop() {
    _subscription?.close();
    print('DEBUG: Matrix Brain stopped.');
  }

  Future<void> processTasks(List<MatrixTask> tasks) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final draft = tasks.where((t) => t.status.toLowerCase() == 'draft').firstOrNull;
      if (draft != null) {
        await _runOracle(draft);
        return; 
      }

      final interpreted = tasks.where((t) => t.status.toLowerCase() == 'interpreted').firstOrNull;
      if (interpreted != null) {
        await _runArchitect(interpreted);
        return;
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _runOracle(MatrixTask draft) async {
    print('DEBUG: Oracle interpreting: ${draft.title}');
    final data = ref.read(dataProvider);

    String brief;
    if (_isMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      brief = '# Technical Brief\n\nMocked interpretation of "${draft.title}".';
    } else {
      final prompt = 'Translate user intent into technical brief: ${draft.title} - ${draft.description}';
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        brief = response.text ?? 'Error';
      } catch (e) {
        brief = 'Error: $e';
      }
    }

    final updatedTask = draft.copyWith(
      status: 'Interpreted',
      description: brief,
    );

    await data.updateTask(updatedTask);
  }

  Future<void> _runArchitect(MatrixTask req) async {
    print('DEBUG: Architect decomposing: ${req.title}');
    final data = ref.read(dataProvider);

    if (_isMock) {
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      final prompt = 'Decompose this brief into tasks: ${req.description}';
      try {
        await _model.generateContent([Content.text(prompt)]);
      } catch (_) {}
    }

    final updatedTask = req.copyWith(
      status: 'Complete',
    );
    await data.updateTask(updatedTask);
  }
}

final matrixBrainProvider = Provider((ref) => MatrixBrain(ref));
