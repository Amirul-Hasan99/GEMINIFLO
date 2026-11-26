import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/product_image.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _picker = ImagePicker();
  String? _avatarData;
  bool _isPickingAvatar = false;
  bool _agreeToTerms = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authStateProvider.notifier);
    final username = _usernameCtrl.text.trim();
    final password = _passCtrl.text;

    final success = await notifier.register(
      name: _nameCtrl.text.trim(),
      username: username,
      email: _emailCtrl.text.trim().toLowerCase(),
      phone: _phoneCtrl.text.trim(),
      avatar: _avatarData,
      password: password,
      passwordConfirmation: password,
    );
    if (!mounted) return;
    if (success) {
      final auth = ref.read(authStateProvider);
      if (auth.isAdmin) {
        context.go(RouteNames.adminDashboard);
      } else {
        context.go(RouteNames.home);
      }
    } else {
      final error = ref.read(authStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Registrasi gagal. Silakan coba lagi.'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  Future<void> _pickProfilePhoto() async {
    setState(() => _isPickingAvatar = true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 70,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final extension = image.name.split('.').last.toLowerCase();
      final mimeType =
          image.mimeType ??
          switch (extension) {
            'png' => 'image/png',
            'webp' => 'image/webp',
            _ => 'image/jpeg',
          };
      if (!mounted) return;
      setState(
        () => _avatarData = 'data:$mimeType;base64,${base64Encode(bytes)}',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto tidak dapat dibuka. Coba pilih gambar lain.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Daftar Akun Baru',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceWhite,
                              border: Border.all(
                                color: AppColors.secondary,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _avatarData == null
                                  ? const ColoredBox(
                                      color: AppColors.background,
                                      child: Icon(
                                        Icons.person_outline_rounded,
                                        size: 58,
                                        color: AppColors.textMuted,
                                      ),
                                    )
                                  : ProductImage(
                                      source: _avatarData,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: _isPickingAvatar
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : IconButton(
                                    tooltip: 'Pilih foto profil dari perangkat',
                                    onPressed: _pickProfilePhoto,
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _isPickingAvatar ? null : _pickProfilePhoto,
                        icon: Icon(
                          _avatarData == null
                              ? Icons.photo_library_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: Text(
                          _avatarData == null
                              ? 'Pilih Foto Profil dari Perangkat'
                              : 'Foto Profil Dipilih · Ganti Foto',
                        ),
                      ),
                      const Text(
                        'Foto ini akan tersimpan pada profil akun Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AuthFormField(
                  label: 'Nama Lengkap',
                  hint: 'masukkan nama lengkap Anda',
                  controller: _nameCtrl,
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, 'Nama lengkap'),
                ),
                const SizedBox(height: AppSpacing.md),
                AuthFormField(
                  label: 'Username',
                  hint: 'buat username, contoh: amirul_01',
                  controller: _usernameCtrl,
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final username = value?.trim() ?? '';
                    if (username.isEmpty) return 'Username wajib diisi.';
                    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._]{2,29}$')
                        .hasMatch(username)) {
                      return 'Gunakan 3–30 karakter: huruf, angka, titik, atau garis bawah.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AuthFormField(
                  label: 'Email',
                  hint: 'nama@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthFormField(
                  label: 'Nomor Telepon / WhatsApp (Wajib)',
                  hint: 'contoh: 081234567890',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthFormField(
                  label: 'Password',
                  hint: 'masukkan password Anda',
                  controller: _passCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_outlined,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Terms agreement
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _agreeToTerms,
                        onChanged: (v) =>
                            setState(() => _agreeToTerms = v ?? true),
                        activeColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Saya menyetujui Syarat & Ketentuan Geminiflo',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: 'Daftar Sekarang',
                  onPressed: _register,
                  isLoading: authState.isLoading,
                  width: double.infinity,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
