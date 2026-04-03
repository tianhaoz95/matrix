import 'dart:async';
import 'package:appwrite/appwrite.dart';
import '../interfaces/i_data_provider.dart';
import '../models/task.dart';
import '../models/agent.dart';
import '../models/message.dart';

class AppwriteDataProvider implements IDataProvider {
  final Client client;
  final String databaseId;
  final String tasksCollectionId;
  final String agentsCollectionId;
  final String messagesCollectionId;
  
  final Databases _databases;
  final Realtime _realtime;

  AppwriteDataProvider({
    required this.client,
    required this.databaseId,
    required this.tasksCollectionId,
    required this.agentsCollectionId,
    required this.messagesCollectionId,
  })  : _databases = Databases(client),
        _realtime = Realtime(client);

  @override
  Future<List<MatrixTask>> getTasks(String workspaceId) async {
    final docs = await _databases.listDocuments(
      databaseId: databaseId,
      collectionId: tasksCollectionId,
      queries: [Query.equal('workspace_id', workspaceId)],
    );
    return docs.documents.map((doc) => MatrixTask.fromMap(doc.data)).toList();
  }

  @override
  Future<MatrixTask> createTask(MatrixTask task) async {
    final doc = await _databases.createDocument(
      databaseId: databaseId,
      collectionId: tasksCollectionId,
      documentId: ID.unique(),
      data: task.toMap(),
    );
    return MatrixTask.fromMap(doc.data);
  }

  @override
  Future<MatrixTask> updateTask(MatrixTask task) async {
    final doc = await _databases.updateDocument(
      databaseId: databaseId,
      collectionId: tasksCollectionId,
      documentId: task.id,
      data: task.toMap(),
    );
    return MatrixTask.fromMap(doc.data);
  }

  @override
  Stream<MatrixTask> get taskUpdates {
    final subscription = _realtime.subscribe([
      'databases.$databaseId.collections.$tasksCollectionId.documents',
    ]);
    return subscription.stream.map((event) => MatrixTask.fromMap(event.payload));
  }

  @override
  Future<List<Agent>> getAgents(String workspaceId) async {
    final docs = await _databases.listDocuments(
      databaseId: databaseId,
      collectionId: agentsCollectionId,
      queries: [Query.equal('workspace_id', workspaceId)],
    );
    return docs.documents.map((doc) => Agent.fromMap(doc.data)).toList();
  }

  @override
  Future<Agent> registerAgent(Agent agent) async {
    final doc = await _databases.createDocument(
      databaseId: databaseId,
      collectionId: agentsCollectionId,
      documentId: agent.id.isEmpty ? ID.unique() : agent.id,
      data: agent.toMap(),
    );
    return Agent.fromMap(doc.data);
  }

  @override
  Future<Agent> updateAgent(Agent agent) async {
    final doc = await _databases.updateDocument(
      databaseId: databaseId,
      collectionId: agentsCollectionId,
      documentId: agent.id,
      data: agent.toMap(),
    );
    return Agent.fromMap(doc.data);
  }

  @override
  Stream<Agent> get agentUpdates {
    final subscription = _realtime.subscribe([
      'databases.$databaseId.collections.$agentsCollectionId.documents',
    ]);
    return subscription.stream.map((event) => Agent.fromMap(event.payload));
  }

  @override
  Future<List<Message>> getMessages(String workspaceId, {String? threadId}) async {
    final queries = [Query.equal('workspace_id', workspaceId)];
    if (threadId != null) {
      queries.add(Query.equal('thread_id', threadId));
    }
    final docs = await _databases.listDocuments(
      databaseId: databaseId,
      collectionId: messagesCollectionId,
      queries: queries,
    );
    return docs.documents.map((doc) => Message.fromMap(doc.data)).toList();
  }

  @override
  Future<Message> sendMessage(Message message) async {
    final doc = await _databases.createDocument(
      databaseId: databaseId,
      collectionId: messagesCollectionId,
      documentId: ID.unique(),
      data: message.toMap(),
    );
    return Message.fromMap(doc.data);
  }

  @override
  Stream<Message> get messageUpdates {
    final subscription = _realtime.subscribe([
      'databases.$databaseId.collections.$messagesCollectionId.documents',
    ]);
    return subscription.stream.map((event) => Message.fromMap(event.payload));
  }
}
