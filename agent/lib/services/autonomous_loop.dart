import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msp/msp.dart';
import '../providers.dart';
import '../main.dart';
import 'package:rust/rust.dart';

class AutonomousLoop {
  final Ref ref;
  ProviderSubscription? _subscription;
  bool _isProcessing = false;

  AutonomousLoop(this.ref);

  void start() {
    _subscription?.close();
    _subscription = ref.listen(assignedTasksProvider, (previous, next) {
      next.whenData((tasks) {
        _checkAndExecute(tasks);
      });
    }, fireImmediately: true);
    ref.read(logsProvider.notifier).addLog('> Autonomous loop started. Watching for tasks...');
  }

  void stop() {
    _subscription?.close();
    ref.read(logsProvider.notifier).addLog('> Autonomous loop stopped.');
  }

  Future<void> _checkAndExecute(List<MatrixTask> tasks) async {
    if (_isProcessing) return;

    // Find the first task ready for execution
    // Note: The design says Architect Review -> In Progress etc.
    // In our loop we claim anything that matches 'ready_for_execution'
    // but the design document says 'ready_for_execution' is a status.
    // Let's check against what hq produces. hq produces 'Backlog' currently.
    // But design says: 
    // 1. human creates (draft)
    // 2. oracle interprets (interpreted)
    // 3. architect decomposes (pending)
    // 4. architect marks ready (ready_for_execution)
    
    final task = tasks.where((t) => t.status == 'ready_for_execution').firstOrNull;
    if (task == null) return;

    _isProcessing = true;
    final logs = ref.read(logsProvider.notifier);
    final data = ref.read(dataProvider);

    try {
      logs.addLog('> [Autonomous] Claiming task: ${task.title}');
      
      // 1. Mark as In Progress
      final inProgressTask = task.copyWith(
        status: 'In Progress',
        assignedTo: 'current_agent', // Should be real agent ID
      );
      await data.updateTask(inProgressTask);

      // 2. Mock Execution Loop
      logs.addLog('> [Autonomous] Planning local execution...');
      await Future.delayed(const Duration(seconds: 2));
      
      logs.addLog('> [Autonomous] Executing: ${task.title}');
      final result = await executeCommand(cmd: 'echo "Task logic executed successfully"');
      logs.addLog('> [Autonomous] Result: $result');

      // 3. Mark for Review
      final completedTask = inProgressTask.copyWith(
        description: '${task.description}\n\n## Execution Output\n$result',
        status: 'Validation', // Following design: Validation step
      );
      await data.updateTask(completedTask);
      logs.addLog('> [Autonomous] Task submitted for review.');

    } catch (e) {
      logs.addLog('> [Autonomous] Task failed: $e');
    } finally {
      _isProcessing = false;
    }
  }
}

final autonomousLoopProvider = Provider((ref) => AutonomousLoop(ref));
