import 'package:expense_tracker_app/localization/app_strings.dart';
import 'package:expense_tracker_app/services/export_service.dart';
import 'package:expense_tracker_app/services/repository_registry.dart';
import 'package:expense_tracker_app/widgets/app_preferences_scope.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesScope.of(context);
    final strings = AppStrings.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            strings.settingsScreenTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.languageLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AppLanguage>(
                    initialValue: preferences.language,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.language_rounded),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: AppLanguage.en,
                        child: Text(strings.englishLabel),
                      ),
                      DropdownMenuItem(
                        value: AppLanguage.vi,
                        child: Text(strings.vietnameseLabel),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        preferences.setLanguage(value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.darkModeLabel),
                    value: preferences.themeMode == ThemeMode.dark,
                    onChanged: (enabled) {
                      preferences.setThemeMode(
                        enabled ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.exportSectionTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isExporting ? null : () => _export(false),
                    icon: _isExporting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined),
                    label: Text(
                      _isExporting
                          ? strings.exportingLabel
                          : strings.exportCsvLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isExporting ? null : () => _export(true),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: Text(strings.exportExcelLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(bool excelCompatible) async {
    setState(() {
      _isExporting = true;
    });

    final strings = AppStrings.of(context);
    final exportService = ExportService(RepositoryRegistry.expenseRepository);

    try {
      final file = await exportService.exportTransactionsToCsv(
        excelCompatible: excelCompatible,
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.exportSuccess(file.path))));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.exportFailure(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
