import 'dart:collection';
import 'dart:convert';

import 'package:expense_tracker_app/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesController extends ChangeNotifier {
  AppPreferencesController._(
    this._preferences, {
    required ThemeMode themeMode,
    required AppLanguage language,
    required Map<String, double> budgets,
  }) : _themeMode = themeMode,
       _language = language,
       _budgets = budgets;

  static const _themeModeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _budgetsKey = 'budgets';

  final SharedPreferences _preferences;

  ThemeMode _themeMode;
  AppLanguage _language;
  Map<String, double> _budgets;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  Map<String, double> get budgets => UnmodifiableMapView(_budgets);

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
}
