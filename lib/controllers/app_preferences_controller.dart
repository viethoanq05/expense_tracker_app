import 'dart:collection';
import 'dart:convert';

import 'package:expense_tracker_app/localization/app_strings.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesController extends ChangeNotifier {
  AppPreferencesController._(
    this._preferences, {
    required ThemeMode themeMode,
    required AppLanguage language,
    required Map<String, double> budgets,
    required bool pinLockEnabled,
    required String? pinCodeHash,
  }) : _themeMode = themeMode,
       _language = language,
       _budgets = budgets,
       _pinLockEnabled = pinLockEnabled,
       _pinCodeHash = pinCodeHash;

  static const _themeModeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _budgetsKey = 'budgets';
  static const _pinLockKey = 'pin_lock_enabled';
  static const _pinCodeHashKey = 'pin_code_hash';

  final SharedPreferences _preferences;

  ThemeMode _themeMode;
  AppLanguage _language;
  Map<String, double> _budgets;
  bool _pinLockEnabled;
  String? _pinCodeHash;
  int _lockRequestToken = 0;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  Map<String, double> get budgets => UnmodifiableMapView(_budgets);
  bool get pinLockEnabled => _pinLockEnabled;
  bool get hasPinCode => (_pinCodeHash ?? '').isNotEmpty;
  int get lockRequestToken => _lockRequestToken;

  static Future<AppPreferencesController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final themeMode = ThemeMode.values.byName(
      preferences.getString(_themeModeKey) ?? ThemeMode.light.name,
    );
    final language = AppLanguage.fromCode(
      preferences.getString(_languageKey) ?? AppLanguage.en.code,
    );

    final budgetsRaw = preferences.getString(_budgetsKey);
    final budgets = <String, double>{};
    if (budgetsRaw != null && budgetsRaw.isNotEmpty) {
      final decoded = jsonDecode(budgetsRaw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final value = (entry.value as num?)?.toDouble();
        if (value != null && value > 0) {
          budgets[entry.key] = value;
        }
      }
    }

    return AppPreferencesController._(
      preferences,
      themeMode: themeMode,
      language: language,
      budgets: budgets,
      pinLockEnabled: preferences.getBool(_pinLockKey) ?? false,
      pinCodeHash: preferences.getString(_pinCodeHashKey),
    );
  }

  double? budgetFor(String category) => _budgets[category];

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) {
      return;
    }

    _themeMode = themeMode;
    await _preferences.setString(_themeModeKey, themeMode.name);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) {
      return;
    }

    _language = language;
    await _preferences.setString(_languageKey, language.code);
    notifyListeners();
  }

  Future<void> setBudgets(Map<String, double?> budgets) async {
    final nextBudgets = Map<String, double>.from(_budgets);

    for (final entry in budgets.entries) {
      final value = entry.value;
      if (value == null || value <= 0) {
        nextBudgets.remove(entry.key);
      } else {
        nextBudgets[entry.key] = value;
      }
    }

    _budgets = nextBudgets;
    final encoded = jsonEncode(_budgets);
    await _preferences.setString(_budgetsKey, encoded);
    notifyListeners();
  }

  Future<void> setPinLockEnabled(bool enabled) async {
    if (_pinLockEnabled == enabled) {
      return;
    }

    if (enabled && !hasPinCode) {
      return;
    }

    _pinLockEnabled = enabled;
    await _preferences.setBool(_pinLockKey, enabled);
    notifyListeners();
  }

  Future<void> savePinCode(String pin) async {
    _pinCodeHash = _hashPin(pin);
    _pinLockEnabled = true;
    _lockRequestToken++;
    await _preferences.setString(_pinCodeHashKey, _pinCodeHash!);
    await _preferences.setBool(_pinLockKey, true);
    notifyListeners();
  }

  void requestPinLock() {
    if (!pinLockEnabled || !hasPinCode) {
      return;
    }

    _lockRequestToken++;
    notifyListeners();
  }

  Future<void> clearPinCode() async {
    _pinCodeHash = null;
    _pinLockEnabled = false;
    await _preferences.remove(_pinCodeHashKey);
    await _preferences.setBool(_pinLockKey, false);
    notifyListeners();
  }

  bool verifyPinCode(String pin) {
    if (!hasPinCode) {
      return true;
    }

    return _pinCodeHash == _hashPin(pin);
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }
}
