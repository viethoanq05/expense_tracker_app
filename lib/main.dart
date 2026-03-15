import 'package:expense_tracker_app/controllers/app_preferences_controller.dart';
import 'package:expense_tracker_app/localization/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:expense_tracker_app/screens/app_shell_screen.dart';
import 'package:expense_tracker_app/services/firebase_bootstrap.dart';
import 'package:expense_tracker_app/theme/app_theme.dart';
import 'package:expense_tracker_app/widgets/app_preferences_scope.dart';
import 'package:expense_tracker_app/widgets/pin_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  final preferencesController = await AppPreferencesController.load();
  runApp(ExpenseTrackerApp(controller: preferencesController));
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key, required this.controller});

  final AppPreferencesController controller;

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final strings = AppStrings(widget.controller.language);

        return AppPreferencesScope(
          controller: widget.controller,
          child: MaterialApp(
            title: strings.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: widget.controller.themeMode,
            locale: widget.controller.language.locale,
            supportedLocales: AppLanguage.values
                .map((language) => language.locale)
                .toList(growable: false),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const PinGate(child: AppShellScreen()),
          ),
        );
      },
    );
  }
}
