import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';

class AdminProductFormScreen extends StatefulWidget {
  final String? productId;

  const AdminProductFormScreen({super.key, required this.productId});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _dimensionsCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  bool get isEdit => widget.productId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _dimensionsCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Produk' : 'Tambah Produk',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image upload area
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.textMuted, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Upload Foto Produk',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildField('Nama Produk', _nameCtrl,
                  validator: (v) =>
                      v?.isEmpty == true ? 'Nama wajib diisi' : null),
              const SizedBox(height: AppSpacing.md),
              _buildField('SKU', _skuCtrl),
              const SizedBox(height: AppSpacing.md),
              _buildField('Deskripsi', _descCtrl, maxLines: 4),
              const SizedBox(height: AppSpacing.md),
              _buildField('Harga / 24 jam (Rp)', _priceCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v?.isEmpty == true ? 'Harga wajib diisi' : null),
              const SizedBox(height: AppSpacing.md),
              _buildField('Dimensi (cth: 120cm × 180cm)', _dimensionsCtrl),
              const SizedBox(height: AppSpacing.md),
              _buildField('Stok Total', _stockCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Produk berhasil disimpan')),
                    );
                    Navigator.pop(context);
                  }
                },
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
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
          controller: ctrl,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
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
              borderSide:
                  const BorderSide(color: AppColors.secondary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
