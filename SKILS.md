# Architecture & Engineering Standards — GEMINIFLO (SKILS.md)

*Catatan: Dokumen ini sinkron dengan [SKILLS.md](file:///c:/Users/VIVOBOOK/OneDrive%20-%20Business/FILE/Pictures/GEMINIFLO/SKILLS.md).*

Silakan baca panduan lengkap arsitektur, standar Riverpod 3, integrasi Neon Serverless PostgreSQL, dan konvensi Clean Architecture pada:
👉 **[SKILLS.md](file:///c:/Users/VIVOBOOK/OneDrive%20-%20Business/FILE/Pictures/GEMINIFLO/SKILLS.md)**

### Ringkasan Cepat:
- **Arsitektur**: Feature-First Clean Architecture (`core/` & `features/{feature}/domain,data,presentation`).
- **State Management**: Flutter Riverpod 3 (`^3.4.3`) menggunakan `Notifier` & `NotifierProvider`.
- **Database**: Neon Serverless PostgreSQL (`ep-snowy-haze-at8e3hc2-pooler.c-9.us-east-1.aws.neon.tech`).
- **Kualitas Kode**: 0 error, 0 warning, 0 lint pada `flutter analyze`.
- **Testing**: `flutter test` wajib lulus 100%.
