import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;
    final avatar = user?.avatar;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1B6B4D)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: ClipOval(
                        child: avatar == null || avatar.isEmpty
                            ? const AppLogo(size: 54, isCircle: true)
                            : ProductImage(source: avatar, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Pengguna',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (user?.username?.isNotEmpty == true)
                            Text(
                              '@${user!.username}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          if (user?.phone != null)
                            Text(
                              user!.phone!,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 9,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit profil',
                      onPressed: () => context.push(RouteNames.profileEdit),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Akun dan bantuan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 720 ? 4 : 2;
                    final shortcuts = <_ProfileShortcutData>[
                      _ProfileShortcutData(
                        Icons.location_on_outlined,
                        'Alamat',
                        () => context.push(RouteNames.addresses),
                      ),
                      _ProfileShortcutData(
                        Icons.lock_outline,
                        'Ubah password',
                        () => context.push(RouteNames.changePassword),
                      ),
                      _ProfileShortcutData(
                        Icons.notifications_outlined,
                        'Notifikasi',
                        () => context.push(RouteNames.notifications),
                      ),
                      _ProfileShortcutData(
                        Icons.help_outline,
                        'Bantuan & FAQ',
                        () => context.push(RouteNames.help),
                      ),
                      _ProfileShortcutData(
                        Icons.privacy_tip_outlined,
                        'Privasi',
                        () => context.push(RouteNames.privacyPolicy),
                      ),
                      _ProfileShortcutData(
                        Icons.description_outlined,
                        'Syarat',
                        () => context.push(RouteNames.termsConditions),
                      ),
                      _ProfileShortcutData(
                        Icons.info_outline,
                        'Tentang',
                        () => context.push(RouteNames.about),
                      ),
                    ];
                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: shortcuts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        mainAxisExtent:
                            (constraints.maxHeight -
                                ((shortcuts.length / columns).ceil() - 1) * 8) /
                            (shortcuts.length / columns).ceil(),
                      ),
                      itemBuilder: (context, index) =>
                          _ProfileShortcut(data: shortcuts[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                text: 'Keluar',
                type: ButtonType.danger,
                onPressed: () => _logout(context, ref),
                width: double.infinity,
                icon: const Icon(
                  Icons.logout_outlined,
                  size: 18,
                  color: AppColors.statusError,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go(RouteNames.home);
              break;
            case 1:
              context.go(RouteNames.catalog);
              break;
            case 2:
              context.go(RouteNames.orders);
              break;
          }
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar dari Aplikasi?'),
        content: const Text('Anda akan keluar dari akun Geminiflo_ Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.statusError),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }
}

class _ProfileShortcutData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileShortcutData(this.icon, this.label, this.onTap);
}

class _ProfileShortcut extends StatelessWidget {
  final _ProfileShortcutData data;

  const _ProfileShortcut({required this.data});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(data.icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                data.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    ),
  );
}
