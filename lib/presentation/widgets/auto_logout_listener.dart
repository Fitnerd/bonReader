import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../providers/auth_state.dart';

/// Wrappt den authentifizierten Bereich der App und meldet den Nutzer
/// nach Inaktivitaet (oder beim Backgrounding) automatisch ab.
///
/// - Jede Geste setzt den Timer zurueck.
/// - Wenn die App in den Hintergrund geht, wird sofort ausgeloggt
///   (sicherer als Timer, weil das OS die App jederzeit beenden kann).
class AutoLogoutListener extends ConsumerStatefulWidget {
  const AutoLogoutListener({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: AppConstants.defaultAutoLogoutMinutes),
  });

  final Widget child;
  final Duration timeout;

  @override
  ConsumerState<AutoLogoutListener> createState() => _AutoLogoutListenerState();
}

class _AutoLogoutListenerState extends ConsumerState<AutoLogoutListener>
    with WidgetsBindingObserver {
  Timer? _timer;

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
    _timer = Timer(widget.timeout, _logout);
  }

  void _logout() {
    ref.read(authStateProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Jede Touch-Bewegung im Auth-Bereich resettet den Timer.
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
