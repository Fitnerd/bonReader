import 'package:flutter/material.dart';
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
    final asyncTimeout = ref.watch(autoLogoutMinutesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _SectionTitle(label: 'Sicherheit', theme: theme),
          const _BiometricStatusTile(),
          const Divider(height: 1),
          asyncTimeout.when(
            loading: () => const ListTile(
              leading: Icon(Icons.timer_outlined),
              title: Text('Auto-Logout'),
              subtitle: Text('Lade…'),
            ),
            error: (e, _) => const ListTile(
              leading: Icon(Icons.timer_outlined),
              title: Text('Auto-Logout'),
              subtitle:
                  Text('Einstellung konnte nicht geladen werden.'),
            ),
            data: (minutes) => _AutoLogoutTile(minutes: minutes),
          ),
          const SizedBox(height: 24),
          _SectionTitle(label: 'Daten', theme: theme),
          ListTile(
            leading: Icon(
              Icons.delete_forever_rounded,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Account und alle Daten loeschen',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text(
                'Unwiderruflich. Setzt die App auf Werkseinstellungen zurueck.'),
            onTap: () => _showResetSheet(context),
          ),
          const SizedBox(height: 24),
          _SectionTitle(label: 'Ueber', theme: theme),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Ueber ${AppConstants.appName}'),
            subtitle: const Text('Lokal, privacy-first, keine Cloud.'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: AppConstants.appName,
              applicationLegalese:
                  'Alle Daten bleiben lokal auf diesem Geraet. '
                  'AES-256 verschluesselte Datenbank. Zugriff per '
                  'Biometrie / Geraete-PIN.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_rounded),
            title: const Text('Open-Source-Lizenzen'),
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
    final available = _available;
    return ListTile(
      leading: const Icon(Icons.fingerprint_rounded),
      title: const Text('Biometrie / Geraete-PIN'),
      subtitle: Text(
        switch (available) {
          null => 'Pruefe…',
          true =>
            'Aktiv. Nur Biometrie oder Geraete-PIN gibt Zugriff frei.',
          false =>
            'Auf dem Geraet ist keine Biometrie eingerichtet. '
                'Bitte System-Einstellungen pruefen.',
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
                  'Auto-Logout',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Text(
                '$minutes ${minutes == 1 ? 'Minute' : 'Minuten'}',
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
            label: '$minutes Min',
            onChanged: (v) {
              ref
                  .read(autoLogoutMinutesProvider.notifier)
                  .set(v.round());
            },
          ),
          Text(
            'Nach so vielen Minuten ohne Bedienung wirst du abgemeldet. '
            'Beim Wechsel in den Hintergrund passiert das sofort, '
            'unabhaengig vom Wert.',
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
        const SnackBar(
            content: Text('Account und alle Daten geloescht.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Fehler beim Zuruecksetzen.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Wirklich alles loeschen?',
        style: TextStyle(color: theme.colorScheme.error),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Account, alle Kategorien, Budgets und Ausgaben werden '
            'unwiderruflich entfernt. Es gibt keinen Backup.',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
                'Mir ist klar, dass das nicht rueckgaengig zu machen ist.'),
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
          child: const Text('Abbrechen'),
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
              : const Text('Endgueltig loeschen'),
        ),
      ],
    );
  }
}
