import 'dart:async';
import 'package:appwrite/appwrite.dart';
import '../interfaces/i_auth_provider.dart';
import '../models/workspace.dart';

class AppwriteAuthProvider implements IAuthProvider {
  final Client client;
  final Account _account;
  final Teams _teams;
  
  final _authStateController = StreamController<bool>.broadcast();
  Workspace? _currentWorkspace;
  bool _isAuthenticated = false;

  AppwriteAuthProvider(this.client)
      : _account = Account(client),
        _teams = Teams(client) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _account.get();
      _isAuthenticated = true;
    } catch (_) {
      _isAuthenticated = false;
    }
    _authStateController.add(_isAuthenticated);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
    // After sign up, we don't sign in automatically as per standard Appwrite practice.
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _account.createEmailPasswordSession(email: email, password: password);
    _isAuthenticated = true;
    _authStateController.add(true);
  }

  @override
  Future<void> signOut() async {
    await _account.deleteSession(sessionId: 'current');
    _isAuthenticated = false;
    _currentWorkspace = null;
    _authStateController.add(false);
  }

  @override
  Future<List<Workspace>> getWorkspaces() async {
    final teamsList = await _teams.list();
    return teamsList.teams.map((team) => Workspace(id: team.$id, name: team.name)).toList();
  }

  @override
  Future<Workspace> createWorkspace({required String name}) async {
    final team = await _teams.create(teamId: ID.unique(), name: name);
    return Workspace(id: team.$id, name: team.name);
  }

  @override
  Future<void> selectWorkspace(String workspaceId) async {
    final team = await _teams.get(teamId: workspaceId);
    _currentWorkspace = Workspace(id: team.$id, name: team.name);
  }

  @override
  Workspace? get currentWorkspace => _currentWorkspace;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;
  
  void dispose() {
    _authStateController.close();
  }
}
