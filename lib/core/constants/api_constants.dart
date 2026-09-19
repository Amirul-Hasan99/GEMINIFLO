class ApiConstants {
  ApiConstants._();

  // Environment base URLs
  static const String devBaseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator localhost
  static const String prodBaseUrl = 'https://api.geminiflo.com/api';
  
  // Timeout configs
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Authentication Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // User Profile & Settings
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';

  // Products & Catalog
  static const String products = '/products';
  static String productDetail(String id) => '/products/$id';
  static String productAvailability(String id) => '/products/$id/availability';
  static const String categories = '/categories';

  // Favorites
  static const String favorites = '/favorites';
  static String favoriteToggle(String id) => '/products/$id/favorite';

  // Booking
  static const String bookings = '/bookings';
  static String bookingDetail(String id) => '/bookings/$id';
  static String bookingCancel(String id) => '/bookings/$id/cancel';

  // Payment
  static const String paymentMethods = '/payment-methods';
  static String bookingPayment(String bookingId) => '/bookings/$bookingId/payment';
  static String paymentDetail(String paymentId) => '/payments/$paymentId';
  static String paymentProof(String paymentId) => '/payments/$paymentId/proof';

  // Addresses
  static const String addresses = '/addresses';
  static String addressDetail(String id) => '/addresses/$id';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // Business Settings
  static const String businessSettings = '/business-settings';

  // Admin Endpoints
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static String adminProductDetail(String id) => '/admin/products/$id';
  static const String adminCategories = '/admin/categories';
  static String adminCategoryDetail(String id) => '/admin/categories/$id';
  static const String adminBookings = '/admin/bookings';
  static String adminBookingDetail(String id) => '/admin/bookings/$id';
  static String adminBookingUpdateStatus(String id) => '/admin/bookings/$id/status';
  static const String adminPayments = '/admin/payments';
  static String adminPaymentDetail(String id) => '/admin/payments/$id';
  static String adminPaymentVerify(String id) => '/admin/payments/$id/verify';
  static String adminPaymentReject(String id) => '/admin/payments/$id/reject';
  static const String adminPaymentMethods = '/admin/payment-methods';
  static String adminPaymentMethodDetail(String id) => '/admin/payment-methods/$id';
  static const String adminCustomers = '/admin/customers';
  static String adminCustomerDetail(String id) => '/admin/customers/$id';
  static const String adminReports = '/admin/reports';
  static const String adminSettings = '/admin/settings';
}
