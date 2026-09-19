# UI/UX Design System Specification — GEMINIFLO (DESIGN.md)

**Design Philosophy**: *"Botanical Ceremonial & Modern Luxury Florist"*  
**Target Platform**: Android & iOS Mobile Devices (Touch-first, 375px–428px base viewport)  
**Prototype Reference**: `stitch_geminiflo_booking_ui_ux_design_system`  

---

## 1. Design Vision & Aesthetics

GEMINIFLO menghadirkan estetika kemewahan upacara seremonial yang dipadukan dengan kehangatan elemen botani. Visual dirancang untuk memberikan impresi premium, tenang, dan terpercaya bagi pemesan karangan bunga papan pernikahan, wisuda, duka cita, maupun peresmian korporat.

- **Karakter Visual**: Elegan, bersahaja, rapi, dengan kontras lembut antara hijau zamrud tua (*Deep Emerald*) dan aksen emas sampanye (*Champagne Gold*).
- **Surface Treatment**: Latar belakang tidak menggunakan putih murni yang silau, melainkan *Soft Cream / Warm Alabaster* (`#FBF9F5`) yang ramah mata dan terkesan mewah seperti kertas undangan seremonial bertekstur.
- **Mikro-Interaksi**: Animasi transisi halus (200ms–300ms cubic ease), efek shimmer saat memuat data katalog, serta feedback haptic saat tombol aksi ditekan.

---

## 2. Color Palette & Design Tokens

### 2.1 Brand & Neutral Colors

| Token Name | Hex Code | Deskripsi & Penggunaan |
|---|---|---|
| `AppColors.primary` | `#0F382A` | **Deep Emerald**: Warna utama identitas brand, header bar, tombol aksi primer (CTA), dan teks heading penting. |
| `AppColors.primaryLight`| `#154D39` | Emerald terang untuk aksen hover/focus state. |
| `AppColors.primaryDark` | `#002217` | Kontras gelap untuk bayangan dan elemen penekanan. |
| `AppColors.secondary` | `#C5A059` | **Muted Champagne Gold**: Warna aksen untuk badge bintang, garis aksen, border kartu premium. |
| `AppColors.goldAccent` | `#D4AF37` | Emas cerah untuk status verifikasi dan bintang rating. |
| `AppColors.background` | `#FBF9F5` | **Warm Alabaster**: Warna dasar seluruh layar aplikasi. |
| `AppColors.surfaceWhite`| `#FFFFFF` | Latar belakang kartu (*Card*), modal bottom sheet, dan form input. |
| `AppColors.border` | `#E8E2D8` | Garis pembatas tipis (*Linen Gray-Beige*) pemisah section. |

### 2.2 Typography Colors
- `AppColors.textPrimary` (`#1F2421`): Charcoal Forest untuk judul, nama produk, dan nominal harga.
- `AppColors.textSecondary` (`#565E59`): Abu-abu kehijauan untuk deskripsi paragraf dan subjudul.
- `AppColors.textMuted` (`#8C948F`): Teks keterangan waktu, placeholder input, dan ikon pasif.

### 2.3 Semantic Status Tokens (Badge Ketersediaan & Pembayaran)

| Status | Text Color | Background Color | Contoh Penggunaan |
|---|---|---|---|
| **Success** | `#1F6F43` | `#E9F5EE` | Papan Bunga `Available`, Booking `Confirmed`, Pembayaran `Paid` / Lunas. |
| **Warning** | `#9E6E18` | `#FEF6E7` | Stok `Limited` (Tersisa ≤ 2), Pembayaran `Verifying` (Menunggu Verifikasi). |
| **Error** | `#9C2A2A` | `#FDF0F0` | Slot `Unavailable` (Penuh), Pembayaran `Rejected`, Pesanan `Cancelled`. |
| **Info** | `#2E6171` | `#E8F1F5` | Pesanan `Assembling` (Sedang dirangkai di workshop), Kurir `On The Way`. |

---

## 3. Typography Hierarchy

Sistem tipografi menggunakan font modern berkarakter seremonial (*Google Fonts Plus Jakarta Sans*):

| Level | Size | Weight | Line Height | Penggunaan |
|---|---|---|---|---|
| **Display / H1** | 24px | Bold (700) | 32px | Judul utama layar (Beranda, Detail Papan Bunga, Invoice) |
| **Headline / H2** | 20px | SemiBold (600)| 28px | Judul kartu, sub-section, nama produk di katalog |
| **Title / H3** | 16px | SemiBold (600)| 24px | Nama kategori, label total bayar, nama customer |
| **Body Large** | 14px | Regular (400) | 20px | Deskripsi produk, instruksi pembayaran |
| **Body Small** | 12px | Regular (400) | 16px | Alamat pengiriman, tanggal acara, catatan kecil |
| **Caption** | 10px | Medium (500) | 14px | Badge status ketersediaan, timestamp notifikasi |

