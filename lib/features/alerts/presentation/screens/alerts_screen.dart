import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doodledry/core/constants/app_colors.dart';
import 'package:doodledry/core/constants/app_text_styles.dart';
import 'package:doodledry/core/utils/date_formatter.dart';
import 'package:doodledry/features/alerts/data/models/alert_model.dart';
import 'package:doodledry/features/alerts/presentation/providers/alert_provider.dart';
import 'package:doodledry/shared/widgets/custom_card.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  AlertSeverity? _selectedSeverityFilter;

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertsListProvider).value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredAlerts = _selectedSeverityFilter == null
        ? alerts
        : alerts.where((a) => a.severity == _selectedSeverityFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Safety Alerts',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (alerts.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'mark_all') {
                  ref.read(alertRepositoryProvider).markAllAsSeen();
                } else if (val == 'clear_all') {
                  ref.read(alertRepositoryProvider).clearAll();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded, size: 18),
                      SizedBox(width: 8),
                      Text("Mark all as read"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text("Clear all alerts", style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text("All (${alerts.length})"),
                      selected: _selectedSeverityFilter == null,
                      onSelected: (_) => setState(() => _selectedSeverityFilter = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.crisis_alert_rounded, color: AppColors.danger, size: 16),
                      label: Text("Critical (${alerts.where((a) => a.severity == AlertSeverity.critical).length})"),
                      selected: _selectedSeverityFilter == AlertSeverity.critical,
                      onSelected: (_) => setState(() => _selectedSeverityFilter = AlertSeverity.critical),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                      label: Text("Warnings (${alerts.where((a) => a.severity == AlertSeverity.warning).length})"),
                      selected: _selectedSeverityFilter == AlertSeverity.warning,
                      onSelected: (_) => setState(() => _selectedSeverityFilter = AlertSeverity.warning),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.info_outline, color: AppColors.info, size: 16),
                      label: Text("Info (${alerts.where((a) => a.severity == AlertSeverity.info).length})"),
                      selected: _selectedSeverityFilter == AlertSeverity.info,
                      onSelected: (_) => setState(() => _selectedSeverityFilter = AlertSeverity.info),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Alerts List
            Expanded(
              child: filteredAlerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 48,
                            color: AppColors.success.withOpacity(0.8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No Alerts Found",
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "All sensor readings are currently within normal thresholds.",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: filteredAlerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final alert = filteredAlerts[index];
                        return _buildAlertCard(alert, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(AlertModel alert, bool isDark) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      border: !alert.isSeen
          ? Border.all(color: alert.severity.color, width: 1.5)
          : null,
      onTap: () {
        ref.read(alertRepositoryProvider).markAsSeen(alert.id);
        _showAlertDetails(alert);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: alert.severity.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(alert.severity.icon, color: alert.severity.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        alert.title,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: alert.isSeen ? FontWeight.w600 : FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!alert.isSeen)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: alert.severity.color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "NEW",
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (alert.readingValue != null)
                      Text(
                        "Reading: ${alert.readingValue}",
                        style: AppTextStyles.label.copyWith(
                          color: alert.severity.color,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Text(
                      AppDateFormatter.formatRelativeTime(alert.timestamp),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(AlertModel alert) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(alert.severity.icon, color: alert.severity.color),
              const SizedBox(width: 10),
              Flexible(child: Text(alert.title, style: AppTextStyles.titleMedium)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alert.message, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              if (alert.readingValue != null) ...[
                _buildModalRow("Recorded Reading", alert.readingValue!),
                const SizedBox(height: 6),
              ],
              if (alert.sensorType != null) ...[
                _buildModalRow("Sensor Subsystem", alert.sensorType!),
                const SizedBox(height: 6),
              ],
              _buildModalRow("Device ID", alert.deviceId),
              const SizedBox(height: 6),
              _buildModalRow("Timestamp", AppDateFormatter.formatDateTime(alert.timestamp)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
