import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final repo = AuthRepository(storage);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});
