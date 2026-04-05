import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';
import 'dart:io';

Future<void> main() async {
  final env = DotEnv()..load(['../../.env']);
  
  final projectId = env['APPWRITE_PROJECT_ID'] ?? 'matrix_dev';
  final projectName = env['APPWRITE_PROJECT_NAME'] ?? 'Matrix Organization';
  final apiKey = env['APPWRITE_LOCAL_API_KEY'] ?? 'standard_a84dcce7e8ab43315ff21487e0da61819601488d6cbb6478a6e36c91374bd9ef732e10dcbbfa9963f27b504e8c49c711a43095dcd1d216d128120a52f9e8303c1eab5cd661882f251dfe27e177d4840cb11193d3d837eb14a643250fae2eaf0f115abe0a6e90789dbb38441ac8fce576d59591b676ed7457afbc0b3558c1cd1f';
  
  // For host execution, port 80 is usually preferred if 8080 is for adb reverse
  var endpoint = env['APPWRITE_ENDPOINT'] ?? 'http://localhost/v1';
  if (endpoint.contains('localhost:8080')) {
    print('Detected Android-specific localhost:8080. Switching to http://localhost/v1 for host setup.');
    endpoint = 'http://localhost/v1';
  }
  
  const dbId = 'main';

  print('--- Matrix Appwrite Deep Setup ---');
  print('Target Project ID: $projectId');
  print('Endpoint: $endpoint');

  // 1. Create Platforms (Allowing apps to connect)
  final platforms = [
    {'type': 'android', 'name': 'HQ Android', 'key': 'com.hejitech.hq'},
    {'type': 'android', 'name': 'Agent Android', 'key': 'com.hejitech.agent'},
    {'type': 'linux', 'name': 'HQ Linux', 'key': 'com.hejitech.hq'},
    {'type': 'linux', 'name': 'Agent Linux', 'key': 'com.hejitech.agent'},
  ];

  for (final platform in platforms) {
    try {
      print('Creating platform: ${platform['name']}...');
      final response = await http.post(
        Uri.parse('$endpoint/projects/$projectId/platforms'),
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': 'console',
          'X-Appwrite-Key': apiKey,
        },
        body: jsonEncode({
          'type': platform['type'],
          'name': platform['name'],
          'key': platform['key'],
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('  Platform created successfully.');
      } else {
        print('  Platform status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('  Error creating platform: $e');
    }
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
    print('  Database created.');
  } catch (e) {
    if (e.toString().contains('already exists')) {
      print('  Database already exists.');
    } else {
      print('  Database status: $e');
    }
  }

  // 3. Create Collections and Attributes
  final collectionConfigs = {
    'agents': {
      'name': 'Agents Registry',
      'attributes': [
        {'key': 'workspace_id', 'type': 'string', 'size': 50, 'required': true},
        {'key': 'name', 'type': 'string', 'size': 255, 'required': true},
        {'key': 'role', 'type': 'string', 'size': 50, 'required': true},
        {'key': 'status', 'type': 'string', 'size': 50, 'required': true},
        {'key': 'capability_statement', 'type': 'string', 'size': 10000, 'required': true},
      ]
    },
    'tasks': {
      'name': 'Matrix Tasks',
      'attributes': [
        {'key': 'workspace_id', 'type': 'string', 'size': 50, 'required': true},
        {'key': 'title', 'type': 'string', 'size': 255, 'required': true},
        {'key': 'description', 'type': 'string', 'size': 10000, 'required': true},
        {'key': 'content', 'type': 'string', 'size': 65535, 'required': false},
        {'key': 'status', 'type': 'string', 'size': 50, 'required': true},
        {'key': 'priority', 'type': 'string', 'size': 50, 'required': true},
        {'key': 'assigned_to', 'type': 'string', 'size': 50, 'required': false},
        {'key': 'parent_task_id', 'type': 'string', 'size': 50, 'required': false},
        {'key': 'repository_url', 'type': 'string', 'size': 500, 'required': false},
        {'key': 'artifacts', 'type': 'string', 'size': 255, 'required': false, 'array': true},
      ]
    },
    'messages': {
      'name': 'Communication Logs',
      'attributes': [
        {'key': 'workspace_id', 'type': 'string', 'size': 50, 'required': true},
        {'key': 'sender_id', 'type': 'string', 'size': 50, 'required': true},
        {'key': 'content', 'type': 'string', 'size': 10000, 'required': true},
        {'key': 'timestamp', 'type': 'string', 'size': 50, 'required': true},
        {'key': 'thread_id', 'type': 'string', 'size': 50, 'required': false},
      ]
    },
  };

  for (final collId in collectionConfigs.keys) {
    final config = collectionConfigs[collId]!;
    try {
      print('Creating collection: $collId...');
      await databases.createCollection(
        databaseId: dbId,
        collectionId: collId,
        name: config['name'] as String,
        permissions: [
          Permission.read(Role.any()),
          Permission.write(Role.users()),
        ],
      );
      print('  Collection created.');
    } catch (e) {
      if (e.toString().contains('already exists')) {
        print('  Collection already exists.');
      } else {
        print('  Collection status: $e');
      }
    }

    final attributes = config['attributes'] as List<Map<String, dynamic>>;
    for (final attr in attributes) {
      try {
        final key = attr['key'] as String;
        print('  Creating attribute $collId.$key...');
        
        if (attr['type'] == 'string') {
          await databases.createStringAttribute(
            databaseId: dbId,
            collectionId: collId,
            key: key,
            size: attr['size'] as int,
            xrequired: attr['required'] as bool,
            array: attr['array'] as bool? ?? false,
          );
        }
        
        print('    Attribute created.');
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        if (e.toString().contains('already exists')) {
          print('    Attribute already exists.');
        } else {
          print('    Attribute error: $e');
        }
      }
    }
  }

  print('--- Setup Complete ---');
}
