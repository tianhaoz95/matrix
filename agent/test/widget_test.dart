import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msp/msp.dart';
import 'package:agent/providers.dart';
import 'package:agent/main.dart';
import 'package:agent/services/autonomous_loop.dart';
import 'package:rust/rust.dart' as rust;
import 'dart:async';

class MockAuthProvider implements IAuthProvider {
  @override
  Future<void> signUp({required String email, required String password, required String name}) async {}
  @override
  Future<void> signIn({required String email, required String password}) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<List<Workspace>> getWorkspaces() async => [Workspace(id: 'w1', name: 'Test')];
  @override
  Future<Workspace> createWorkspace({required String name}) async => Workspace(id: 'w2', name: name);
  @override
  Future<void> selectWorkspace(String workspaceId) async {}
  @override
  Workspace? get currentWorkspace => Workspace(id: 'w1', name: 'Test');
  @override
  bool get isAuthenticated => true;
  @override
  Stream<bool> get authStateChanges => Stream.value(true);
}

class MockDataProvider implements IDataProvider {
  final _taskController = StreamController<MatrixTask>.broadcast();
  final List<MatrixTask> tasks = [];

  @override
  Future<List<MatrixTask>> getTasks(String workspaceId) async => tasks;
  @override
  Future<MatrixTask> createTask(MatrixTask task) async {
    tasks.add(task);
    _taskController.add(task);
    return task;
  }
  @override
  Future<MatrixTask> updateTask(MatrixTask task) async {
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    _taskController.add(task);
    return task;
  }
  @override
  Stream<MatrixTask> get taskUpdates => _taskController.stream;
  @override
  Future<List<Agent>> getAgents(String workspaceId) async => [];
  @override
  Future<Agent> registerAgent(Agent agent) async => agent;
  @override
  Future<Agent> updateAgent(Agent agent) async => agent;
  @override
  Stream<Agent> get agentUpdates => Stream.empty();
  @override
  Future<List<Message>> getMessages(String workspaceId, {String? threadId}) async => [];
  @override
  Future<Message> sendMessage(Message message) async => message;
  @override
  Stream<Message> get messageUpdates => Stream.empty();
}

class MockRustCore extends RustCore {
  @override
  Future<String> cloneRepository({required String url, required String targetPath}) async => 'Successfully cloned';
  @override
  Future<String> createAgentWorktree({required String repoPath, required String branchName, required String targetPath}) async => 'Successfully created worktree';
  @override
  Future<List<String>> listFilesRecursive({required String path}) async => ['file1.txt'];
  @override
  Future<String> executeCommand({required String cmd}) async => 'Command output';
  @override
  Future<String> startMcpServer({required int port}) async => 'Mock started';
  @override
  Stream<rust.TaskUpdateEvent> listenMcpEvents() => const Stream.empty();
  @override
  Future<String> runAgentTask({required rust.MatrixAIProvider provider, required String prompt, required String workingDir}) async => 'Mock success';
}

void main() {
  test('Autonomous loop claims and processes task', () async {
    final mockAuth = MockAuthProvider();
    final mockData = MockDataProvider();
    final mockRust = MockRustCore();

    final container = ProviderContainer(overrides: [
      authProvider.overrideWithValue(mockAuth),
      dataProvider.overrideWithValue(mockData),
      rustProvider.overrideWithValue(mockRust),
      modelSettingsProvider.overrideWith(() => ModelSettingsNotifier()),
      logsProvider.overrideWith(() => LogsNotifier()),
      worktreeProvider.overrideWith(() => WorktreeNotifier()),
    ]);

    // Add a task that should be claimed, but WITHOUT repositoryUrl to avoid FS operations
    final task = MatrixTask(
      id: 'task1',
      workspaceId: 'w1',
      title: 'Simple Task',
      description: 'Do something simple',
      status: 'Backlog',
      priority: 'high',
    );
    mockData.tasks.add(task);

    // Start loop
    container.read(autonomousLoopProvider).start();

    // Wait for loop to process
    for (int i = 0; i < 50; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mockData.tasks.first.status == 'Validation') break;
    }

    // Check if task status updated to Validation
    expect(mockData.tasks.first.status, 'Validation');
    expect(mockData.tasks.first.assignedTo, 'current_agent');
  });
}
