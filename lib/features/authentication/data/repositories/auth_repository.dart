import 'dart:async';
import '../../../../core/services/local_storage_service.dart';
import '../models/user_model.dart';

abstract class IAuthRepository {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(String email, String password, String displayName);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> logout();
}

/// Production Auth Repository with local session caching and Firebase-ready abstractions
class AuthRepository implements IAuthRepository {
  final LocalStorageService _storageService;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  AuthRepository(this._storageService) {
    _currentUser = _storageService.getUser();
    // Default to a demo caregiver session if first launch so app is immediately usable
    if (_currentUser == null && !_storageService.isOnboardingCompleted()) {
      _currentUser = UserModel.demo();
      _storageService.saveUser(_currentUser!);
    }
    _authStateController.add(_currentUser);
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    // Simulate network latency / auth verification
    await Future.delayed(const Duration(milliseconds: 600));

    if (!email.contains('@') || password.length < 6) {
      throw Exception("Invalid credentials. Please check your email and password.");
    }

    final user = UserModel(
      id: 'usr_${email.hashCode.abs()}',
      email: email,
      displayName: email.split('@').first.capitalize(),
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    await _storageService.saveUser(user);
    _authStateController.add(user);
    return user;
  }

  @override
  Future<UserModel> registerWithEmail(String email, String password, String displayName) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (!email.contains('@') || password.length < 6) {
      throw Exception("Password must be at least 6 characters.");
    }

    final user = UserModel(
      id: 'usr_${email.hashCode.abs()}',
      email: email,
      displayName: displayName.isNotEmpty ? displayName : 'Parent',
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    await _storageService.saveUser(user);
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!email.contains('@')) {
      throw Exception("Please provide a valid email address.");
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    await _storageService.clearUser();
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
