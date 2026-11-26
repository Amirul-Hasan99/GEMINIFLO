import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class AddressItem {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String addressDetail;
  bool isPrimary;

  AddressItem({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.addressDetail,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'recipientName': recipientName,
    'phone': phone,
    'addressDetail': addressDetail,
    'isPrimary': isPrimary,
  };

  factory AddressItem.fromJson(Map<String, dynamic> json) => AddressItem(
    id: '${json['id']}',
    label: '${json['label'] ?? 'Alamat'}',
    recipientName: '${json['recipientName'] ?? ''}',
    phone: '${json['phone'] ?? ''}',
    addressDetail: '${json['addressDetail'] ?? ''}',
    isPrimary: json['isPrimary'] as bool? ?? false,
  );
}

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  bool _isLoading = true;
  final List<AddressItem> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .get(ApiConstants.addresses);
      final rows = response.data['data']['addresses'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _addresses
          ..clear()
          ..addAll(
            rows.map(
              (x) => AddressItem.fromJson(Map<String, dynamic>.from(x as Map)),
            ),
          );
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat alamat: $error')));
    }
  }

  Future<void> _setPrimary(String id) async {
    await ref
        .read(apiClientProvider)
        .put('${ApiConstants.addressDetail(id)}/primary');
    await _loadAddresses();
    setState(() {
      for (var a in _addresses) {
        a.isPrimary = (a.id == id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alamat utama berhasil diperbarui'),
        backgroundColor: AppColors.statusSuccess,
      ),
    );
  }

  void _showAddressDialog({AddressItem? existing}) {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final nameCtrl = TextEditingController(text: existing?.recipientName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addressCtrl = TextEditingController(
      text: existing?.addressDetail ?? '',
    );
    final isEditing = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Alamat' : 'Tambah Alamat Baru',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: labelCtrl,
                label: 'Label Alamat (mis: Rumah, Kantor)',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: nameCtrl, label: 'Nama Penerima'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: phoneCtrl,
                label: 'Nomor Telepon',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: addressCtrl,
                label: 'Alamat Lengkap',
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: isEditing ? 'Simpan Perubahan' : 'Simpan Alamat',
                width: double.infinity,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      addressCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Nama penerima dan alamat lengkap wajib diisi.',
                        ),
                      ),
                    );
                    return;
                  }
                  final data = {
                    'label': labelCtrl.text.trim().isEmpty
                        ? 'Alamat Lain'
                        : labelCtrl.text.trim(),
                    'recipient_name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'address_line': addressCtrl.text.trim(),
                    'is_primary': existing?.isPrimary ?? _addresses.isEmpty,
                  };
                  final api = ref.read(apiClientProvider);
                  if (existing == null) {
                    await api.post(ApiConstants.addresses, data: data);
                  } else {
                    await api.put(
                      ApiConstants.addressDetail(existing.id),
                      data: data,
                    );
                  }
                  await _loadAddresses();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Alamat berhasil diperbarui.'
                            : 'Alamat baru berhasil ditambahkan!',
                      ),
                      backgroundColor: AppColors.statusSuccess,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddAddressDialog() => _showAddressDialog();

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
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.profile),
        ),
        title: const Text(
          'Alamat Pengiriman',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Alamat',
            onPressed: _isLoading ? null : _showAddAddressDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final addr = _addresses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: addr.isPrimary
                          ? AppColors.primary
                          : AppColors.borderLight,
                      width: addr.isPrimary ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              addr.label,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (addr.isPrimary) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Utama',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'primary') {
                                _setPrimary(addr.id);
                              } else if (val == 'edit') {
                                _showAddressDialog(existing: addr);
                              } else if (val == 'delete') {
                                ref
                                    .read(apiClientProvider)
                                    .delete(ApiConstants.addressDetail(addr.id))
                                    .then((_) => _loadAddresses());
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Alamat'),
                              ),
                              if (!addr.isPrimary)
                                const PopupMenuItem(
                                  value: 'primary',
                                  child: Text('Jadikan Utama'),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Hapus Alamat',
                                  style: TextStyle(
                                    color: AppColors.statusError,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        addr.recipientName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        addr.phone,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        addr.addressDetail,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton(
            text: '+ Tambah Alamat Baru',
            type: ButtonType.outlined,
            width: double.infinity,
            onPressed: _isLoading ? null : _showAddAddressDialog,
          ),
        ),
      ),
    );
  }
}
