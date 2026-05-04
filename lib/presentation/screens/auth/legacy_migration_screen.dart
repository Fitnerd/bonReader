import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/auth_state.dart';

/// Einmaliger Migrations-Screen. Eine alte Installation hatte ein
/// Argon2-Passwort. Wir verlangen es einmal, verifizieren, schalten
/// auf Biometrie um und loeschen den alten Hash.
class LegacyMigrationScreen extends ConsumerStatefulWidget {
  const LegacyMigrationScreen({super.key});

  @override
  ConsumerState<LegacyMigrationScreen> createState() =>
      _LegacyMigrationScreenState();
}

class _LegacyMigrationScreenState
    extends ConsumerState<LegacyMigrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.clear();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authStateProvider.notifier)
        .migrateFromLegacy(_passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      _passwordCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authStateProvider);
    final isWorking = auth.value?.status == AuthStatus.unlocking;
    final error = auth.value?.errorMessage;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 32),
                Icon(
                  Icons.upgrade_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.legacyMigrationTitle(AppConstants.appName),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.legacyMigrationExplanation,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.legacyMigrationOldPasswordLabel,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? l10n.legacyMigrationEmptyError
                      : null,
                ),
                if (error != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    error,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isWorking ? null : _submit,
                  child: isWorking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.legacyMigrationButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
