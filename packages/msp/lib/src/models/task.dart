class MatrixTask {
  final String id;
  final String workspaceId;
  final String title;
  final String description;
  final String? assignedTo;
  final String status;
  final String priority;
  final String? parentTaskId;
  final List<String> artifacts;

  MatrixTask({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.description,
    this.assignedTo,
    required this.status,
    required this.priority,
    this.parentTaskId,
    this.artifacts = const [],
  });

  factory MatrixTask.fromMap(Map<String, dynamic> map) {
    return MatrixTask(
      id: map['\$id'] ?? map['id'] ?? '',
      workspaceId: map['workspace_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assignedTo: map['assigned_to'],
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 'normal',
      parentTaskId: map['parent_task_id'],
      artifacts: List<String>.from(map['artifacts'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workspace_id': workspaceId,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'status': status,
      'priority': priority,
      'parent_task_id': parentTaskId,
      'artifacts': artifacts,
    };
  }
}
