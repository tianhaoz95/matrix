import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart' as client_sdk;
import 'package:dart_appwrite/dart_appwrite.dart' as server_sdk;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:msp/msp.dart';
import 'package:msp/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'environment.dart';

String _getEffectiveEndpoint() {
  String endpoint = Environment.appwritePublicEndpoint;

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
      .setProject(Environment.appwriteProjectId)
      .setSelfSigned(status: true);
  return client;
});

final appwriteServerClientProvider = Provider<server_sdk.Client?>((ref) {
  final apiKey = dotenv.env['APPWRITE_LOCAL_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) return null;

  final client = server_sdk.Client();
  client
      .setEndpoint(_getEffectiveEndpoint())
      .setProject(Environment.appwriteProjectId)
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
    databaseId: Environment.appwriteDatabaseId,
    tasksCollectionId: 'tasks',
    agentsCollectionId: 'agents',
    messagesCollectionId: 'messages',
  );
});

final tasksProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<MatrixTask>>>((ref) {
  return TasksNotifier(ref);
});

class TasksNotifier extends StateNotifier<AsyncValue<List<MatrixTask>>> {
  final Ref ref;
  StreamSubscription? _subscription;

  TasksNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final data = ref.read(dataProvider);
    final auth = ref.read(authProvider);
    
    if (!auth.isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }

    final workspaceId = auth.currentWorkspace?.id ?? 'default';
    
    try {
      final initialTasks = await data.getTasks(workspaceId);
      state = AsyncValue.data(initialTasks);

      _subscription?.cancel();
      _subscription = data.taskUpdates.listen((update) {
        state.whenData((tasks) {
          final currentTasks = List<MatrixTask>.from(tasks);
          final index = currentTasks.indexWhere((t) => t.id == update.id);
          if (index != -1) {
            currentTasks[index] = update;
          } else {
            // Only add if it belongs to the current workspace
            if (update.workspaceId == workspaceId) {
              currentTasks.add(update);
            }
          }
          state = AsyncValue.data(currentTasks);
        });
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _init();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
