import 'package:yaml/yaml.dart';

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
  final String? content; // The full markdown content with YAML front matter

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
    this.content,
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
      content: map['content'],
    );
  }

  /// Synthesizes the full markdown content from the task metadata and description.
  String synthesizeContent() {
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('id: $id');
    buffer.writeln('workspace_id: $workspaceId');
    buffer.writeln('title: "$title"');
    buffer.writeln('status: $status');
    buffer.writeln('priority: $priority');
    if (assignedTo != null) buffer.writeln('assigned_to: $assignedTo');
    if (parentTaskId != null) buffer.writeln('parent_task_id: $parentTaskId');
    if (artifacts.isNotEmpty) {
      buffer.writeln('artifacts:');
      for (final artifact in artifacts) {
        buffer.writeln('  - $artifact');
      }
    }
    buffer.writeln('---');
    buffer.writeln();
    buffer.write(description);
    return buffer.toString();
  }

  /// Parses a markdown string with YAML front matter into a MatrixTask.
  static MatrixTask parseContent(String content, {String? id, String? workspaceId}) {
    if (!content.startsWith('---')) {
      return MatrixTask(
        id: id ?? '',
        workspaceId: workspaceId ?? '',
        title: 'Untitled',
        description: content,
        status: 'pending',
        priority: 'normal',
        content: content,
      );
    }

    final parts = content.split('---');
    if (parts.length < 3) {
      return MatrixTask(
        id: id ?? '',
        workspaceId: workspaceId ?? '',
        title: 'Untitled',
        description: content,
        status: 'pending',
        priority: 'normal',
        content: content,
      );
    }

    final yamlMap = loadYaml(parts[1]) as YamlMap;
    final description = parts.sublist(2).join('---').trim();

    return MatrixTask(
      id: yamlMap['id']?.toString() ?? id ?? '',
      workspaceId: yamlMap['workspace_id']?.toString() ?? workspaceId ?? '',
      title: yamlMap['title']?.toString() ?? 'Untitled',
      description: description,
      status: yamlMap['status']?.toString() ?? 'pending',
      priority: yamlMap['priority']?.toString() ?? 'normal',
      assignedTo: yamlMap['assigned_to']?.toString(),
      parentTaskId: yamlMap['parent_task_id']?.toString(),
      artifacts: yamlMap['artifacts'] != null ? List<String>.from(yamlMap['artifacts']) : const [],
      content: content,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workspace_id': workspaceId,
      'title': title,
      'description': description,
      'content': synthesizeContent(),
      'assigned_to': assignedTo,
      'status': status,
      'priority': priority,
      'parent_task_id': parentTaskId,
      'artifacts': artifacts,
    };
  }

  /// Creates a copy of this task with the given fields replaced.
  MatrixTask copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? description,
    String? assignedTo,
    String? status,
    String? priority,
    String? parentTaskId,
    List<String>? artifacts,
    String? content,
  }) {
    return MatrixTask(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      artifacts: artifacts ?? this.artifacts,
      content: content ?? this.content,
    );
  }
}
