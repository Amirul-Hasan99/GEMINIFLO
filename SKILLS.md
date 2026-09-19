# Architecture & Engineering Standards — GEMINIFLO (SKILLS.md)

Dokumen ini memuat panduan arsitektur perangkat lunak, standar konvensi kode, pola Riverpod 3, integrasi Neon Serverless PostgreSQL, dan prosedur pemeliharaan proyek **GEMINIFLO**.

---

## 1. Clean Architecture & Feature-First Structure

Kode diorganisasi menggunakan pendekatan **Feature-First**:

```
lib/
├── core/                                # Pondasi reusable global
│   ├── config/                          # AppConfig, EnvConfig, NeonConfig
│   ├── constants/                       # AppConstants (Keys, storage keys, assets)
│   ├── database/                        # Neon Database Service (PostgreSQL connection & pooler)
│   ├── network/                         # Dio client & API interceptors
│   ├── router/                          # GoRouter configuration & AppRoutes
│   ├── storage/                         # LocalStorageService, SecureStorageService
│   ├── theme/                           # AppTheme, AppColors, AppTypography, AppSpacing
│   ├── utils/                           # CurrencyFormatter, DateFormatter, Validators
│   └── widgets/                         # Reusable UI widgets (Buttons, Badges, Inputs, Shimmers)
│
└── features/                            # Modul fungsional per fitur
    ├── addresses/                       # Manajemen alamat pengiriman tersimpan
    ├── admin/                           # Dashboard admin, kelola produk, verifikasi bukti
    ├── auth/                            # Login, Register, Session & Token management
    ├── booking/                         # Kalender ketersediaan & form pemesanan papan bunga
    ├── catalog/                         # Katalog, filter kategori, search, detail produk
    ├── favorites/                       # Produk yang disimpan/disukai
    ├── home/                            # Beranda penyewa & ringkasan pesanan aktif
    ├── notifications/                   # Notifikasi status pemesanan & pembayaran
    ├── orders/                          # Riwayat pesanan & timeline pelacakan
    ├── payment/                         # Alur pembayaran, instruksi rekening, unggah bukti
    └── profile/                         # Akun, ganti info, FAQ, pengaturan
```

Setiap modul fitur mengadopsi 3 lapisan (layers):
1. **`domain/`**: Entitas bisnis (`entities/`) dan kontrak repositori (`repositories/`). Tidak boleh bergantung pada library pihak ketiga.
2. **`data/`**: Model serialisasi JSON/DB (`models/`), sumber data (`datasources/`), dan implementasi repositori (`repositories/`).
3. **`presentation/`**: Layar UI (`screens/`), widget modular (`widgets/`), dan penyedia state Riverpod (`providers/`).

---

## 2. State Management Conventions (Riverpod 3)

Proyek ini menggunakan **Flutter Riverpod 3 (`^3.4.3`)**. Aturan ketat yang harus dipatuhi:

### 2.1 Gunakan `Notifier` / `NotifierProvider`, Jangan `StateNotifier`
`StateNotifier` sudah didepresiasi. Seluruh state mutable wajib ditulis dengan turunan `Notifier<T>` atau `AsyncNotifier<T>`:

```dart
// Pola Notifier Riverpod 3
class CatalogNotifier extends Notifier<CatalogState> {
  @override
  CatalogState build() {
    return const CatalogState(products: [], isLoading: false);
  }

  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final products = await ref.read(catalogRepositoryProvider).getProducts();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final catalogProvider = NotifierProvider<CatalogNotifier, CatalogState>(
  CatalogNotifier.new,
);
```

### 2.2 Hindari Dependency Cycle di Providers
- Pisahkan penyedia data (`Provider<Repository>`) dari penyedia tampilan (`NotifierProvider`).
- Inisialisasi parameter dinamis dilakukan via method eksplisit (misal: `notifier.initialise(...)`) atau parameter method, hindari kompleksitas `family` jika menyebabkan generic type mismatch.

### 2.3 Safe Asynchronous Context
Jika memanggil navigasi atau snackbar setelah `await`, selalu amankan `BuildContext`:
```dart
final messenger = ScaffoldMessenger.of(context);
final navigator = Navigator.of(context);
await notifier.uploadProof(filePath);
if (!mounted) return;
messenger.showSnackBar(...);
navigator.pop();
```

---

## 3. Integrasi Neon Serverless PostgreSQL

### 3.1 Detail Koneksi
- **Koneksi String**: `postgresql://neondb_owner:npg_An3OriHysUC0@ep-snowy-haze-at8e3hc2-pooler.c-9.us-east-1.aws.neon.tech/GEMINIFLO?sslmode=require&channel_binding=require`
- **Host**: `ep-snowy-haze-at8e3hc2-pooler.c-9.us-east-1.aws.neon.tech`
- **Port**: `5432`
- **Database**: `GEMINIFLO`
- **User**: `neondb_owner`
- **SSL Mode**: `SslMode.require` (Wajib diaktifkan untuk Neon DB)

### 3.2 Eksekusi Prepared Statement di PostgreSQL 3.x
Driver Dart `postgres: ^3.5.15` mengeksekusi query melalui prepared statement. **Satu panggilan `connection.execute(query)` hanya boleh berisi 1 perintah SQL**. Jika menjalankan beberapa perintah DDL/DML, pisahkan ke dalam perulangan (`for (final stmt in statements) await conn.execute(stmt);`).

### 3.3 Dual-Mode Data Source (Online Neon vs Offline Mock)
Aplikasi mendukung peralihan dinamis melalui `AppConfig`:
- `AppConfig.useNeonDb = true`: Repositori akan memprioritaskan query langsung ke database Neon Serverless.
- Jika terjadi gangguan jaringan atau timeout, repositori secara otomatis fallback ke cache/mock lokal agar UX tidak crash.

---

## 4. UI/UX & Design Token Guidelines

1. **Warna**:
   - Primary: `AppColors.primary` (`#9B1B30` - Crimson Velvet Rose)
   - Secondary: `AppColors.secondary` (`#D4AF37` - Gold Ceremonial Ribbon)
   - Background: `AppColors.background` (`#FAFAFA` - Off-White)
   - Surface: `AppColors.surface` (`#FFFFFF` - Pure White)
   - Status Badge: `AppColors.statusSuccess` (`#10B981`), `AppColors.statusWarning` (`#F59E0B`), `AppColors.statusError` (`#EF4444`)
2. **Typography**: Menggunakan Google Fonts *Plus Jakarta Sans* atau *Outfit*. Selalu gunakan token `AppTypography`.
3. **Currency & Date Formatting**:
   - Selalu format mata uang dengan `CurrencyFormatter.formatIDR(nominal)` (contoh output: `Rp 750.000`).
   - Format tanggal dengan `DateFormatter.formatDateTime(date)` atau `DateFormatter.formatDate(date)` (contoh: `19 Sep 2026`).

---

## 5. Testing & Static Analysis Standard

Sebelum melakukan commit atau rilis:
1. Jalankan analisis statis:
   ```bash
   flutter analyze
   ```
   *Ekspektasi: "No issues found!" (0 error, 0 warning, 0 lint).*
2. Jalankan tes unit:
   ```bash
   flutter test
   ```
   *Ekspektasi: "All tests passed!".*
