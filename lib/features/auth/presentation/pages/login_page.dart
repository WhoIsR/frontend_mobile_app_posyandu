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
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: LedgerColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LedgerColors.line),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SoftIcon(icon: Icons.health_and_safety_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Posyandu ML',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: LedgerColors.ink,
                              ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Catatan tumbuh kembang dan tindak lanjut balita.',
                          style: TextStyle(
                            color: LedgerColors.inkSoft,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      key: const Key('nikField'),
                      controller: _nikController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'NIK / NIP',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('passwordField'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: 12),
                      InlineMessage(text: auth.error!, isError: true),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: auth.isSubmitting ? null : _submit,
                      child: Text(auth.isSubmitting ? 'Memeriksa...' : 'Masuk'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const InlineMessage(
              text: 'Butuh bantuan akun? Hubungi bidan atau kader koordinator.',
            ),
          ],
        ),
      ),
    );
  }
}
