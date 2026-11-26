import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_provider.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final String productId;
  final DateTime? initialDate;
  final Booking? initialBooking;

  const BookingFormScreen({
    super.key,
    required this.productId,
    this.initialDate,
    this.initialBooking,
  });

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _startDate;
  // true = Pengiriman & Antar-Jemput oleh Toko (include instalasi)
  // false = Pick-up / Ambil Sendiri di Florist (include instalasi / mandiri)
  bool _isStoreDelivery = true;

  @override
  void initState() {
    super.initState();
    final booking = widget.initialBooking;
    if (booking != null) {
      _startDate = booking.startDate;
      _isStoreDelivery = booking.withDelivery;
      _nameCtrl.text = booking.customerName;
      _phoneCtrl.text = booking.customerPhone;
      _addressCtrl.text = booking.withDelivery
          ? booking.eventAddress
          : booking.eventAddress.startsWith('Pick-up Florist - Acara di: ')
          ? booking.eventAddress.replaceFirst(
              'Pick-up Florist - Acara di: ',
              '',
            )
          : '';
      _messageCtrl.text = booking.eventMessage;
      _notesCtrl.text = booking.notes ?? '';
    } else if (widget.initialDate != null) {
      _startDate = widget.initialDate;
    }
    // Pre-fill user data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialBooking != null) return;
      final user = ref.read(authStateProvider).user;
      if (user != null) {
        _nameCtrl.text = user.name;
        if (user.phone != null) _phoneCtrl.text = user.phone!;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _messageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double _calculateTotal(double productPrice) {
    // Biaya pengiriman dan instalasi sudah include / gratis
    return productPrice;
  }

  Future<void> _pickDate() async {
    final earliestDate = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 1)),
    );
    final selectedDate = _startDate;
    final initialDate =
        selectedDate == null || selectedDate.isBefore(earliestDate)
        ? earliestDate
        : selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: earliestDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit(String productName, double productPrice) async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal acara terlebih dahulu'),
          backgroundColor: AppColors.statusWarning,
        ),
      );
      return;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .get(
            ApiConstants.productAvailability(widget.productId),
            queryParameters: {
              'start_date': _startDate!.toUtc().toIso8601String(),
              'end_date': _startDate!
                  .add(const Duration(hours: 24))
                  .toUtc()
                  .toIso8601String(),
              if (widget.initialBooking != null)
                'exclude_booking_id': widget.initialBooking!.id,
            },
          );
      final availability = response.data['data'];
      if (availability is Map && availability['is_available'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Papan bunga sudah dipesan pada tanggal tersebut.'),
              backgroundColor: AppColors.statusWarning,
            ),
          );
        }
        return;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ketersediaan belum dapat diperiksa: $error')),
        );
      }
      return;
    }

    Booking? booking;
    final existing = widget.initialBooking;
    try {
      if (existing != null) {
        booking = await ref
            .read(myBookingsProvider.notifier)
            .updateBooking(
              Booking(
                id: existing.id,
                bookingCode: existing.bookingCode,
                productId: widget.productId,
                productName: productName,
                productImageUrl: existing.productImageUrl,
                customerId: existing.customerId,
                customerName: _nameCtrl.text.trim(),
                customerPhone: _phoneCtrl.text.trim(),
                eventAddress: _isStoreDelivery
                    ? _addressCtrl.text.trim()
                    : (_addressCtrl.text.trim().isEmpty
                          ? 'Pick-up di Florist Geminiflo (Jl. Bunga Mawar No. 12, Pontianak)'
                          : 'Pick-up Florist - Acara di: ${_addressCtrl.text.trim()}'),
                eventMessage: _messageCtrl.text.trim(),
                notes: _notesCtrl.text.trim().isNotEmpty
                    ? _notesCtrl.text.trim()
                    : null,
                startDate: _startDate!,
                endDate: _startDate!.add(const Duration(hours: 24)),
                withDelivery: _isStoreDelivery,
                withInstallation: _isStoreDelivery,
                subtotal: productPrice,
                deliveryFee: 0,
                installationFee: 0,
                total: _calculateTotal(productPrice),
                status: existing.status,
                createdAt: existing.createdAt,
                paymentDeadline: existing.paymentDeadline,
              ),
            );
      } else {
        booking = await ref
            .read(createBookingProvider.notifier)
            .createBooking(
              productId: widget.productId,
              productName: productName,
              productPrice: productPrice,
              startDate: _startDate!,
              endDate: _startDate!.add(const Duration(hours: 24)),
              customerName: _nameCtrl.text.trim(),
              customerPhone: _phoneCtrl.text.trim(),
              eventAddress: _isStoreDelivery
                  ? _addressCtrl.text.trim()
                  : (_addressCtrl.text.trim().isEmpty
                        ? 'Pick-up di Florist Geminiflo (Jl. Bunga Mawar No. 12, Pontianak)'
                        : 'Pick-up Florist - Acara di: ${_addressCtrl.text.trim()}'),
              eventMessage: _messageCtrl.text.trim(),
              notes: _notesCtrl.text.trim().isNotEmpty
                  ? _notesCtrl.text.trim()
                  : null,
              withDelivery: _isStoreDelivery,
              withInstallation: _isStoreDelivery,
            );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesanan gagal diperbarui: $error')),
        );
      }
      return;
    }

    if (!mounted) return;
    if (booking != null) {
      unawaited(
        context.push(
          RouteNames.bookingConfirmation,
          extra: {'booking': booking, 'productName': productName},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final bookingState = ref.watch(createBookingProvider);

    return productAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primary),
        body: Center(child: Text('Error: $e')),
      ),
      data: (product) {
        final total = _calculateTotal(product.pricePerDay);
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(RouteNames.catalog),
            ),
            title: Text(
              widget.initialBooking == null ? 'Form Booking' : 'Edit Pesanan',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product summary
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_florist,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${CurrencyFormatter.formatIDR(product.pricePerDay)} / 24 Jam',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  const _SectionTitle('Informasi Pemesan'),
                  const SizedBox(height: AppSpacing.md),
                  _FormField(
                    label: 'Nama Pemesan',
                    hint: 'Masukkan nama lengkap Anda',
                    controller: _nameCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FormField(
                    label: 'Nomor WhatsApp / HP',
                    hint: 'Contoh: 081234567890',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'No. HP wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  const _SectionTitle('Detail Acara'),
                  const SizedBox(height: AppSpacing.md),
                  // Date picker
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _startDate != null
                                  ? DateFormatter.formatFull(_startDate!)
                                  : 'Pilih Tanggal Acara',
                              style: TextStyle(
                                color: _startDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: _startDate != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Metode Pengiriman / Penyerahan (Included Pengiriman & Instalasi)
                  const _SectionTitle('Metode Penyerahan Papan Bunga'),
                  const SizedBox(height: 4),
                  const Text(
                    'Biaya sewa sudah mencakup pengiriman & instalasi (Gratis). Silakan pilih metode yang Anda inginkan:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Option 1: Toko antar-jemput & instalasi
                  _DeliveryOptionCard(
                    title: 'Antar - Pasang - Jemput Toko',
                    badge: 'Include Gratis',
                    subtitle: 'Papan bunga diantar ke venue, dipasang oleh tim florist, dan dijemput kembali setelah acara selesai.',
                    icon: Icons.local_shipping_outlined,
                    isSelected: _isStoreDelivery,
                    onTap: () => setState(() => _isStoreDelivery = true),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Option 2: Pick-up sendiri
                  _DeliveryOptionCard(
                    title: 'Pick-up / Ambil Sendiri di Toko',
                    badge: 'Ambil Mandiri',
                    subtitle: 'Ambil dan kembalikan sendiri papan bunga di workshop Florist Geminiflo. Tanpa biaya tambahan.',
                    icon: Icons.storefront_outlined,
                    isSelected: !_isStoreDelivery,
                    onTap: () => setState(() => _isStoreDelivery = false),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (!_isStoreDelivery)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lokasi Workshop Florist Geminiflo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Jl. Bunga Mawar No. 12, Pontianak (Buka 08:00 - 21:00 WIB).\nSilakan ambil H-1 atau hari H sesuai jadwal acara.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  _FormField(
                    label: _isStoreDelivery
                        ? 'Alamat Acara / Pengiriman'
                        : 'Lokasi Acara (Opsional)',
                    hint: _isStoreDelivery
                        ? 'Contoh: Gedung PCC Jl. Sutan Syahrir No. 1, Pontianak'
                        : 'Nama gedung / lokasi acara (opsional)',
                    controller: _addressCtrl,
                    maxLines: 3,
                    validator: (v) {
                      if (_isStoreDelivery && (v == null || v.isEmpty)) {
                        return 'Alamat pengiriman wajib diisi untuk layanan antar-jemput';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FormField(
                    label: 'Tulisan Pita / Ucapan',
                    hint: 'Contoh: Selamat & Sukses atas Grand Opening...',
                    controller: _messageCtrl,
                    maxLines: 2,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Tulisan pita wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FormField(
                    label: 'Catatan Tambahan (Opsional)',
                    hint: 'Instruksi khusus, posisi penempatan, atau kontak PIC di venue...',
                    controller: _notesCtrl,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Price summary
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        _PriceRow(
                          'Sewa Papan (24 Jam)',
                          CurrencyFormatter.formatIDR(product.pricePerDay),
                        ),
                        _PriceRow(
                          'Pengiriman & Antar-Jemput',
                          _isStoreDelivery
                              ? 'Gratis (Termasuk)'
                              : 'Ambil Sendiri (Rp 0)',
                          valueColor: AppColors.statusSuccess,
                        ),
                        _PriceRow(
                          'Pemasangan di Venue',
                          _isStoreDelivery
                              ? 'Gratis (Termasuk)'
                              : 'Mandiri (Rp 0)',
                          valueColor: AppColors.statusSuccess,
                        ),
                        const Divider(color: AppColors.borderLight, height: 16),
                        _PriceRow(
                          'Total Pembayaran',
                          CurrencyFormatter.formatIDR(total),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: widget.initialBooking == null
                        ? 'Lanjut ke Konfirmasi'
                        : 'Simpan Perubahan',
                    onPressed: () => _submit(product.name, product.pricePerDay),
                    isLoading: bookingState.isLoading,
                    width: double.infinity,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DeliveryOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryOptionCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _FormField({
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.secondary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const _PriceRow(
    this.label,
    this.value, {
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal
                  ? AppColors.primary
                  : (valueColor ?? AppColors.textPrimary),
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
