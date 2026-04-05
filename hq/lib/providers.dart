import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart' as client_sdk;
import 'package:dart_appwrite/dart_appwrite.dart' as server_sdk;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:msp/msp.dart';
import 'package:msp/appwrite.dart';
import 'package:flutter/foundation.dart';

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
      .setSelfSigned(status: true);
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

// A simpler, non-autodispose provider for testing reliability
final tasksStreamProvider = StreamProvider<List<MatrixTask>>((ref) async* {
  final data = ref.watch(dataProvider);
  final auth = ref.watch(authProvider);
  
  if (!auth.isAuthenticated) {
    yield [];
    return;
  }

  final workspaceId = auth.currentWorkspace?.id ?? 'default';
  
  final initialTasks = await data.getTasks(workspaceId);
  final currentTasks = List<MatrixTask>.from(initialTasks);
  yield List.unmodifiable(currentTasks);

  await for (final update in data.taskUpdates) {
    final index = currentTasks.indexWhere((t) => t.id == update.id);
    if (index != -1) {
      currentTasks[index] = update;
    } else {
      currentTasks.add(update);
    }
    yield List.unmodifiable(currentTasks);
  }
});
