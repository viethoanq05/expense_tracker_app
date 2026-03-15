import 'package:expense_tracker_app/localization/app_strings.dart';
import 'package:expense_tracker_app/widgets/app_preferences_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String? _error;

  void _unlock() {
    final preferences = AppPreferencesScope.read(context);
    final strings = AppStrings(preferences.language);
    final pin = _pin.trim();

    if (preferences.verifyPinCode(pin)) {
      FocusScope.of(context).unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onUnlocked();
        }
      });
    } else {
      setState(() {
        _error = strings.pinIncorrect;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesScope.read(context);
    final strings = AppStrings(preferences.language);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 80, color: colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  strings.appTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.pinPrompt,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: strings.pinFieldLabel,
                    errorText: _error,
                  ),
                  onChanged: (value) {
                    _pin = value;
                    if (_error != null) {
                      setState(() {
                        _error = null;
                      });
                    }
                  },
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _unlock,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: Text(strings.pinUnlockLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
