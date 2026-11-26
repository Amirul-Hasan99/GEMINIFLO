import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/product_image.dart';
import '../../../../catalog/domain/entities/product.dart';
import '../../../../catalog/presentation/providers/catalog_provider.dart';

class AdminProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AdminProductFormScreen({super.key, required this.productId});

  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState
    extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _dimensionsCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  String _selectedCategoryId = '7';
  String _selectedCategoryName = 'Papan Bunga';
  String _availabilityStatus = 'available';
  bool _isSaving = false;
  bool _isInitialLoaded = false;
  String? _existingImageUrl;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool get isEdit => widget.productId != null;

  static const _categories = [
    {'id': '1', 'name': 'Pernikahan'},
    {'id': '2', 'name': 'Grand Opening'},
    {'id': '3', 'name': 'Ulang Tahun'},
    {'id': '4', 'name': 'Duka Cita'},
    {'id': '5', 'name': 'Wisuda'},
    {'id': '6', 'name': 'Promosi'},
    {'id': '7', 'name': 'Papan Bunga'},
  ];

  static const _statuses = [
    {'value': 'available', 'label': 'Tersedia'},
    {'value': 'limited', 'label': 'Stok Terbatas'},
    {'value': 'unavailable', 'label': 'Habis / Disewa'},
  ];

  @override
  void initState() {
    super.initState();
    _dimensionsCtrl.text = '120cm × 180cm';
    _stockCtrl.text = '5';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialLoaded && isEdit) {
      _loadExistingProduct();
      _isInitialLoaded = true;
    }
  }

  void _loadExistingProduct() {
    final catalogState = ref.read(catalogProvider);
    final product = catalogState.products
        .where((p) => p.id == widget.productId)
        .cast<Product?>()
        .firstOrNull;

    if (product != null) {
      _nameCtrl.text = product.name;
      _skuCtrl.text = product.sku;
      _descCtrl.text = product.description ?? '';
      _priceCtrl.text = product.pricePerDay.toInt().toString();
      _dimensionsCtrl.text = product.dimensions;
      _stockCtrl.text = product.stockTotal.toString();
      _selectedCategoryId = product.categoryId;
      _selectedCategoryName = product.categoryName;
      _availabilityStatus = product.availabilityStatus;
      if (product.imageUrls.isNotEmpty) {
        _existingImageUrl = product.imageUrls.first;
        _imageUrlCtrl.text = product.imageUrls.first;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _dimensionsCtrl.dispose();
    _stockCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _selectedImage = File(file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Sumber Foto Produk',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Galeri HP',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Kamera',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final price = double.parse(_priceCtrl.text.trim());
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 5;
    final dimensions = _dimensionsCtrl.text.trim().isEmpty
        ? '120cm × 180cm'
        : _dimensionsCtrl.text.trim();

    String sku = _skuCtrl.text.trim();
    if (sku.isEmpty) {
      final prefix = _selectedCategoryName.substring(0, 2).toUpperCase();
      sku = 'GF-$prefix-${DateTime.now().millisecondsSinceEpoch % 1000}';
    }

    final imageUrls = <String>[];
    if (_selectedImage != null) {
      var imagePath = _selectedImage!.path;
      if (!kIsWeb) {
        final extension = _selectedImage!.path.split('.').last.toLowerCase();
        final bytes = await _selectedImage!.readAsBytes();
        imagePath = 'data:image/$extension;base64,${base64Encode(bytes)}';
      }
      imageUrls.add(kIsWeb ? _imageUrlCtrl.text.trim() : imagePath);
    } else if (_imageUrlCtrl.text.trim().isNotEmpty) {
      imageUrls.add(_imageUrlCtrl.text.trim());
    } else if (_existingImageUrl != null) {
      imageUrls.add(_existingImageUrl!);
    }

    try {
      if (isEdit) {
        final updatedProduct = Product(
          id: widget.productId!,
          name: name,
          sku: sku,
          categoryId: _selectedCategoryId,
          categoryName: _selectedCategoryName,
          description: description,
          imageUrls: imageUrls,
          pricePerDay: price,
          dimensions: dimensions,
          stockTotal: stock,
          stockAvailable: stock,
          isActive: true,
          availabilityStatus: _availabilityStatus,
        );
        final saved = await ref
            .read(catalogProvider.notifier)
            .updateProduct(updatedProduct);
        if (saved == null) {
          throw StateError(
            ref.read(catalogProvider).error ??
                'Perubahan produk gagal disimpan.',
          );
        }
      } else {
        final newId = DateTime.now().microsecondsSinceEpoch.toString();
        final newProduct = Product(
          id: newId,
          name: name,
          sku: sku,
          categoryId: _selectedCategoryId,
          categoryName: _selectedCategoryName,
          description: description,
          imageUrls: imageUrls,
          pricePerDay: price,
          dimensions: dimensions,
          stockTotal: stock,
          stockAvailable: stock,
          isActive: true,
          availabilityStatus: _availabilityStatus,
        );
        final saved = await ref
            .read(catalogProvider.notifier)
            .addProduct(newProduct);
        if (saved == null) {
          throw StateError(
            ref.read(catalogProvider).error ?? 'Produk gagal disimpan.',
          );
        }
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Produk "$name" berhasil diperbarui'
                : 'Produk "$name" berhasil ditambahkan',
          ),
          backgroundColor: AppColors.statusSuccess,
        ),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteNames.adminProducts);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Produk Ini?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus produk "${_nameCtrl.text}" dari katalog toko?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSaving = true);
              final success = await ref
                  .read(catalogProvider.notifier)
                  .deleteProduct(widget.productId!);
              if (!mounted) return;
              setState(() => _isSaving = false);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Produk "${_nameCtrl.text}" berhasil dihapus',
                    ),
                    backgroundColor: AppColors.statusSuccess,
                  ),
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.adminProducts);
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              : context.go(RouteNames.adminProducts),
        ),
        title: Text(
          isEdit ? 'Edit Produk' : 'Tambah Produk Baru',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Hapus Produk',
              onPressed: _isSaving ? null : _confirmDelete,
            ),
        ],
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
                onTap: _showImagePickerSheet,
                child: Container(
                  width: double.infinity,
                  height: 190,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          (_selectedImage != null || _existingImageUrl != null)
                          ? AppColors.primary
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_selectedImage!, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    onPressed: _showImagePickerSheet,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : (_existingImageUrl != null &&
                            _existingImageUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ProductImage(source: _existingImageUrl),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    onPressed: _showImagePickerSheet,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.primary,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Pilih Foto Produk Papan Bunga',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ketuk untuk memilih dari Galeri atau Kamera',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Category dropdown
              const Text(
                'Kategori Produk *',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategoryId,
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['id'],
                        child: Text(
                          c['name']!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedCategoryName = _categories.firstWhere(
                            (c) => c['id'] == val,
                          )['name']!;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Name
              _buildField(
                'Nama Produk Papan Bunga *',
                _nameCtrl,
                hintText: 'cth: Papan Bunga Grand Opening Mewah',
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Nama produk wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Keterangan / Deskripsi Lengkap Produk
              _buildField(
                'Keterangan & Deskripsi Produk *',
                _descCtrl,
                maxLines: 4,
                hintText: 'Isi keterangan detail produk: jenis bunga, nuansa warna pita/bunga, ukuran papan, dan ketentuan ucapan...',
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Keterangan produk wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // SKU
              _buildField(
                'Kode SKU Produk',
                _skuCtrl,
                hintText: 'Cth: GF-GO-003 (Kosongkan untuk otomatis)',
              ),
              const SizedBox(height: AppSpacing.md),

              // Price
              _buildField(
                'Harga Sewa per 24 Jam (Rp) *',
                _priceCtrl,
                keyboardType: TextInputType.number,
                hintText: 'cth: 150000',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Harga wajib diisi';
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return 'Masukkan nominal angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Dimensions
              _buildField(
                'Dimensi Ukuran',
                _dimensionsCtrl,
                hintText: 'cth: 120cm × 180cm',
              ),
              const SizedBox(height: AppSpacing.md),

              // Stock & Availability
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      'Total Stok Unit',
                      _stockCtrl,
                      keyboardType: TextInputType.number,
                      hintText: 'cth: 5',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Ketersediaan',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _availabilityStatus,
                              items: _statuses.map((s) {
                                return DropdownMenuItem<String>(
                                  value: s['value'],
                                  child: Text(
                                    s['label']!,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _availabilityStatus = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Optional Image URL
              _buildField(
                'URL Gambar Cadangan (Opsional)',
                _imageUrlCtrl,
                hintText: 'https://images.unsplash.com/...',
              ),
              const SizedBox(height: AppSpacing.xl),

              // Save button
              AppButton(
                text: isEdit
                    ? 'Simpan Perubahan Produk'
                    : 'Tambah Produk ke Katalog',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _handleSave,
                width: double.infinity,
                icon: const Icon(Icons.check, color: Colors.white, size: 20),
              ),

              // Delete button if in edit mode
              if (isEdit) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  text: 'Hapus Produk Ini',
                  type: ButtonType.danger,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _confirmDelete,
                  width: double.infinity,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.statusError,
                    size: 20,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
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
    String? hintText,
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
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
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
