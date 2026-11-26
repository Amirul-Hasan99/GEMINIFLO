class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => message;

  factory ApiException.fromStatusCode(int? code, [dynamic data]) {
    switch (code) {
      case 400:
        return ApiException(
          message:
              'Permintaan tidak valid. Silakan periksa data yang dimasukkan.',
          statusCode: code,
          data: data,
        );
      case 401:
        return ApiException(
          message: data is Map && data['message'] != null
              ? data['message'].toString()
              : 'Sesi login telah berakhir. Silakan masuk kembali.',
          statusCode: code,
          data: data,
        );
      case 403:
        return ApiException(
          message: data is Map && data['message'] != null
              ? data['message'].toString()
              : 'Anda tidak memiliki hak akses untuk halaman atau tindakan ini.',
          statusCode: code,
          data: data,
        );
      case 404:
        return ApiException(
          message: 'Data atau halaman yang dicari tidak ditemukan.',
          statusCode: code,
          data: data,
        );
      case 422:
        String validationMsg = 'Data yang dikirim tidak valid.';
        if (data is Map && data['message'] != null) {
          validationMsg = data['message'].toString();
        } else if (data is Map && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
            validationMsg = errors.values.first is List
                ? (errors.values.first as List).first.toString()
                : errors.values.first.toString();
          }
        }
        return ApiException(
          message: validationMsg,
          statusCode: code,
          data: data,
        );
      case 429:
        return ApiException(
          message: 'Terlalu banyak permintaan. Silakan tunggu beberapa saat.',
          statusCode: code,
          data: data,
        );
      case 500:
      case 502:
      case 503:
        return ApiException(
          message:
              'Terjadi kesalahan pada server. Tim kami sedang menanganinya.',
          statusCode: code,
          data: data,
        );
      default:
        return ApiException(
          message: 'Terjadi kendala yang tidak terduga. Silakan coba kembali.',
          statusCode: code,
          data: data,
        );
    }
  }

  factory ApiException.networkError() {
    return const ApiException(
      message:
          'Tidak ada koneksi internet. Periksa koneksi data atau Wi-Fi Anda.',
      statusCode: null,
    );
  }

  factory ApiException.timeout() {
    return const ApiException(
      message: 'Waktu koneksi habis. Silakan coba beberapa saat lagi.',
      statusCode: null,
    );
  }
}
