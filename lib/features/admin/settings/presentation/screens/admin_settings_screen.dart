import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _businessNameCtrl =
      TextEditingController(text: 'Geminiflo_');
  final _waCtrl = TextEditingController(text: '+62 812-3456-7890');
  final _addressCtrl =
      TextEditingController(text: 'Jl. Florist No. 1, Kota Floral');
  bool _bcaEnabled = true;
  bool _mandiriEnabled = true;
  bool _qrisEnabled = false;
  bool _autoLockSlot = true;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _waCtrl.dispose();
    _addressCtrl.dispose();
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
        title: const Text('Pengaturan Bisnis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business identity
            _SettingSection(
              title: 'Identitas Bisnis',
              children: [
                _SettingField('Nama Bisnis', _businessNameCtrl),
                const SizedBox(height: AppSpacing.md),
                _SettingField('Nomor WhatsApp Admin', _waCtrl,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: AppSpacing.md),
                _SettingField('Alamat Bisnis', _addressCtrl, maxLines: 2),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Payment methods
            _SettingSection(
              title: 'Rekening Pembayaran',
              children: [
                _ToggleRow(
                  label: 'BCA',
                  subtitle: '1234567890 a.n. Geminiflo_',
                  value: _bcaEnabled,
                  onChanged: (v) => setState(() => _bcaEnabled = v),
                ),
                const Divider(color: AppColors.borderLight),
                _ToggleRow(
                  label: 'Mandiri',
                  subtitle: '0987654321 a.n. Geminiflo_',
                  value: _mandiriEnabled,
                  onChanged: (v) => setState(() => _mandiriEnabled = v),
                ),
                const Divider(color: AppColors.borderLight),
                _ToggleRow(
                  label: 'QRIS',
                  subtitle: 'QR code dinamis',
                  value: _qrisEnabled,
                  onChanged: (v) => setState(() => _qrisEnabled = v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Booking rules
            _SettingSection(
              title: 'Aturan Booking',
              children: [
                _ToggleRow(
                  label: 'Auto-lock Slot',
                  subtitle: 'Otomatis blokir slot saat booking dibuat',
                  value: _autoLockSlot,
                  onChanged: (v) => setState(() => _autoLockSlot = v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            AppButton(
              text: 'Simpan Pengaturan',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengaturan berhasil disimpan'),
                    backgroundColor: AppColors.statusSuccess,
                  ),
                );
              },
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(color: AppColors.borderLight, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SettingField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _SettingField(
    this.label,
    this.controller, {
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.secondary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}
