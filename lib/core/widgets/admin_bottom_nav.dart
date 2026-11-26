import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/route_names.dart';
import '../theme/app_colors.dart';

/// Compact taskbar for the five most-used admin pages.
class AdminBottomNav extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNav({super.key, required this.currentIndex});

  static const _items = <({String label, IconData icon, String route})>[
    (
      label: 'Beranda',
      icon: Icons.dashboard_outlined,
      route: RouteNames.adminDashboard,
    ),
    (
      label: 'Produk',
      icon: Icons.local_florist_outlined,
      route: RouteNames.adminProducts,
    ),
    (
      label: 'Booking',
      icon: Icons.payments_outlined,
      route: RouteNames.adminPayments,
    ),
    (
      label: 'Pelanggan',
      icon: Icons.people_outline,
      route: RouteNames.adminCustomers,
    ),
    (
      label: 'Laporan',
      icon: Icons.bar_chart_outlined,
      route: RouteNames.adminReports,
    ),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _items.length; index++)
            Expanded(
              child: Semantics(
                button: true,
                selected: currentIndex == index,
                label: _items[index].label,
                child: InkWell(
                  onTap: () => context.go(_items[index].route),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _items[index].icon,
                          size: 20,
                          color: currentIndex == index
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[index].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: currentIndex == index
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: currentIndex == index
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
