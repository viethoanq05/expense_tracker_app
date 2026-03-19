import 'package:expense_tracker_app/controllers/app_preferences_controller.dart';
import 'package:expense_tracker_app/screens/lock_screen.dart';
import 'package:expense_tracker_app/widgets/app_preferences_scope.dart';
import 'package:flutter/material.dart';

class PinGate extends StatefulWidget {
  const PinGate({super.key, required this.child});

  final Widget child;

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> with WidgetsBindingObserver {
  AppPreferencesController? _preferences;
  bool _isLocked = false;
  bool _initialized = false;
  int _lastLockRequestToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _preferences?.removeListener(_handlePreferencesChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextPreferences = AppPreferencesScope.read(context);
    if (!identical(_preferences, nextPreferences)) {
      _preferences?.removeListener(_handlePreferencesChanged);
      _preferences = nextPreferences;
      _preferences!.addListener(_handlePreferencesChanged);
      _lastLockRequestToken = _preferences!.lockRequestToken;
    }

    if (_initialized) {
      return;
    }

    _initialized = true;
    if (_preferences!.pinLockEnabled && _preferences!.hasPinCode) {
      _isLocked = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) {
      return;
    }

    final preferences = _preferences;
    if (preferences != null &&
        preferences.pinLockEnabled &&
        preferences.hasPinCode) {
      setState(() {
        _isLocked = true;
      });
    }
  }

  void _handlePreferencesChanged() {
    final preferences = _preferences;
    if (!mounted || preferences == null) {
      return;
    }

    final shouldLock = preferences.pinLockEnabled && preferences.hasPinCode;
    final lockRequested = preferences.lockRequestToken != _lastLockRequestToken;
    _lastLockRequestToken = preferences.lockRequestToken;

    setState(() {
      if (lockRequested && shouldLock) {
        _isLocked = true;
      } else if (!shouldLock) {
        _isLocked = false;
      }
    });
  }

  void _unlock() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    final showLockScreen =
        preferences != null &&
        preferences.pinLockEnabled &&
        preferences.hasPinCode &&
        _isLocked;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (showLockScreen) LockScreen(onUnlocked: _unlock),
      ],
    );
  }
}
