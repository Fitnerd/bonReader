import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../domain/entities/user_auth.dart';
import '../../providers/auth_state.dart';
import '../../providers/settings_state.dart';

/// Einstellungen: Biometrie, Auto-Logout, Passwort aendern,
/// Account zuruecksetzen, Lizenzen.
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
          const _BiometricTile(),
          const Divider(height: 1),
          asyncTimeout.when(
            loading: () => const ListTile(
              leading: Icon(Icons.timer_outlined),
              title: Text('Auto-Logout'),
              subtitle: Text('Lade…'),
            ),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Auto-Logout'),
              subtitle: Text('Fehler: $e'),
            ),
            data: (minutes) => _AutoLogoutTile(minutes: minutes),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.password_rounded),
            title: const Text('Passwort aendern'),
            subtitle: const Text('Altes Passwort wird zur Bestaetigung benoetigt'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showChangePasswordSheet(context, ref),
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
            onTap: () => _showResetSheet(context, ref),
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
                  'AES-256 verschluesselte Datenbank, Argon2id-Passwort.',
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

  Future<void> _showChangePasswordSheet(
      BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _showResetSheet(BuildContext context, WidgetRef ref) async {
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

class _BiometricTile extends ConsumerStatefulWidget {
  const _BiometricTile();

  @override
  ConsumerState<_BiometricTile> createState() => _BiometricTileState();
}

class _BiometricTileState extends ConsumerState<_BiometricTile> {
  bool _busy = false;

  Future<void> _toggle(bool enabled) async {
    setState(() => _busy = true);
    try {
      if (enabled) {
        // Vor dem Aktivieren einmal authentifizieren, sonst koennte
        // jemand bei offener Sitzung Biometrie aktivieren und sich so
        // dauerhaft Zugang sichern.
        final biom = ref.read(biometricServiceProvider);
        final ok = await biom.authenticate(
          localizedReason: 'Biometrie aktivieren',
        );
        if (!ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometrie nicht bestaetigt.')),
            );
          }
          return;
        }
      }
      await ref
          .read(authStateProvider.notifier)
          .setBiometricEnabled(enabled: enabled);
      // AuthState neu laden waere idiomatischer; pragmatisch genuegt
      // dieser Toggle, da das Flag direkt aus DB/Storage gelesen wird.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRepo = ref.watch(authRepositoryProvider);
    return asyncRepo.when(
      loading: () => const ListTile(
        leading: Icon(Icons.fingerprint_rounded),
        title: Text('Biometrie'),
        subtitle: Text('Lade…'),
      ),
      error: (e, _) => ListTile(
        leading: const Icon(Icons.fingerprint_rounded),
        title: const Text('Biometrie'),
        subtitle: Text('Fehler: $e'),
      ),
      data: (repo) => FutureBuilder<UserAuth?>(
        future: repo.getAuth(),
        builder: (BuildContext ctx, AsyncSnapshot<UserAuth?> snap) {
          final enabled = snap.data?.biometricEnabled ?? false;
          return SwitchListTile(
            secondary: const Icon(Icons.fingerprint_rounded),
            title: const Text('Biometrie'),
            subtitle: Text(enabled
                ? 'Aktiv – Anmeldung mit Fingerabdruck/Face ID moeglich.'
                : 'Aus – Anmeldung nur per Passwort.'),
            value: enabled,
            onChanged: _busy ? null : _toggle,
          );
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
            'Beim Wechsel in den Hintergrund passiert das sofort, unabhaengig vom Wert.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.changePassword(
        oldPassword: _oldCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwort geaendert.')),
        );
      }
    } catch (e) {
      setState(() => _error = _humanize(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _humanize(Object e) {
    if (e is StateError) return e.message;
    if (e is ArgumentError) return e.message?.toString() ?? 'Ungueltige Eingabe';
    return 'Fehler beim Aendern des Passworts.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Passwort aendern',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Aktuelles Passwort'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Bitte eingeben' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Neues Passwort'),
              validator: (v) {
                if (v == null || v.length < 8) return 'Mindestens 8 Zeichen';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Neues Passwort wiederholen'),
              validator: (v) {
                if (v != _newCtrl.text) return 'Passwoerter stimmen nicht ueberein';
                return null;
              },
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Speichern'),
            ),
          ],
        ),
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
  final _passwordCtrl = TextEditingController();
  bool _confirmed = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_confirmed) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.resetAccount(_passwordCtrl.text);
      // Auth-State neu auswerten – nach resetAccount ist hasAccount() false.
      ref.invalidate(authStateProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account und alle Daten geloescht.')),
        );
      }
    } catch (e) {
      setState(() => _error = e is StateError ? e.message : 'Fehler.');
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
            'Account, Passwort, alle Kategorien, Budgets und Ausgaben '
            'werden unwiderruflich entfernt. Es gibt keinen Backup.',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Mir ist klar, dass das nicht rueckgaengig zu machen ist.'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Aktuelles Passwort',
            ),
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
