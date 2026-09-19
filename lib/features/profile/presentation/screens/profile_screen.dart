import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A2B1F), Color(0xFF0F382A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + AppSpacing.md,
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: AppSpacing.xl,
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      border: Border.all(
                          color: AppColors.secondary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Pengguna',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  if (user?.phone != null)
                    Text(
                      user!.phone!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.profileEdit),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text(
                      'Edit Profil',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  _MenuSection(
                    title: 'Akun',
                    items: [
                      _MenuItem(
                        icon: Icons.location_on_outlined,
                        label: 'Alamat Pengiriman',
                        onTap: () => context.push(RouteNames.addresses),
                      ),
                      _MenuItem(
                        icon: Icons.lock_outlined,
                        label: 'Ubah Password',
                        onTap: () => context.push(RouteNames.changePassword),
                      ),
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifikasi',
                        onTap: () => context.push(RouteNames.notifications),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MenuSection(
                    title: 'Aplikasi',
                    items: [
                      _MenuItem(
                        icon: Icons.help_outline,
                        label: 'Bantuan & FAQ',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Kebijakan Privasi',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.description_outlined,
                        label: 'Syarat & Ketentuan',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.info_outline,
                        label: 'Tentang Aplikasi',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: 'Keluar',
                    type: ButtonType.danger,
                    onPressed: () => _logout(context, ref),
                    width: double.infinity,
                    icon: const Icon(Icons.logout_outlined,
                        size: 18, color: AppColors.statusError),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
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

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 4),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                e.value,
                if (!isLast)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Divider(color: AppColors.borderLight, height: 1),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
