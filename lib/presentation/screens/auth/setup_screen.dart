import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_providers.dart';
import '../../providers/auth_state.dart';

/// Erst-Einrichtung. Erklaert das Sicherheitsmodell und startet den
/// Biometrie-Prompt fuer das Setup.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  bool? _biometricsAvailable;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available =
        await ref.read(biometricServiceProvider).isAvailable();
    if (!mounted) return;
    setState(() => _biometricsAvailable = available);
  }

  Future<void> _startSetup() async {
    await ref.read(authStateProvider.notifier).setup();
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
              const SizedBox(height: 32),
              Icon(
                Icons.fingerprint_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Willkommen bei ${AppConstants.appName}',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Deine Daten werden lokal verschluesselt gespeichert. '
                'Zugriff bekommst du ueber Biometrie '
                '(Fingerabdruck / Gesicht) oder die Geraete-PIN.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wichtig: Es gibt keinen Cloud-Backup und kein '
                        'Recovery. Bei Geraeteverlust sind alle Bons, '
                        'Budgets und Kategorien unwiederbringlich weg.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_biometricsAvailable == false) ...<Widget>[
                Text(
                  'Auf diesem Geraet ist keine Biometrie eingerichtet. '
                  'Bitte zuerst in den System-Einstellungen einen '
                  'Fingerabdruck oder Face-ID hinterlegen und die App '
                  'neu starten.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ] else if (error != null) ...<Widget>[
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: (_biometricsAvailable == true && !isWorking)
                    ? _startSetup
                    : null,
                icon: const Icon(Icons.fingerprint_rounded),
                label: isWorking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Mit Biometrie einrichten'),
              ),
              const SizedBox(height: 8),
              if (_biometricsAvailable == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
