import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ledger_theme.dart';
import '../../../../shared/widgets/ledger_widgets.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(authControllerProvider.notifier)
        .login(_nikController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 36),
            Text(
              'Posyandu Desa',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: LedgerColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catatan tumbuh kembang dan tindak lanjut balita.',
              style: TextStyle(color: LedgerColors.inkSoft, height: 1.4),
            ),
            const SizedBox(height: 32),
            TextField(
              key: const Key('nikField'),
              controller: _nikController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'NIK / NIP'),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('passwordField'),
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              InlineMessage(text: auth.error!, isError: true),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.isSubmitting ? null : _submit,
              child: Text(auth.isSubmitting ? 'Memeriksa...' : 'Masuk'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Butuh bantuan akun? Hubungi bidan atau kader koordinator.',
              style: TextStyle(color: LedgerColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
