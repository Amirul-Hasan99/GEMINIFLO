import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../providers/booking_provider.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final String productId;

  const BookingFormScreen({super.key, required this.productId});

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
  bool _withDelivery = true;
  bool _withInstallation = false;

  static const double _deliveryFee = 150000;
  static const double _installationFee = 100000;

  @override
  void initState() {
    super.initState();
    // Pre-fill user data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    return productPrice +
        (_withDelivery ? _deliveryFee : 0) +
        (_withInstallation ? _installationFee : 0);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
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

    final notifier = ref.read(createBookingProvider.notifier);
    final booking = await notifier.createBooking(
      productId: widget.productId,
      productName: productName,
      productPrice: productPrice,
      startDate: _startDate!,
      endDate: _startDate!.add(const Duration(hours: 24)),
      customerName: _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      eventAddress: _addressCtrl.text.trim(),
      eventMessage: _messageCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      withDelivery: _withDelivery,
      withInstallation: _withInstallation,
    );

    if (!mounted) return;
    if (booking != null) {
      context.push(RouteNames.bookingConfirmation, extra: {
        'booking': booking,
        'productName': productName,
      });
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
            title: const Text(
              'Form Booking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                                CurrencyFormatter.formatIDR(product.pricePerDay),
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

                  _SectionTitle('Informasi Pemesan'),
                  const SizedBox(height: AppSpacing.md),
                  _FormField(
                    label: 'Nama Pemesan',
                    controller: _nameCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FormField(
                    label: 'Nomor HP',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'No. HP wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _SectionTitle('Detail Acara'),
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
                          const Icon(Icons.calendar_today_outlined,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            _startDate != null
                                ? DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                                    .format(_startDate!)
                                : 'Pilih Tanggal Acara',
                            style: TextStyle(
                              color: _startDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FormField(
                    label: 'Alamat Acara / Pengiriman',
                    controller: _addressCtrl,
                    maxLines: 3,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FormField(
                    label: 'Tulisan Pita / Ucapan',
                    hint: 'Contoh: Selamat & Sukses atas Grand Opening...',
                    controller: _messageCtrl,
                    maxLines: 2,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Tulisan pita wajib diisi' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FormField(
                    label: 'Catatan Tambahan (Opsional)',
                    hint: 'Instruksi khusus untuk admin...',
                    controller: _notesCtrl,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  _SectionTitle('Layanan Tambahan'),
                  const SizedBox(height: AppSpacing.md),
                  _ServiceToggle(
                    label: 'Pengiriman',
                    subtitle: CurrencyFormatter.formatIDR(_deliveryFee),
                    value: _withDelivery,
                    onChanged: (v) => setState(() => _withDelivery = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ServiceToggle(
                    label: 'Instalasi',
                    subtitle: CurrencyFormatter.formatIDR(_installationFee),
                    value: _withInstallation,
                    onChanged: (v) => setState(() => _withInstallation = v),
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
                        _PriceRow('Sewa Papan',
                            CurrencyFormatter.formatIDR(product.pricePerDay)),
                        if (_withDelivery)
                          _PriceRow('Pengiriman',
                              CurrencyFormatter.formatIDR(_deliveryFee)),
                        if (_withInstallation)
                          _PriceRow('Instalasi',
                              CurrencyFormatter.formatIDR(_installationFee)),
                        const Divider(color: AppColors.borderLight, height: 16),
                        _PriceRow(
                          'Total',
                          CurrencyFormatter.formatIDR(total),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: 'Lanjut ke Konfirmasi',
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
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            filled: true,
            fillColor: AppColors.surfaceWhite,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 12),
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
              borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ServiceToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? AppColors.primary : AppColors.border,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.circle_outlined,
            color: value ? AppColors.primary : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceRow(this.label, this.value, {this.isTotal = false});

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
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
