# 🌸 GEMINIFLO_ — Aplikasi Booking Papan Bunga
> **"EXPRESSED WITH ELEGANCE."**

GEMINIFLO_ adalah aplikasi mobile Flutter terintegrasi untuk pemesanan, persewaan, dan pengelolaan papan bunga (Pernikahan, Grand Opening, Ulang Tahun, Wisuda, Duka Cita, dan Promosi) dengan antarmuka elegan dan dukungan multi-role (Pelanggan & Admin).

---

## 🔐 Akun dan data

Akun pelanggan dibuat melalui formulir pendaftaran dan disimpan di Neon. Satu-satunya akun admin adalah `geminiflo@admin.com` dengan kata sandi `admin000`. Backend menyinkronkan kredensial ini ke Neon saat mulai. Email admin lain tidak dipromosikan. Backend menghapus akun contoh lama `geminiflo@user.com`, `user@geminiflo.com`, dan `admin@geminiflo.com` saat migrasi.

Booking pelanggan disimpan ke Neon dengan user ID dari sesi login. Panel admin menampilkan data kontak akun dan detail acara dari booking tersebut.

### API Vercel dan Neon

API produksi dideploy sebagai Vercel Functions di `https://geminiflo-api.vercel.app/api`. `DATABASE_URL` disimpan sebagai environment variable **Sensitive** di Vercel, bukan di aplikasi Flutter atau Git. Login Google juga memerlukan `FIREBASE_PROJECT_ID` di Vercel dengan nilai `geminiflo-3d7f0` (Production, Preview, dan Development sesuai environment yang dipakai); backend memvalidasi Firebase ID token terhadap proyek tersebut. Vercel tidak memerlukan `FIREBASE_WEB_API_KEY` untuk alur login ini. Untuk menjalankan backend Dart lokal, `FIREBASE_WEB_API_KEY` tetap diperlukan. Untuk menjalankan bootstrap manual, masukkan `DATABASE_URL` ke `.env.local` yang diabaikan Git lalu jalankan `npm run db:bootstrap`; gunakan hanya saat migrasi awal yang memang diperlukan. Reset kata sandi memerlukan `RESEND_API_KEY` dan `MAIL_FROM` di Environment Variables Vercel.

Build release Flutter otomatis memakai URL API production. Build debug tetap memakai backend lokal. Untuk mengubah URL saat build, gunakan `--dart-define=API_BASE_URL=https://geminiflo-api.vercel.app/api`.

```bash
flutter build appbundle --release
flutter build apk --release
flutter build ipa --release
```

Build iOS harus dijalankan pada macOS dengan Xcode.

---

## ✨ Fitur Utama Aplikasi

1. **Identitas Brand Baru & Logo Resmi:**
   * Logo lingkaran eksklusif dengan aksen Rose & Emerald (`AppLogo`).
   * Desain AppBar hijau dengan teks dan ikon kontras putih yang bersih.
   * Tombol kembali (*Back Button*) pintar di setiap halaman sub-menu.

2. **Upload Foto Produk & Bukti Pembayaran:**
   * Mendukung pemilihan foto langsung dari **Galeri HP** maupun **Kamera HP** secara native (`image_picker`).
   * Dilengkapi izin (*permission*) kamera dan galeri Android di mode Release APK.

3. **Multi-role Navigation & Routing:**
   * Menggunakan `go_router` dengan pemisahan alur otomatis antara *User* dan *Admin*.
   * Error Handling 404 jika halaman tidak ditemukan.

4. **Kalkulasi Biaya & Status Real-time:**
   * Perhitungan transparan biaya sewa, biaya pengiriman, dan biaya instalasi.
   * Status pesanan lengkap (*Pending Payment*, *Waiting Verification*, *Confirmed*, *Processing*, *Ready*, *Completed*, *Cancelled*).

---

## 🛠️ Petunjuk Jalankan Aplikasi (Development)

### Login Google dan sinkronisasi database

1. Daftarkan aplikasi Android dengan application ID `com.geminiflo.geminiflo_booking` di proyek Firebase, aktifkan provider Google pada Firebase Authentication, lalu letakkan `google-services.json` di `android/app/google-services.json`.
2. Pastikan OAuth SHA-1/SHA-256 untuk signing key aplikasi terdaftar pada aplikasi Android Firebase. Jangan menaruh service-account private key di aplikasi Flutter.
3. Project ID pada konfigurasi saat ini adalah `geminiflo-3d7f0`. Atur `FIREBASE_PROJECT_ID` yang sama di Vercel. Untuk backend lokal Dart, atur juga `FIREBASE_WEB_API_KEY` memakai nilai Web API key dari konfigurasi Firebase; backend lokal memverifikasi token lewat Firebase Identity Toolkit.
4. Sebelum versi API baru dipakai di Neon, jalankan SQL pada `database/migrations/20261125_google_auth_reviews_returns.sql` melalui Neon SQL Editor. Migrasi menambahkan identitas Firebase, waktu pengembalian, tabel ulasan, dan indeks ulasan.

Login Google menghasilkan sesi GEMINIFLO setelah token Firebase diverifikasi. Role admin tetap berasal dari akun yang sudah terdaftar di backend.

1. **Atur koneksi backend:**
   Atur `NEON_DATABASE_URL` di lingkungan backend. Atur juga `RESEND_API_KEY` dan `MAIL_FROM` dari domain pengirim Resend yang sudah diverifikasi untuk mengirim tautan reset kata sandi; `APP_RESET_URL` opsional (default tautan aplikasi `geminiflo://reset-password`). Jalankan `run_backend.bat` dari folder proyek. API tersedia di port `8000` dan terhubung ke Neon; aplikasi tidak memakai database lokal untuk akun, katalog, alamat, booking, pembayaran, notifikasi, atau pelanggan.
   Android emulator menggunakan `10.0.2.2`; HP fisik harus memakai alamat IP LAN komputer melalui `--dart-define=API_BASE_URL=http://<IP-KOMPUTER>:8000/api`.

2. **Jalankan Pub Get:**
   ```bash
   flutter pub get
   ```

3. **Jalankan Unit Test:**
   ```bash
   flutter test
   ```

4. **Jalankan Aplikasi di Emulator / HP (Debug):**
   ```bash
   flutter run
   ```

5. **Build APK Siap Install di Android (Release):**
   ```bash
   flutter build apk --release
   ```
   *File APK hasil build berada di:*
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 🎨 Teknologi & Library

* **Framework:** Flutter & Dart (Material 3)
* **State Management:** Riverpod (`flutter_riverpod`)
* **Routing:** `go_router`
* **Image Picker:** `image_picker`
* **Network & Storage:** `dio`, `flutter_secure_storage`, `shared_preferences`
* **Design & Typography:** `google_fonts` (Plus Jakarta Sans & Serif Accent)
