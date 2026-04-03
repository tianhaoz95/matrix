class Message {
  final String id;
  final String workspaceId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String? threadId;

  Message({
    required this.id,
    required this.workspaceId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.threadId,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['\$id'] ?? map['id'] ?? '',
      workspaceId: map['workspace_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      threadId: map['thread_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workspace_id': workspaceId,
      'sender_id': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'thread_id': threadId,
    };
  }
}
