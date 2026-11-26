import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String token;
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });
  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _done = false;
  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.length < 8 || _password.text != _confirmation.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi minimal 8 karakter dan harus sama.'),
        ),
      );
      return;
    }
    final ok = await ref
        .read(authStateProvider.notifier)
        .resetPassword(
          email: widget.email,
          token: widget.token,
          password: _password.text,
          passwordConfirmation: _confirmation.text,
        );
    if (!mounted) return;
    if (ok) {
      setState(() => _done = true);
    } else {
      final error = ref.read(authStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Tautan reset tidak valid atau sudah kedaluwarsa.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: const Text('Atur Kata Sandi Baru'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: _done
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.statusSuccess,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text('Kata sandi berhasil diperbarui.'),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Masuk',
                  onPressed: () => context.go(RouteNames.login),
                  width: double.infinity,
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Akun ${widget.email}'),
                const SizedBox(height: 18),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata sandi baru',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmation,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Ulangi kata sandi',
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Simpan Kata Sandi',
                  onPressed: _submit,
                  isLoading: ref.watch(authStateProvider).isLoading,
                  width: double.infinity,
                ),
              ],
            ),
    ),
  );
}
