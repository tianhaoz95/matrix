class Workspace {
  final String id;
  final String name;

  Workspace({required this.id, required this.name});

  factory Workspace.fromMap(Map<String, dynamic> map) {
    return Workspace(
      id: map['\$id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
