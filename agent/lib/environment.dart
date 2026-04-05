class Environment {
  static const String appwriteProjectId = String.fromEnvironment('APPWRITE_PROJECT_ID', defaultValue: 'matrix_dev');
  static const String appwriteProjectName = String.fromEnvironment('APPWRITE_PROJECT_NAME', defaultValue: 'Matrix Organization');
  static const String appwritePublicEndpoint = String.fromEnvironment('APPWRITE_ENDPOINT', defaultValue: 'http://localhost/v1');
}
