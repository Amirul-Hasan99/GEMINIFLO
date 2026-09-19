class RouteNames {
  RouteNames._();

  // Public
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // User
  static const String home = '/home';
  static const String catalog = '/catalog';
  static const String productDetail = '/product/:id';
  static String productDetailPath(String id) => '/product/$id';
  static const String favorites = '/favorites';
  static const String booking = '/booking/:productId';
  static String bookingPath(String productId) => '/booking/$productId';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String bookingSuccess = '/booking-success';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static String orderDetailPath(String id) => '/orders/$id';
  static const String payment = '/payment/:bookingId';
  static String paymentPath(String bookingId) => '/payment/$bookingId';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String addresses = '/addresses';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String changePassword = '/change-password';
  static const String help = '/help';
  static const String about = '/about';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String adminProductAdd = '/admin/products/add';
  static const String adminProductEdit = '/admin/products/:id/edit';
  static String adminProductEditPath(String id) => '/admin/products/$id/edit';
  static const String adminCategories = '/admin/categories';
  static const String adminBookings = '/admin/bookings';
  static const String adminBookingDetail = '/admin/bookings/:id';
  static String adminBookingDetailPath(String id) => '/admin/bookings/$id';
  static const String adminPayments = '/admin/payments';
  static const String adminPaymentDetail = '/admin/payments/:id';
  static String adminPaymentDetailPath(String id) => '/admin/payments/$id';
  static const String adminPaymentMethods = '/admin/payment-methods';
  static const String adminCustomers = '/admin/customers';
  static const String adminCustomerDetail = '/admin/customers/:id';
  static String adminCustomerDetailPath(String id) => '/admin/customers/$id';
  static const String adminReports = '/admin/reports';
  static const String adminProfile = '/admin/profile';
  static const String adminSettings = '/admin/settings';
}
