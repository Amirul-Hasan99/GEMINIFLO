import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  List<Map<String, dynamic>> _methods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .get(ApiConstants.adminPaymentMethods);
      final rows = response.data['data']['methods'] as List? ?? const [];
      if (mounted)
        setState(
          () => _methods = rows
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList(),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat metode pembayaran: $error')),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit({Map<String, dynamic>? method}) async {
    final type = TextEditingController(
      text: '${method?['type'] ?? 'bank_transfer'}',
    );
    final name = TextEditingController(text: '${method?['name'] ?? ''}');
    final number = TextEditingController(
      text: '${method?['accountNumber'] ?? ''}',
    );
    final account = TextEditingController(
      text: '${method?['accountName'] ?? ''}',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          method == null ? 'Tambah Rekening' : 'Edit Metode Pembayaran',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: type,
                decoration: const InputDecoration(
                  labelText: 'Jenis (bank_transfer / ewallet)',
                ),
              ),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Nama Bank / E-wallet',
                ),
              ),
              TextField(
                controller: number,
                decoration: const InputDecoration(
                  labelText: 'Nomor Rekening / Telepon',
                ),
              ),
              TextField(
                controller: account,
                decoration: const InputDecoration(labelText: 'Nama Pemilik'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final data = {
      'type': type.text.trim(),
      'name': name.text.trim(),
      'account_number': number.text.trim(),
      'account_name': account.text.trim(),
      'is_active': true,
    };
    try {
      final api = ref.read(apiClientProvider);
      if (method == null) {
        await api.post(ApiConstants.adminPaymentMethods, data: data);
      } else {
        await api.put(
          '${ApiConstants.adminPaymentMethods}/${method['id']}',
          data: data,
        );
      }
      await _load();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $error')));
    }
  }

  Future<void> _delete(Map<String, dynamic> method) async {
    try {
      await ref
          .read(apiClientProvider)
          .delete('${ApiConstants.adminPaymentMethods}/${method['id']}');
      await _load();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menghapus: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => context.canPop()
            ? context.pop()
            : context.go(RouteNames.adminDashboard),
      ),
      title: const Text('Metode Pembayaran'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.rate_review_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Ulasan Pelanggan'),
                  subtitle: const Text(
                    'Lihat rating dan masukan tentang GEMINIFLO.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RouteNames.adminReviews),
                ),
              ),
              const Text(
                'Rekening atau dompet digital aktif akan ditampilkan kepada pelanggan saat melakukan pembayaran.',
              ),
              const SizedBox(height: 12),
              if (_methods.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Belum ada rekening aktif. Tambahkan rekening bisnis yang benar.',
                    ),
                  ),
                ),
              ..._methods.map(
                (method) => Card(
                  child: ListTile(
                    title: Text('${method['name']}'),
                    subtitle: Text(
                      '${method['accountNumber'] ?? ''} a.n. ${method['accountName'] ?? ''}',
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          onPressed: () => _edit(method: method),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => _delete(method),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.statusError,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Tambah Metode Pembayaran',
                onPressed: () => _edit(),
                width: double.infinity,
              ),
            ],
          ),
  );
}
