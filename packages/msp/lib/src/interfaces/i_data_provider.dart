import '../models/task.dart';
import '../models/agent.dart';
import '../models/message.dart';

abstract class IDataProvider {
  // Tasks
  Future<List<MatrixTask>> getTasks(String workspaceId);
  Future<MatrixTask> createTask(MatrixTask task);
  Future<MatrixTask> updateTask(MatrixTask task);
  Stream<MatrixTask> get taskUpdates;

  // Agents
  Future<List<Agent>> getAgents(String workspaceId);
  Future<Agent> registerAgent(Agent agent);
  Future<Agent> updateAgent(Agent agent);
  Stream<Agent> get agentUpdates;

  // Messages
  Future<List<Message>> getMessages(String workspaceId, {String? threadId});
  Future<Message> sendMessage(Message message);
  Stream<Message> get messageUpdates;
}
