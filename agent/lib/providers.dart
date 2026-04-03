import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:msp/msp.dart';
import 'package:msp/appwrite.dart';

final appwriteClientProvider = Provider<Client>((ref) {
  final client = Client();
  client
      .setEndpoint(dotenv.env['APPWRITE_ENDPOINT'] ?? 'http://localhost/v1')
      .setProject(dotenv.env['APPWRITE_PROJECT_ID'] ?? 'matrix_dev')
      .setSelfSigned(status: true); // For local dev
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

// Stream of tasks assigned to this specific agent
final assignedTasksProvider = StreamProvider<List<MatrixTask>>((ref) async* {
  final data = ref.watch(dataProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    yield [];
    return;
  }

  final workspaceId = auth.currentWorkspace?.id ?? 'default';
  
  // Note: In a real scenario, we'd filter by assigned_to
  // For now, we fetch all tasks in the workspace
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
