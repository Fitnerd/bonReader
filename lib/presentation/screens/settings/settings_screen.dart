import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_providers.dart';
import '../../providers/auth_state.dart';
import '../../providers/settings_state.dart';

/// Einstellungen: Biometrie-Status, Auto-Logout, Account zuruecksetzen,
/// Lizenzen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final asyncTimeout = ref.watch(autoLogoutMinutesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _SectionTitle(label: l10n.settingsSecuritySection, theme: theme),
          const _BiometricStatusTile(),
          const Divider(height: 1),
          asyncTimeout.when(
            loading: () => ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.settingsAutoLogoutTitle),
              subtitle: Text(l10n.settingsAutoLogoutLoading),
            ),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.settingsAutoLogoutTitle),
              subtitle: Text(l10n.settingsAutoLogoutLoadError),
            ),
            data: (minutes) => _AutoLogoutTile(minutes: minutes),
          ),
          const SizedBox(height: 24),
          _SectionTitle(label: l10n.settingsDataSection, theme: theme),
          ListTile(
            leading: Icon(
              Icons.delete_forever_rounded,
              color: theme.colorScheme.error,
            ),
            title: Text(
              l10n.settingsDeleteAccountTitle,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: Text(l10n.settingsDeleteAccountSubtitle),
            onTap: () => _showResetSheet(context),
          ),
          const SizedBox(height: 24),
          _SectionTitle(label: l10n.settingsAboutSection, theme: theme),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(l10n.settingsAboutAppTitle(AppConstants.appName)),
            subtitle: Text(l10n.settingsAboutSubtitle),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: AppConstants.appName,
              applicationLegalese: l10n.settingsAboutLegalese,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_rounded),
            title: Text(l10n.settingsLicensesTitle),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetSheet(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _ResetAccountDialog(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.theme});
  final String label;
  final ThemeData theme;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 4),
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

/// Reine Statusanzeige - Biometrie ist im Biometrie-Only-Modell immer
/// aktiv. Falls auf dem Geraet nichts eingerichtet ist, leitet der
/// Hinweis zur System-Einstellung.
class _BiometricStatusTile extends ConsumerStatefulWidget {
  const _BiometricStatusTile();

  @override
  ConsumerState<_BiometricStatusTile> createState() =>
      _BiometricStatusTileState();
}

class _BiometricStatusTileState
    extends ConsumerState<_BiometricStatusTile> {
  bool? _available;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await ref.read(biometricServiceProvider).isAvailable();
    if (!mounted) return;
    setState(() => _available = ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final available = _available;
    return ListTile(
      leading: const Icon(Icons.fingerprint_rounded),
      title: Text(l10n.settingsBiometricsTitle),
      subtitle: Text(
        switch (available) {
          null => l10n.settingsBiometricsChecking,
          true => l10n.settingsBiometricsActive,
          false => l10n.settingsBiometricsNone,
        },
      ),
    );
  }
}

class _AutoLogoutTile extends ConsumerWidget {
  const _AutoLogoutTile({required this.minutes});
  final int minutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.timer_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.settingsAutoLogoutTitle,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Text(
                l10n.settingsAutoLogoutValue(minutes),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: minutes.toDouble(),
            min: AppConstants.minAutoLogoutMinutes.toDouble(),
            max: AppConstants.maxAutoLogoutMinutes.toDouble(),
            divisions: AppConstants.maxAutoLogoutMinutes -
                AppConstants.minAutoLogoutMinutes,
            label: l10n.settingsAutoLogoutSliderLabel(minutes),
            onChanged: (v) {
              ref
                  .read(autoLogoutMinutesProvider.notifier)
                  .set(v.round());
            },
          ),
          Text(
            l10n.settingsAutoLogoutDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetAccountDialog extends ConsumerStatefulWidget {
  const _ResetAccountDialog();

  @override
  ConsumerState<_ResetAccountDialog> createState() =>
      _ResetAccountDialogState();
}

class _ResetAccountDialogState extends ConsumerState<_ResetAccountDialog> {
  bool _confirmed = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (!_confirmed) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Reset triggert Biometrie-Prompt nicht direkt – der User hat sich
      // ja gerade authentifiziert, um in die Settings zu kommen. Wir
      // verlassen uns auf die Auto-Logout-Suppression beim
      // Bestaetigungs-Klick.
      await ref.read(authStateProvider.notifier).resetAccount();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsResetSnack)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = l10n.settingsResetError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        l10n.settingsResetTitle,
        style: TextStyle(color: theme.colorScheme.error),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.settingsResetBody),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l10n.settingsResetConfirmCheck),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: (_busy || !_confirmed) ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.settingsResetConfirmAction),
        ),
      ],
    );
  }
}
