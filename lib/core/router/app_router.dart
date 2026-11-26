import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/addresses/presentation/screens/addresses_screen.dart';
import '../../features/admin/bookings/presentation/screens/admin_booking_detail_screen.dart';
import '../../features/admin/bookings/presentation/screens/admin_bookings_screen.dart';
import '../../features/admin/customers/presentation/screens/admin_customers_screen.dart';
import '../../features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/payments/presentation/screens/admin_payment_detail_screen.dart';
import '../../features/admin/payments/presentation/screens/admin_payments_screen.dart';
import '../../features/admin/products/presentation/screens/admin_product_form_screen.dart';
import '../../features/admin/products/presentation/screens/admin_products_screen.dart';
import '../../features/admin/reports/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/reviews/presentation/screens/admin_reviews_screen.dart';
import '../../features/admin/settings/presentation/screens/admin_settings_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/booking/presentation/screens/booking_confirmation_screen.dart';
import '../../features/booking/presentation/screens/booking_form_screen.dart';
import '../../features/booking/presentation/screens/booking_success_screen.dart';
import '../../features/booking/domain/entities/booking.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/catalog/presentation/screens/product_detail_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/payment/presentation/screens/payment_proof_upload_screen.dart';
import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/profile/presentation/screens/about_app_screen.dart';
import '../../features/profile/presentation/screens/help_faq_screen.dart';
import '../../features/profile/presentation/screens/privacy_policy_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/terms_conditions_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_button.dart';
import '../router/route_names.dart';

// Listenable to trigger router refresh when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.isLoading != next.isLoading) {
        notifyListeners();
      }
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: GoRouterRefreshStream(ref),
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Halaman Tidak Ditemukan'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 80,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                '404 - Halaman Tidak Ditemukan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Maaf, halaman "${state.uri}" yang Anda tuju tidak tersedia.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                text: 'Kembali ke Beranda',
                onPressed: () => context.go(RouteNames.home),
              ),
            ],
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      if (state.uri.scheme == 'geminiflo' &&
          state.uri.host == 'reset-password') {
        return Uri(
          path: RouteNames.resetPassword,
          queryParameters: state.uri.queryParameters,
        ).toString();
      }
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.isAuthenticated;
      final isAdmin = authState.isAdmin;
      final location = state.matchedLocation;

      // While loading, stay on splash
      if (isLoading && location == RouteNames.splash) return null;

      final publicRoutes = [
        RouteNames.splash,
        RouteNames.onboarding,
        RouteNames.login,
        RouteNames.register,
        RouteNames.forgotPassword,
        RouteNames.resetPassword,
      ];
      final isPublic = publicRoutes.any((r) => location.startsWith(r));

      if (!isAuthenticated && !isPublic) return RouteNames.login;
      if (isAuthenticated &&
          isPublic &&
          location != RouteNames.splash &&
          location != RouteNames.resetPassword) {
        return isAdmin ? RouteNames.adminDashboard : RouteNames.home;
      }
      if (isAuthenticated && !isAdmin && location.startsWith('/admin')) {
        return RouteNames.home;
      }
      return null;
    },
    routes: [
      // --- Auth ---
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),

      // --- User Routes ---
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.catalog,
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: RouteNames.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/:productId',
        builder: (context, state) {
          final extra = state.extra;
          return BookingFormScreen(
            productId: state.pathParameters['productId']!,
            initialDate: extra is DateTime
                ? extra
                : extra is Map<String, dynamic>
                ? extra['initialDate'] as DateTime?
                : null,
            initialBooking: extra is Map<String, dynamic>
                ? extra['booking'] as Booking?
                : null,
          );
        },
      ),
      GoRoute(
        path: RouteNames.bookingConfirmation,
        builder: (context, state) => BookingConfirmationScreen(
          extra: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: RouteNames.bookingSuccess,
        builder: (context, state) =>
            BookingSuccessScreen(extra: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: '/payment/:bookingId',
        builder: (context, state) =>
            PaymentScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/payment/:bookingId/proof',
        builder: (context, state) => PaymentProofUploadScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.profileEdit,
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: RouteNames.addresses,
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.help,
        builder: (context, state) => const HelpFaqScreen(),
      ),
      GoRoute(
        path: '/profile/help',
        builder: (context, state) => const HelpFaqScreen(),
      ),
      GoRoute(
        path: '/help-faq',
        builder: (context, state) => const HelpFaqScreen(),
      ),
      GoRoute(
        path: RouteNames.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: RouteNames.termsConditions,
        builder: (context, state) => const TermsConditionsScreen(),
      ),
      GoRoute(
        path: RouteNames.about,
        builder: (context, state) => const AboutAppScreen(),
      ),

      // --- Admin Routes ---
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.adminProducts,
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminProductAdd,
        builder: (context, state) =>
            const AdminProductFormScreen(productId: null),
      ),
      GoRoute(
        path: '/admin/products/:id/edit',
        builder: (context, state) =>
            AdminProductFormScreen(productId: state.pathParameters['id']),
      ),
      GoRoute(
        path: RouteNames.adminBookings,
        builder: (context, state) => const AdminBookingsScreen(),
      ),
      GoRoute(
        path: '/admin/bookings/:id',
        builder: (context, state) =>
            AdminBookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.adminPayments,
        builder: (context, state) => const AdminPaymentsScreen(),
      ),
      GoRoute(
        path: '/admin/payments/:id',
        builder: (context, state) =>
            AdminPaymentDetailScreen(paymentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.adminCustomers,
        builder: (context, state) => const AdminCustomersScreen(),
      ),
      GoRoute(
        path: RouteNames.adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminReviews,
        builder: (context, state) => const AdminReviewsScreen(),
      ),
    ],
  );
});
