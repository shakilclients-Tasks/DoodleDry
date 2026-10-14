import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vital_history_entry.dart';
import '../../data/repositories/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final repo = HistoryRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final liveBufferProvider = StreamProvider<List<VitalHistoryEntry>>((ref) {
  final repo = ref.watch(historyRepositoryProvider);
  return repo.liveBufferStream;
});

final selectedTimeframeProvider = StateProvider<HistoryTimeframe>((ref) {
  return HistoryTimeframe.day;
});
