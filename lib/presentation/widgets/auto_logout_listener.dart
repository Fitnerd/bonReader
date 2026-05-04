import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../providers/auth_state.dart';
import '../providers/settings_state.dart';

/// Wrappt den authentifizierten Bereich der App und meldet den Nutzer
/// nach Inaktivitaet (oder beim Backgrounding) automatisch ab.
///
/// - Jede Geste setzt den Timer zurueck.
/// - Wenn die App in den Hintergrund geht, wird sofort ausgeloggt
///   (sicherer als Timer, weil das OS die App jederzeit beenden kann).
/// - Das Timeout wird live aus [autoLogoutMinutesProvider] gezogen,
///   damit Aenderungen in den Settings sofort wirken.
class AutoLogoutListener extends ConsumerStatefulWidget {
  const AutoLogoutListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoLogoutListener> createState() => _AutoLogoutListenerState();
}

class _AutoLogoutListenerState extends ConsumerState<AutoLogoutListener>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _currentMinutes = AppConstants.defaultAutoLogoutMinutes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _logout();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(minutes: _currentMinutes), _logout);
  }

  void _logout() {
    ref.read(authStateProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    // Einstellung beobachten – beim Aendern Timer neu setzen.
    ref.listen<AsyncValue<int>>(autoLogoutMinutesProvider, (prev, next) {
      final m = next.valueOrNull;
      if (m != null && m != _currentMinutes) {
        _currentMinutes = m;
        _resetTimer();
      }
    });
    final initial = ref.read(autoLogoutMinutesProvider).valueOrNull;
    if (initial != null && initial != _currentMinutes) {
      _currentMinutes = initial;
      _resetTimer();
    }

    return Listener(
      // Jede Touch-Bewegung im Auth-Bereich resettet den Timer.
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
