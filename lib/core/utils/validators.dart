class Validators {
  Validators._();

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Bidang ini'} wajib diisi.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor WhatsApp/telepon wajib diisi.';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length < 9 || cleaned.length > 15) {
      return 'Nomor telepon harus antara 9–15 digit.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi.';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter.';
    }
    return null;
  }
}
