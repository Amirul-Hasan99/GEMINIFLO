class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? (json['status'] == 'success' || json['status'] == true),
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?,
      errors: json['errors'],
    );
  }
}
