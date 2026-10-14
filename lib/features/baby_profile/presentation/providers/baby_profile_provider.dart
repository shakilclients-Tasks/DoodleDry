import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/baby_profile_model.dart';
import '../../data/repositories/baby_profile_repository.dart';

final babyProfileRepositoryProvider = Provider<BabyProfileRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final repo = BabyProfileRepository(storage);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final currentBabyProfileProvider = StreamProvider<BabyProfileModel?>((ref) {
  final repo = ref.watch(babyProfileRepositoryProvider);
  return repo.profileStream;
});
