import '../models/workspace.dart';

abstract class IAuthProvider {
  Future<void> signUp({required String email, required String password, required String name});
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  
  Future<List<Workspace>> getWorkspaces();
  Future<Workspace> createWorkspace({required String name});
  Future<void> selectWorkspace(String workspaceId);
  
  Workspace? get currentWorkspace;
  bool get isAuthenticated;
  
  Stream<bool> get authStateChanges;
}
