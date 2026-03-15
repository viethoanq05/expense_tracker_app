import 'dart:io';

import 'package:expense_tracker_app/localization/app_strings.dart';
import 'package:expense_tracker_app/controllers/app_preferences_controller.dart';
import 'package:expense_tracker_app/screens/budget_screen.dart';
import 'package:expense_tracker_app/services/export_service.dart';
import 'package:expense_tracker_app/services/repository_registry.dart';
import 'package:expense_tracker_app/widgets/app_preferences_scope.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

// ---------------------------------------------------------------------------
// PIN dialog — owns its TextEditingControllers so they are disposed AFTER
// the dialog's closing animation finishes (widget unmount), not before.
// ---------------------------------------------------------------------------
class _PinDialog extends StatefulWidget {
  const _PinDialog({
    required this.changeExisting,
    required this.preferences,
    required this.strings,
  });

  final bool changeExisting;
  final AppPreferencesController preferences;
  final AppStrings strings;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  late final TextEditingController _currentCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _confirmCtrl;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _currentCtrl = TextEditingController();
    _pinCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final current = _currentCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    final s = widget.strings;
    if (widget.changeExisting && !widget.preferences.verifyPinCode(current)) {
      return s.pinValidationCurrentIncorrect;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) return s.pinValidationLength;
    if (pin != confirm) return s.pinValidationMismatch;
    return null;
  }

  void _submit() {
    final error = _validate();
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.of(context).pop(_pinCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return AlertDialog(
      title: Text(
        widget.changeExisting ? s.pinDialogChangeTitle : s.pinDialogTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.changeExisting) ...[
              TextField(
                controller: _currentCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(labelText: s.pinCurrentFieldLabel),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(labelText: s.pinFieldLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(labelText: s.pinConfirmFieldLabel),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.pinCancelLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(s.pinSaveLabel)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onBudgetSaved});

  final ValueChanged<int>? onBudgetSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  File? _lastExportedFile;

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
                    strings.budgetScreenTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.budgetScreenDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openBudgetScreen,
                      icon: const Icon(Icons.pie_chart_rounded),
                      label: Text(strings.budgetLabel),
                    ),
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
                    strings.securitySectionTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.pinLockDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (preferences.hasPinCode) ...[
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.lock_rounded),
                      title: Text(strings.pinEnableLabel),
                      subtitle: Text(
                        preferences.pinLockEnabled
                            ? strings.pinEnabledDescription
                            : strings.pinDisabledDescription,
                      ),
                      value: preferences.pinLockEnabled,
                      onChanged: preferences.setPinLockEnabled,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showChangePinDialog,
                            icon: const Icon(Icons.password_rounded),
                            label: Text(strings.pinChangeLabel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _removePin,
                            icon: const Icon(Icons.lock_open_rounded),
                            label: Text(strings.pinRemoveLabel),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _showSetPinDialog,
                            icon: const Icon(Icons.pin_rounded),
                            label: Text(strings.pinSetUpLabel),
                          ),
                        ),
                      ],
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isExporting || _lastExportedFile == null
                              ? null
                              : _openLastFile,
                          icon: const Icon(Icons.insert_drive_file_outlined),
                          label: Text(strings.openFileLabel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isExporting || _lastExportedFile == null
                              ? null
                              : _shareLastFile,
                          icon: const Icon(Icons.share_rounded),
                          label: Text(strings.shareFileLabel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _lastExportedFile == null
                        ? strings.noExportYetLabel
                        : '${strings.latestExportLabel} ${_lastExportedFile!.path}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetPinDialog() async {
    await _showPinDialog(changeExisting: false);
  }

  Future<void> _showChangePinDialog() async {
    await _showPinDialog(changeExisting: true);
  }

  Future<void> _showPinDialog({required bool changeExisting}) async {
    final preferences = AppPreferencesScope.read(context);
    final strings = AppStrings(preferences.language);
    final nextPin = await showDialog<String>(
      context: context,
      builder: (_) => _PinDialog(
        changeExisting: changeExisting,
        preferences: preferences,
        strings: strings,
      ),
    );

    if (nextPin != null) {
      await preferences.savePinCode(nextPin);
    }

    if (nextPin != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.pinSavedSuccess)));
    }
  }

  Future<void> _openBudgetScreen() async {
    final strings = AppStrings.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(strings.budgetScreenTitle)),
          body: BudgetScreen(
            onSaved: (exceededCount) {
              Navigator.of(context).pop();
              widget.onBudgetSaved?.call(exceededCount);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _removePin() async {
    final preferences = AppPreferencesScope.read(context);
    final strings = AppStrings(preferences.language);
    await preferences.clearPinCode();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.pinRemovedSuccess)));
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

      setState(() {
        _lastExportedFile = file;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.exportSuccess(file.path))));

      // Open immediately so user can view the exported file on emulator.
      await _openLastFile();
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

  Future<void> _openLastFile() async {
    final strings = AppStrings.of(context);
    final file = _lastExportedFile;
    if (file == null) {
      return;
    }

    try {
      final result = await OpenFilex.open(file.path);
      if (!mounted) {
        return;
      }

      if (result.type != ResultType.done) {
        final details = result.message.trim();
        final suffix = details.isEmpty ? '' : ' $details';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.openFileFailed}$suffix')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${strings.openFileFailed} ${error.toString()}'),
        ),
      );
    }
  }

  Future<void> _shareLastFile() async {
    final strings = AppStrings.of(context);
    final file = _lastExportedFile;
    if (file == null) {
      return;
    }

    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${strings.shareFileFailed} ${error.toString()}'),
        ),
      );
    }
  }
}
