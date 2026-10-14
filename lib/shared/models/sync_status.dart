/// Cloud & database synchronization states
enum SyncStatus {
  synced,
  syncing,
  offline,
  syncFailed;

  String get displayName {
    switch (this) {
      case SyncStatus.synced:
        return 'Synced with Cloud';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offline:
        return 'Offline Mode (Local Cache)';
      case SyncStatus.syncFailed:
        return 'Sync Failed';
    }
  }
}
