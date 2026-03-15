import 'package:expense_tracker_app/controllers/app_preferences_controller.dart';
import 'package:flutter/widgets.dart';

class AppPreferencesScope extends InheritedNotifier<AppPreferencesController> {
  const AppPreferencesScope({
    super.key,
    required AppPreferencesController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppPreferencesController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPreferencesScope>();
    assert(scope != null, 'AppPreferencesScope is missing in the widget tree.');
    return scope!.notifier!;
  }

  static AppPreferencesController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<AppPreferencesScope>();
    final scope = element?.widget as AppPreferencesScope?;
    assert(scope != null, 'AppPreferencesScope is missing in the widget tree.');
    return scope!.notifier!;
  }
}
