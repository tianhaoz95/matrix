class Agent {
  final String id;
  final String workspaceId;
  final String name;
  final String role;
  final String status;
  final String capabilityStatement;

  Agent({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.role,
    required this.status,
    required this.capabilityStatement,
  });

  factory Agent.fromMap(Map<String, dynamic> map) {
    return Agent(
      id: map['\$id'] ?? map['id'] ?? '',
      workspaceId: map['workspace_id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      status: map['status'] ?? '',
      capabilityStatement: map['capability_statement'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workspace_id': workspaceId,
      'name': name,
      'role': role,
      'status': status,
      'capability_statement': capabilityStatement,
    };
  }
}
