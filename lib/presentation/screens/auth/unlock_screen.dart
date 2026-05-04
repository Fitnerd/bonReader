import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/auth_state.dart';

/// Sperrbildschirm. Loest beim Erscheinen automatisch den Biometrie-
/// Prompt aus. Bei Fehlschlag oder Abbruch kann der Nutzer es erneut
/// versuchen oder den Account zuruecksetzen.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  bool _autoTriggered = false;

  @override
  void initState() {
    super.initState();
    // Biometrie-Prompt direkt nach dem Aufbau ausloesen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoTriggered) {
        _autoTriggered = true;
        _unlock();
      }
    });
  }

  Future<void> _unlock() async {
    await ref.read(authStateProvider.notifier).unlock();
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wirklich zuruecksetzen?'),
        content: const Text(
          'Alle Bons, Budgets und Kategorien werden unwiederbringlich '
          'geloescht. Danach steht die App wieder am Anfang. '
          'Diese Aktion kann nicht rueckgaengig gemacht werden.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authStateProvider.notifier).resetAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authStateProvider);
    final isWorking = auth.value?.status == AuthStatus.unlocking;
    final error = auth.value?.errorMessage;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 48),
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tippe auf "Entsperren", um deine Daten freizugeben.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (error != null) ...<Widget>[
                const SizedBox(height: 24),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: isWorking ? null : _unlock,
                icon: const Icon(Icons.fingerprint_rounded),
                label: isWorking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Entsperren'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: isWorking ? null : _confirmReset,
                child: Text(
                  'Account zuruecksetzen',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
