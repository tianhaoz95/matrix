import 'package:dart_appwrite/dart_appwrite.dart';

Future<void> main() async {
  final client = Client()
      .setEndpoint('http://localhost/v1')
      .setProject('console') // Default project for admin actions
      .setKey('standard_a84dcce7e8ab43315ff21487e0da61819601488d6cbb6478a6e36c91374bd9ef732e10dcbbfa9963f27b504e8c49c711a43095dcd1d216d128120a52f9e8303c1eab5cd661882f251dfe27e177d4840cb11193d3d837eb14a643250fae2eaf0f115abe0a6e90789dbb38441ac8fce576d59591b676ed7457afbc0b3558c1cd1f')
      .setSelfSigned(status: true);

  final projects = Projects(client);
  final databases = Databases(client);

  const projectId = 'matrix_dev';
  const dbId = 'main';

  print('--- Matrix Appwrite Setup ---');

  // 1. Create Project
  try {
    print('Creating project: $projectId...');
    await projects.create(
      projectId: projectId,
      name: 'Matrix Organization',
    );
    print('Project created successfully.');
  } catch (e) {
    print('Project might already exist: $e');
  }

  // Update client to use the new project
  client.setProject(projectId);

  // 2. Create Database
  try {
    print('Creating database: $dbId...');
    await databases.create(databaseId: dbId, name: 'Matrix Core');
    print('Database created.');
  } catch (e) {
    print('Database might already exist.');
  }

  // 3. Create Collections
  final collections = {
    'agents': 'Agents Registry',
    'tasks': 'Matrix Tasks',
    'messages': 'Communication Logs',
  };

  for (final entry in collections.entries) {
    try {
      print('Creating collection: ${entry.key}...');
      await databases.createCollection(
        databaseId: dbId,
        collectionId: entry.key,
        name: entry.value,
        permissions: [
          Permission.read(Role.any()),
          Permission.write(Role.users()),
        ],
      );
      
      // Basic attributes for tasks as example
      if (entry.key == 'tasks') {
        await databases.createStringAttribute(databaseId: dbId, collectionId: 'tasks', key: 'title', size: 255, xrequired: true);
        await databases.createStringAttribute(databaseId: dbId, collectionId: 'tasks', key: 'status', size: 50, xrequired: true);
        await databases.createStringAttribute(databaseId: dbId, collectionId: 'tasks', key: 'workspace_id', size: 50, xrequired: true);
      }
      
      print('Collection ${entry.key} created.');
    } catch (e) {
      print('Collection ${entry.key} might already exist.');
    }
  }

  print('--- Setup Complete ---');
}
