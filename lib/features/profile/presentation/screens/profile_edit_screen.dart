import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_form_field.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _picker = ImagePicker();
  String? _avatarPreview;
  bool _avatarChanged = false;
  bool _isPickingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _avatarPreview = user.avatar;
      if (user.phone != null) _phoneCtrl.text = user.phone!;
    }
  }

  Future<void> _pickAvatar() async {
    setState(() => _isPickingAvatar = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final extension = file.name.split('.').last.toLowerCase();
      final mimeType = file.mimeType ?? switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      if (!mounted) return;
      setState(() {
        _avatarPreview = 'data:$mimeType;base64,${base64Encode(bytes)}';
        _avatarChanged = true;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil tidak dapat dibuka. Coba pilih gambar lain.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingAvatar = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authStateProvider.notifier).updateProfile(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
          avatar: _avatarChanged ? _avatarPreview : null,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profil berhasil diperbarui' : 'Gagal memperbarui profil'),
          backgroundColor: success ? AppColors.statusSuccess : AppColors.statusError,
        ),
      );
      if (success) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RouteNames.profile);
        }
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.profile),
        ),
        title: const Text('Edit Profil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondary, width: 2),
                      color: AppColors.surfaceWhite,
                    ),
                    child: ClipOval(
                      child: _avatarPreview == null || _avatarPreview!.isEmpty
                          ? const AppLogo(size: 100)
                          : ProductImage(source: _avatarPreview, fit: BoxFit.cover),
                    ),
                  ),
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: AppColors.primary,
                    child: _isPickingAvatar
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : IconButton(
                            tooltip: 'Pilih foto profil',
                            onPressed: _pickAvatar,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 19),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _isPickingAvatar ? null : _pickAvatar,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Ganti Foto Profil'),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthFormField(
                label: 'Nama Lengkap',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AuthFormField(
                label: 'Nomor HP',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Simpan Perubahan',
                onPressed: _save,
                isLoading: authState.isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
