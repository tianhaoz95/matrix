import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msp/msp.dart';
import '../providers.dart';
import '../main.dart';
import 'coding_agent.dart';
import 'oracle_service.dart';
import 'architect_service.dart';
import 'package:path/path.dart' as p;

class AutonomousLoop {
  final Ref ref;
  ProviderSubscription? _subscription;
  StreamSubscription? _mcpEventSubscription;
  bool _isProcessing = false;
  bool _isServerStarted = false;

  AutonomousLoop(this.ref);

  void start() {
    _subscription?.close();
    _subscription = ref.listen(assignedTasksProvider, (previous, next) {
      final tasks = next.value;
      if (tasks != null) {
        _checkAndExecute(tasks);
      }
    }, fireImmediately: true);
    
    final persona = ref.read(modelSettingsProvider).selectedPersona;
    ref.read(logsProvider.notifier).addLog('> Autonomous loop started [$persona mode].');
    
    _ensureMcpServerStarted();
  }

  void stop() {
    _subscription?.close();
    _mcpEventSubscription?.cancel();
    ref.read(logsProvider.notifier).addLog('> Autonomous loop stopped.');
  }

  Future<void> _ensureMcpServerStarted() async {
    if (_isServerStarted) return;
    _isServerStarted = true;

    final rust = ref.read(rustProvider);
    final logs = ref.read(logsProvider.notifier);

    // 1. Start SSE Server in background
    unawaited(rust.startMcpServer(port: 8000).then((res) {
      logs.addLog('> [MCP] Server status: $res');
    }));

    // 2. Listen for MCP events (Task Updates)
    _mcpEventSubscription = rust.listenMcpEvents().listen((event) async {
      logs.addLog('> [MCP] Received task update for ${event.taskId}: status=${event.status}');
      
      final data = ref.read(dataProvider);
      final auth = ref.read(authProvider);
      
      // Fetch current task
      final workspaceId = auth.currentWorkspace?.id ?? 'default';
      final tasks = await data.getTasks(workspaceId);
      final task = tasks.where((t) => t.id == event.taskId).firstOrNull;
      
      if (task != null) {
        final updatedTask = task.copyWith(
          status: event.status,
          assignedTo: event.assignedTo,
          description: event.report != null ? '${task.description}\n\n## AI Report\n${event.report}' : null,
        );
        await data.updateTask(updatedTask);
        logs.addLog('> [HQ] Task ${event.taskId} updated successfully.');
      }
    });

    logs.addLog('> [MCP] SSE Singleton started on port 8000.');
  }

  Future<void> _checkAndExecute(List<MatrixTask> tasks) async {
    if (_isProcessing) return;

    final settings = ref.read(modelSettingsProvider);
    final persona = settings.selectedPersona;

    if (persona == 'The Oracle') {
      final draft = tasks.where((t) => t.status.toLowerCase() == 'draft').firstOrNull;
      if (draft != null) {
        _isProcessing = true;
        await ref.read(oracleServiceProvider).runOracle(draft);
        _isProcessing = false;
      }
      return;
    }

    if (persona == 'The Architect') {
      final interpreted = tasks.where((t) => t.status.toLowerCase() == 'interpreted').firstOrNull;
      if (interpreted != null) {
        _isProcessing = true;
        await ref.read(architectServiceProvider).runArchitect(interpreted);
        _isProcessing = false;
      }
      return;
    }

    // Default Agent Logic
    final task = tasks.where((t) {
      final status = t.status.toLowerCase();
      return status == 'ready_for_execution' || status == 'backlog' || status == 'ready';
    }).firstOrNull;
    if (task == null) return;

    _isProcessing = true;
    final logs = ref.read(logsProvider.notifier);
    final data = ref.read(dataProvider);
    final agent = ref.read(codingAgentProvider);
    final rust = ref.read(rustProvider);
    final worktree = ref.read(worktreeProvider.notifier);

    try {
      logs.addLog('> [Autonomous] Claiming task: ${task.title}');
      
      // 1. Mark as In Progress (manual claim before AI starts)
      final inProgressTask = task.copyWith(
        status: 'In Progress',
        assignedTo: 'current_agent', 
      );
      await data.updateTask(inProgressTask);

      String? executionDir;

      // 2. Handle Git & Worktree if repositoryUrl is provided
      if (task.repositoryUrl != null && task.repositoryUrl!.isNotEmpty) {
        logs.addLog('> [Autonomous] Git repository detected: ${task.repositoryUrl}');
        
        final tempDir = Directory.systemTemp.createTempSync('matrix_agent_');
        final repoPath = p.join(tempDir.path, 'repo');
        final wtPath = p.join(tempDir.path, 'worktree');

        logs.addLog('> [Autonomous] Cloning repository...');
        final cloneRes = await rust.cloneRepository(url: task.repositoryUrl!, targetPath: repoPath);
        logs.addLog('> [Autonomous] $cloneRes');

        if (cloneRes.contains('Successfully cloned')) {
          logs.addLog('> [Autonomous] Creating isolated worktree...');
          final branchName = 'agent-task-${task.id}';
          final wtRes = await rust.createAgentWorktree(
            repoPath: repoPath,
            branchName: branchName,
            targetPath: wtPath,
          );
          logs.addLog('> [Autonomous] $wtRes');

          if (wtRes.contains('Successfully created worktree')) {
            executionDir = wtPath;
            worktree.setWorktree(wtPath);
            logs.addLog('> [Autonomous] Isolated environment ready at $wtPath');
          }
        }
      }

      // 3. Setup Gemini CLI config for SSE
      if (executionDir != null) {
        final geminiConfigDir = Directory(p.join(executionDir, '.gemini'));
        // ignore: avoid_slow_async_io
        if (!await geminiConfigDir.exists()) await geminiConfigDir.create();
        
        final settingsFile = File(p.join(geminiConfigDir.path, 'settings.json'));
        await settingsFile.writeAsString(jsonEncode({
          "mcpServers": {
            "matrix-hub": {
              "url": "http://localhost:8000/sse"
            }
          }
        }));
        logs.addLog('> [Autonomous] MCP configuration injected into worktree.');
      }

      // 4. Execution Loop with Reasoning
      logs.addLog('> [Autonomous] Triggering AI reasoning...');
      final result = await agent.executeWithReasoning(inProgressTask, workingDir: executionDir);
      logs.addLog('> [Autonomous] AI reasoning complete.');

      // 5. Mark for Validation
      final completedTask = inProgressTask.copyWith(
        description: '${task.description}\n\n## AI Execution Output\n$result',
        status: 'Validation',
      );
      await data.updateTask(completedTask);
      logs.addLog('> [Autonomous] Task submitted for Validation.');

      // Cleanup UI
      worktree.setWorktree(null);

    } catch (e) {
      logs.addLog('> [Autonomous] Task failed: $e');
      worktree.setWorktree(null);
    } finally {
      _isProcessing = false;
    }
  }
}

final autonomousLoopProvider = Provider((ref) => AutonomousLoop(ref));
