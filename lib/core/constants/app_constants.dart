class AppConstants {
  AppConstants._();

  static const String appName = 'Geminiflo Booking';
  static const String appSubtitle = 'Sewa Papan Bunga Eksklusif & Florist Event';
  static const String businessName = 'Geminiflo_';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyUserRole = 'user_role';
  static const String keyOnboardingSeen = 'onboarding_seen';
  static const String keyMockMode = 'use_mock_data';

  // Default Business Values (overridden dynamically via API)
  static const String defaultWhatsApp = '6281298765432';
  static const String defaultAdminPhone = '+62 811-9988-7711';
  static const int defaultPaymentExpirationMinutes = 60;
  static const double defaultDeliveryFee = 50000;
  static const double defaultInstallationFee = 35000;
  static const int defaultFreeOngkirRadiusKm = 10;
}
