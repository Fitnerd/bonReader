import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_providers.dart';
import '../../providers/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final repo = await ref.read(authRepositoryProvider.future);
    final auth = await repo.getAuth();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = auth?.biometricEnabled ?? false;
    });
    // Direkt versuchen, wenn aktiviert.
    if (_biometricEnabled) {
      await ref.read(authStateProvider.notifier).loginWithBiometric();
    }
  }

  @override
  void dispose() {
    _passwordCtrl.clear();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await ref
        .read(authStateProvider.notifier)
        .loginWithPassword(_passwordCtrl.text);
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _submitBiometric() async {
    await ref.read(authStateProvider.notifier).loginWithBiometric();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final error = authState.value?.errorMessage;
    final inCooldown = authState.value?.inCooldown ?? false;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 48),
                Icon(
                  Icons.receipt_long_rounded,
                  size: 56,
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
                const Spacer(),
                TextFormField(
                  key: const Key('login-password'),
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  enabled: !inCooldown,
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
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Bitte Passwort eingeben.'
                      : null,
                  onFieldSubmitted: (_) => _submitPassword(),
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
                  onPressed: (_submitting || inCooldown) ? null : _submitPassword,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Anmelden'),
                ),
                if (_biometricEnabled) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: inCooldown ? null : _submitBiometric,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Mit Biometrie anmelden'),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