---

## 4. Spacing, Radius, & Elevation Grid

Aplikasi dibangun di atas modular **8pt Grid System**:
- `AppSpacing.xs`: 4px (Jarak ikon dengan teks badge)
- `AppSpacing.sm`: 8px (Jarak antar chip kategori)
- `AppSpacing.md`: 16px (Padding standar konten layar, margin kartu)
- `AppSpacing.lg`: 24px (Jarak vertikal antar section beranda)
- `AppSpacing.xl`: 32px (Margin bawah formulir sebelum CTA)

**Border Radius**:
- Tombol Utama & Input Field: `12px`
- Kartu Produk (*Product Card*): `16px`
- Bottom Sheet Modal: `24px` (Top-left & Top-right)
- Pill / Badge Kategori: `999px` (Full rounded)

**Shadow & Elevation**:
- Soft Card Shadow: `BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))`
- Floating CTA Bar: `BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))`

---

## 5. Screen-by-Screen Component Specifications

### 5.1 Beranda Penyewa (`geminiflo_penyewa_home`)
- **Header Seremonial**: Greeting ramah ("Selamat Datang di Geminiflo"), avatar pengguna, dan tombol notifikasi lonceng dengan dot merah.
- **Banner Promo / Highlight**: Card gradient Deep Emerald berisi promo sewa papan bunga wedding dengan CTA "Lihat Katalog".
- **Kategori Cepat**: Horizontal scroll chip kategori: *Semua*, *Pernikahan*, *Duka Cita*, *Grand Opening*, *Wisuda*.
- **Upcoming Booking Widget**: Kartu status sewa aktif yang menampilkan waktu hitung mundur menuju tanggal acara.
- **Bottom Navigation**: Floating nav bar dengan 4 menu: *Beranda*, *Katalog*, *Pesanan Saya*, *Profil*.

### 5.2 Katalog & Ketersediaan (`geminiflo_katalog_ketersediaan`)
- **Search Bar**: Input pencarian dengan ikon kaca pembesar dan tombol filter lanjutan.
- **Product Grid (2 Kolom)**:
  - Foto utama dengan aspek rasio 4:3.
  - Floating status badge di sudut kanan atas foto (`Available` hijau / `Limited` kuning).
  - Nama papan bunga, dimensi (contoh: 2.0m x 1.5m), dan harga sewa harian formatted IDR.
  - Tombol favorit hati (*Wishlist*) interaktif.

### 5.3 Detail Produk & Booking Flow (`geminiflo_detail_booking`)
- **Hero Image Slider**: Foto sudut penuh papan bunga, close-up rangkaian bunga, dan foto saat terpasang di lokasi.
- **Info Spesifikasi**: Jenis bunga (Segar vs Suyok Premium), estimasi pengerjaan, dimensi papan kayu/busa.
- **Formulir Khusus Acara**:
  - Tanggal Pasang & Selesai (Interactive Date Picker).
  - Teks Ucapan Utama (Misal: "HAPPY WEDDING").
  - Nama Pengirim & Nama Penerima.
  - Alamat Lengkap Venue Acara & Petunjuk Kurir.
  - Checklist Add-on: *Gratis Ongkir Wilayah Tertentu*, *Layanan Pemasangan Khusus*.

### 5.4 Pembayaran & Verifikasi Bukti (`geminiflo_pembayaran_verifikasi`)
- **Two-Status Engine Tracker**:
  - Indikator alur status pesanan: `Menunggu Pembayaran` ➔ `Verifikasi Admin` ➔ `Dikonfirmasi` ➔ `Terkirim`.
- **Rincian Rekening Florist**: Nomor rekening BCA / Mandiri dengan tombol "Salin Nomor Rekening".
- **Upload Box Bukti Transfer**: Area drag/tap dengan preview gambar hasil kamera/galeri.
- **Tombol WhatsApp Direct**: Tombol hijau WhatsApp untuk konfirmasi cepat ke admin toko.

### 5.5 Admin Command Desk (`geminiflo_admin_dashboard`)
- **Metrik Utama**: Total Order, Pending Verification, Papan Bunga Terpasang Hari Ini.
- **Queue Verifikasi Kilat**: Daftar struk transfer pending.
  - Klik kartu membuka modal split-view: preview gambar struk di sisi atas, nominal & nama di sisi bawah.
  - Tombol **Terima (Approve)**: Mengubah status otomatis jadi Lunas & Dikonfirmasi.
  - Tombol **Tolak (Reject)**: Menampilkan dialog input alasan penolakan untuk dikirim ke pembeli.
