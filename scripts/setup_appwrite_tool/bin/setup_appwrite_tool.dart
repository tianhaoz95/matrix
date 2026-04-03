import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const projectId = 'matrix_dev';
  const dbId = 'main';
  const apiKey = 'standard_a84dcce7e8ab43315ff21487e0da61819601488d6cbb6478a6e36c91374bd9ef732e10dcbbfa9963f27b504e8c49c711a43095dcd1d216d128120a52f9e8303c1eab5cd661882f251dfe27e177d4840cb11193d3d837eb14a643250fae2eaf0f115abe0a6e90789dbb38441ac8fce576d59591b676ed7457afbc0b3558c1cd1f';
  const endpoint = 'http://localhost/v1';

  print('--- Matrix Appwrite Deep Setup ---');

  // 1. Create Project via REST API (Console API)
  try {
    print('Attempting to create project "$projectId" via REST...');
    final response = await http.post(
      Uri.parse('$endpoint/projects'),
      headers: {
        'Content-Type': 'application/json',
        'X-Appwrite-Project': 'console',
        'X-Appwrite-Key': apiKey,
      },
      body: jsonEncode({
        'projectId': projectId,
        'name': 'Matrix Organization',
        'teamId': 'matrix_team', // Optional, usually defaults
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('Project created successfully.');
    } else {
      print('Project creation status: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error creating project: $e');
  }

  // Now use standard SDK for the rest
  final client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey)
      .setSelfSigned(status: true);

  final databases = Databases(client);

  // 2. Create Database
  try {
    print('Creating database: $dbId...');
    await databases.create(databaseId: dbId, name: 'Matrix Core');
    print('Database created.');
  } catch (e) {
    print('Database status: $e');
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
      
      if (entry.key == 'tasks') {
        print('Creating attributes for tasks...');
        await databases.createStringAttribute(databaseId: dbId, collectionId: 'tasks', key: 'title', size: 255, xrequired: true);
        await databases.createStringAttribute(databaseId: dbId, collectionId: 'tasks', key: 'status', size: 50, xrequired: true);
        await databases.createStringAttribute(databaseId: dbId, collectionId: 'tasks', key: 'workspace_id', size: 50, xrequired: true);
      }
      
      print('Collection ${entry.key} initialized.');
    } catch (e) {
      print('Collection ${entry.key} status: $e');
    }
  }

  print('--- Setup Complete ---');
}
