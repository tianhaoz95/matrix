import 'dart:async';
import 'package:msp/msp.dart';

class MockAuthProvider implements IAuthProvider {
  bool _isAuthenticated = false;
  Workspace? _currentWorkspace;
  final _authStateController = StreamController<bool>.broadcast();

  MockAuthProvider() {
    Future.microtask(() => _authStateController.add(_isAuthenticated));
  }

  @override
  Future<void> signUp({required String email, required String password, required String name}) async {}

  @override
  Future<void> signIn({required String email, required String password}) async {
    _isAuthenticated = true;
    _currentWorkspace = Workspace(id: 'w1', name: 'Test Workspace');
    _authStateController.add(true);
  }

  @override
  Future<void> signOut() async {
    _isAuthenticated = false;
    _currentWorkspace = null;
    _authStateController.add(false);
  }

  @override
  Future<List<Workspace>> getWorkspaces() async => [Workspace(id: 'w1', name: 'Test Workspace')];

  @override
  Future<Workspace> createWorkspace({required String name}) async => Workspace(id: 'w2', name: name);

  @override
  Future<void> selectWorkspace(String workspaceId) async {}

  @override
  Workspace? get currentWorkspace => _currentWorkspace;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;
}

class MockDataProvider implements IDataProvider {
  final List<MatrixTask> _tasks = [];
  final _taskUpdateController = StreamController<MatrixTask>.broadcast();

  @override
  Future<List<MatrixTask>> getTasks(String workspaceId) async => List.from(_tasks);

  @override
  Future<MatrixTask> createTask(MatrixTask task) async {
    final newTask = MatrixTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workspaceId: task.workspaceId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
    );
    _tasks.add(newTask);
    _taskUpdateController.add(newTask);
    return newTask;
  }

  @override
  Future<MatrixTask> updateTask(MatrixTask task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    } else {
      _tasks.add(task);
    }
    // EMIT A COPY to ensure no mutation issues
    _taskUpdateController.add(task);
    return task;
  }

  @override
  Stream<MatrixTask> get taskUpdates => _taskUpdateController.stream;

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
