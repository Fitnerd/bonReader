import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/password_validator.dart';
import '../../providers/auth_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  PasswordValidation _pwValidation = const PasswordValidation(
    isValid: false,
    hasMinLength: false,
    hasLetter: false,
    hasDigit: false,
  );

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {
      _pwValidation = PasswordValidator.validate(_passwordCtrl.text);
    });
  }

  @override
  void dispose() {
    // Defence-in-depth: Passwort-Text ueberschreiben, bevor der Controller
    // freigegeben wird, um die Verweildauer im Dart-Heap zu minimieren.
    _passwordCtrl.clear();
    _confirmCtrl.clear();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Bitte ein Passwort eingeben.';
    final result = PasswordValidator.validate(v);
    if (!result.isValid) return result.errorMessage;
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordCtrl.text) return 'Passwoerter stimmen nicht ueberein.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await ref.read(authStateProvider.notifier).register(_passwordCtrl.text);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final error = authState.value?.errorMessage;

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
                  Icons.lock_outline_rounded,
                  size: 56,
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
                const SizedBox(height: 8),
                Text(
                  'Lege ein Passwort fest. Es wird mit Argon2id gehasht und niemals im Klartext gespeichert. Wenn du es vergisst, gibt es keinen Reset – nur ein Komplett-Loeschen aller Daten.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  key: const Key('register-password'),
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Passwort',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                if (_passwordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _PasswordStrengthIndicator(validation: _pwValidation),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('register-confirm'),
                  controller: _confirmCtrl,
                  obscureText: _obscurePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Passwort wiederholen',
                  ),
                  validator: _validateConfirm,
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    error,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Account anlegen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Passwort-Staerke-Indikator mit Fortschrittsbalken und Checkliste.
class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.validation});

  final PasswordValidation validation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = validation.strength;

    Color barColor;
    String label;
    if (strength < 0.34) {
      barColor = theme.colorScheme.error;
      label = 'Schwach';
    } else if (strength < 0.67) {
      barColor = Colors.orange;
      label = 'Mittel';
    } else {
      barColor = Colors.green;
      label = 'Stark';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: LinearProgressIndicator(
                value: strength,
                backgroundColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: barColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _CheckItem(
          met: validation.hasMinLength,
          text: 'Mind. ${PasswordValidator.minLength} Zeichen',
        ),
        _CheckItem(met: validation.hasLetter, text: 'Mind. 1 Buchstabe'),
        _CheckItem(met: validation.hasDigit, text: 'Mind. 1 Ziffer'),
      ],
    );
  }
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.met, required this.text});

  final bool met;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color =
        met ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: <Widget>[
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
