import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/backup_service.dart';

class DataManagePage extends StatelessWidget {
  const DataManagePage({super.key});

  static const routeName = '/data-manage';

  Future<void> _exportData(BuildContext context) async {
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await BackupService.instance.exportFile(
        dialogTitle: s.exportData,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result == BackupExportResult.saved
                ? s.exportDone
                : s.exportCancelled,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Backup export failed: $e\n$st');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.exportFailed)));
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await BackupService.instance.exportCsvFile(
        dialogTitle: s.exportCsv,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result == BackupExportResult.saved
                ? s.exportCsvDone
                : s.exportCancelled,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('CSV export failed: $e\n$st');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.exportFailed)));
    }
  }

  Future<void> _importData(BuildContext context) async {    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final payload = await BackupService.instance.pickAndParse();
      if (payload == null) return;
      if (!context.mounted) return;

      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.importData),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.importDataConfirm),
              const SizedBox(height: 12),
              Text(
                s.importSummary(
                  payload.products.length,
                  payload.suppliers.length,
                  payload.units.length,
                  payload.comparisons.length,
                  categories: payload.categories.length,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.importAction),
            ),
          ],
        ),
      );
      if (ok != true) {
        if (context.mounted) {
          messenger.showSnackBar(SnackBar(content: Text(s.importCancelled)));
        }
        return;
      }

      await BackupService.instance.apply(payload);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.importDone)));
    } on FormatException catch (e) {
      debugPrint('Backup import rejected: $e');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.importInvalid)));
    } catch (e, st) {
      debugPrint('Backup import failed: $e\n$st');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.importFailed)));
    }
  }

  Future<void> _clearData(BuildContext context) async {
    final s = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.clearData),
        content: Text(s.clearDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.clearAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await BackupService.instance.clearAll();
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.clearDataDone)));
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.clearFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.dataManage),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            s.dataManageHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.ios_share_outlined, color: scheme.primary),
                  title: Text(s.exportData),
                  subtitle: Text(s.exportDataHint),
                  onTap: () => _exportData(context),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
                ListTile(
                  leading:
                      Icon(Icons.table_chart_outlined, color: scheme.primary),
                  title: Text(s.exportCsv),
                  subtitle: Text(s.exportCsvHint),
                  onTap: () => _exportCsv(context),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
                ListTile(
                  leading: Icon(Icons.download_outlined, color: scheme.primary),
                  title: Text(s.importData),
                  subtitle: Text(s.importDataHint),
                  onTap: () => _importData(context),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: scheme.error,
                  ),
                  title: Text(
                    s.clearData,
                    style: TextStyle(color: scheme.error),
                  ),
                  subtitle: Text(s.clearDataHint),
                  onTap: () => _clearData(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
