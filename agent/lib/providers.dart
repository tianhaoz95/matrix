import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart' as client_sdk;
import 'package:dart_appwrite/dart_appwrite.dart' as server_sdk;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:msp/msp.dart';
import 'package:msp/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:rust/rust.dart' as rust;

String _getEffectiveEndpoint() {
  String endpoint = dotenv.env['APPWRITE_ENDPOINT'] ?? 'http://localhost/v1';
  
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    if (endpoint.contains('localhost') && !endpoint.contains(':')) {
      return endpoint.replaceFirst('localhost', 'localhost:8080');
    }
  }
  
  return endpoint;
}

final appwriteClientProvider = Provider<client_sdk.Client>((ref) {
  final client = client_sdk.Client();
  client
      .setEndpoint(_getEffectiveEndpoint())
      .setProject(dotenv.env['APPWRITE_PROJECT_ID'] ?? 'matrix_dev')
      .setSelfSigned(status: true); // For local dev
  return client;
});

final appwriteServerClientProvider = Provider<server_sdk.Client?>((ref) {
  final apiKey = dotenv.env['APPWRITE_LOCAL_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) return null;

  final client = server_sdk.Client();
  client
      .setEndpoint(_getEffectiveEndpoint())
      .setProject(dotenv.env['APPWRITE_PROJECT_ID'] ?? 'matrix_dev')
      .setKey(apiKey)
      .setSelfSigned(status: true);
  return client;
});

final authProvider = Provider<IAuthProvider>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return AppwriteAuthProvider(client);
});

final authStateProvider = StreamProvider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.authStateChanges;
});

final dataProvider = Provider<IDataProvider>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return AppwriteDataProvider(
    client: client,
    databaseId: 'main',
    tasksCollectionId: 'tasks',
    agentsCollectionId: 'agents',
    messagesCollectionId: 'messages',
  );
});

final assignedTasksProvider = StreamProvider<List<MatrixTask>>((ref) async* {
  final data = ref.watch(dataProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    yield [];
    return;
  }

  final workspaceId = auth.currentWorkspace?.id ?? 'default';
  
  final initialTasks = await data.getTasks(workspaceId);
  var currentTasks = initialTasks;
  yield currentTasks;

  await for (final update in data.taskUpdates) {
    if (update.workspaceId == workspaceId) {
      final index = currentTasks.indexWhere((t) => t.id == update.id);
      if (index != -1) {
        currentTasks[index] = update;
      } else {
        currentTasks.add(update);
      }
      yield [...currentTasks];
    }
  }
});

// Rust Core Provider for Mocking
class RustCore {
  Future<String> executeCommand({required String cmd}) => rust.executeCommand(cmd: cmd);
  Future<String> scanSystem() => rust.scanSystem();
  Future<String> automaticCapabilityCheck() => rust.automaticCapabilityCheck();
  Future<String> cloneRepository({required String url, required String targetPath}) => 
      rust.cloneRepository(url: url, targetPath: targetPath);
  Future<String> createAgentWorktree({required String repoPath, required String branchName, required String targetPath}) =>
      rust.createAgentWorktree(repoPath: repoPath, branchName: branchName, targetPath: targetPath);
  Future<List<String>> listFilesRecursive({required String path}) => rust.listFilesRecursive(path: path);
  Future<String> startMcpServer({required int port}) => rust.startMcpServer(port: port);
  Stream<rust.TaskUpdateEvent> listenMcpEvents() => rust.listenMcpEvents();
  Future<String> runAgentTask({required rust.MatrixAIProvider provider, required String prompt, required String workingDir}) =>
      rust.runAgentTask(provider: provider, prompt: prompt, workingDir: workingDir);
}

final rustProvider = Provider((ref) => RustCore());

// Settings Providers
class ModelSettings {
  final String selectedModel;
  final String selectedCodingAgent;
  final String selectedCloudModel;
  final String openAiUrl;

  ModelSettings({
    required this.selectedModel,
    required this.selectedCodingAgent,
    required this.selectedCloudModel,
    required this.openAiUrl,
  });

  ModelSettings copyWith({
    String? selectedModel,
    String? selectedCodingAgent,
    String? selectedCloudModel,
    String? openAiUrl,
  }) {
    return ModelSettings(
      selectedModel: selectedModel ?? this.selectedModel,
      selectedCodingAgent: selectedCodingAgent ?? this.selectedCodingAgent,
      selectedCloudModel: selectedCloudModel ?? this.selectedCloudModel,
      openAiUrl: openAiUrl ?? this.openAiUrl,
    );
  }
}

class ModelSettingsNotifier extends Notifier<ModelSettings> {
  @override
  ModelSettings build() {
    return ModelSettings(
      selectedModel: 'OpenAI API',
      selectedCodingAgent: 'Gemini CLI',
      selectedCloudModel: 'Gemini 3 Flash',
      openAiUrl: 'https://api.openai.com/v1',
    );
  }

  void updateModel(String model) {
    state = state.copyWith(selectedModel: model);
  }

  void updateCodingAgent(String agent) {
    state = state.copyWith(selectedCodingAgent: agent);
  }

  void updateCloudModel(String model) {
    state = state.copyWith(selectedCloudModel: model);
  }

  void updateOpenAiUrl(String url) {
    state = state.copyWith(openAiUrl: url);
  }
}

final modelSettingsProvider = NotifierProvider<ModelSettingsNotifier, ModelSettings>(ModelSettingsNotifier.new);
