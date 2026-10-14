import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/alert_model.dart';
import '../../data/repositories/alert_repository.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final repo = AlertRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final alertsListProvider = StreamProvider<List<AlertModel>>((ref) {
  final repo = ref.watch(alertRepositoryProvider);
  return repo.alertsStream;
});

final unreadAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertsListProvider).value ?? [];
  return alerts.where((a) => !a.isSeen).length;
});
