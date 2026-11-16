import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _radiusController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _nameController = TextEditingController(text: settings.spbnName);
    _latController = TextEditingController(text: settings.latitude.toString());
    _lngController = TextEditingController(text: settings.longitude.toString());
    _radiusController = TextEditingController(text: settings.radiusMeters.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _syncControllersWithState() {
    final settings = ref.read(settingsProvider);
    _nameController.text = settings.spbnName;
    _latController.text = settings.latitude.toString();
    _lngController.text = settings.longitude.toString();
    _radiusController.text = settings.radiusMeters.toStringAsFixed(1);
  }

  Future<void> _saveCoordinates() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final radius = double.tryParse(_radiusController.text.trim());
    final name = _nameController.text.trim();

    if (lat == null || lng == null || radius == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format angka koordinat atau radius tidak valid!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    await ref.read(settingsProvider.notifier).updateSettings(
          latitude: lat,
          longitude: lng,
          radiusMeters: radius,
          spbnName: name.isNotEmpty ? name : null,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan koordinat SPBN berhasil disimpan ke memori!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _resetToDefault() async {
    await ref.read(settingsProvider.notifier).resetToDefault();
    _syncControllersWithState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan telah di-reset ke default SPBN Madura (Geofencing Nonaktif)'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _applyPreset({
    required String name,
    required double lat,
    required double lng,
    required double radius,
  }) {
    setState(() {
      _nameController.text = name;
      _latController.text = lat.toString();
      _lngController.text = lng.toString();
      _radiusController.text = radius.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pengaturan SPBN & Geofence',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Default',
            icon: const Icon(Icons.restore_rounded),
            onPressed: _resetToDefault,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // 1. KONTROL UTAMA SAKLAR GEOFENCING
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: settings.isGeofenceEnabled
                    ? AppColors.primaryContainer.withValues(alpha: 0.3)
                    : const Color(0xFFEFF6FF), // Soft Blue
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: settings.isGeofenceEnabled
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.info.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: settings.isGeofenceEnabled ? AppColors.primary : AppColors.info,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          settings.isGeofenceEnabled ? Icons.radar_rounded : Icons.lock_open_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pembatasan Radius Geofencing',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              settings.isGeofenceEnabled
                                  ? 'Kunci pendaftaran antrean jika nelayan di luar radius SPBN'
                                  : 'Mode Bebas Uji Coba: Antrean bisa diambil dari rumah/mana saja',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: settings.isGeofenceEnabled,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          ref.read(settingsProvider.notifier).setGeofenceEnabled(value);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // BADGE STATUS GEOFENCE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: settings.isGeofenceEnabled
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          settings.isGeofenceEnabled
                              ? Icons.security_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 16,
                          color: settings.isGeofenceEnabled
                              ? AppColors.warning
                              : const Color(0xFF1D4ED8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            settings.isGeofenceEnabled
                                ? 'Geofencing AKTIF: Validasi jarak GPS diterapkan ketat di lapangan'
                                : 'Mode Bebas Uji (Geofencing Dinonaktifkan): Tombol pendaftaran selalu aktif',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: settings.isGeofenceEnabled
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 2. FORM INPUT KOORDINAT & RADIUS DINAMIS
            // ==========================================
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_location_alt_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Koordinat & Radius SPBN Lapangan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ubah koordinat GPS dan radius jangkauan SPBN secara fleksibel sesuai titik koordinat dermaga yang Anda miliki.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Nama SPBN
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Stasiun SPBN',
                          hintText: 'Contoh: SPBN 54.693.01 Branta Pamekasan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.storefront_rounded),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama SPBN tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Latitude & Longitude
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                hintText: '-7.239400',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.my_location_rounded),
                              ),
                              validator: (val) {
                                if (val == null || double.tryParse(val.trim()) == null) {
                                  return 'Harus angka';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                hintText: '113.535600',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.explore_rounded),
                              ),
                              validator: (val) {
                                if (val == null || double.tryParse(val.trim()) == null) {
                                  return 'Harus angka';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Radius (meter)
                      TextFormField(
                        controller: _radiusController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Radius Geofence Valid (Meter)',
                          hintText: '100.0',
                          suffixText: 'Meter',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.adjust_rounded),
                        ),
                        validator: (val) {
                          final num = double.tryParse(val?.trim() ?? '');
                          if (num == null || num <= 0) {
                            return 'Radius harus lebih dari 0 meter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Preset Lokasi SPBN Madura
                      const Text(
                        'Pilihan Cepat Titik SPBN Madura:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.place_rounded, size: 16),
                            label: const Text('Branta Pamekasan'),
                            onPressed: () => _applyPreset(
                              name: 'SPBN 54.693.01 Branta Pamekasan',
                              lat: -7.239400,
                              lng: 113.535600,
                              radius: 100.0,
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.place_rounded, size: 16),
                            label: const Text('Camplong Sampang'),
                            onPressed: () => _applyPreset(
                              name: 'SPBN 54.692.03 Camplong Sampang',
                              lat: -7.195200,
                              lng: 113.334100,
                              radius: 120.0,
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.place_rounded, size: 16),
                            label: const Text('Kalianget Sumenep'),
                            onPressed: () => _applyPreset(
                              name: 'SPBN 54.694.02 Kalianget Sumenep',
                              lat: -7.054200,
                              lng: 113.896700,
                              radius: 150.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tombol Simpan
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _saveCoordinates,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text(
                            'Simpan Pengaturan Koordinat',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // 3. PANDUAN PENGUJIAN UNTUK SIDANG / DEMO
            // ==========================================
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Petunjuk Pengujian Dosen & Uji Coba',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Biarkan saklar dalam posisi OFF (Mati) saat mendemokan aplikasi di dalam ruangan / rumah agar tombol pendaftaran langsung aktif.\n'
                    '2. Saat ingin mendemokan validasi geofence, geser saklar ke ON. Jika Anda di luar radius SPBN, tombol akan terkunci secara otomatis.\n'
                    '3. Anda juga dapat mengubah nilai Latitude & Longitude SPBN di atas mengikuti koordinat lokasi Anda saat ini untuk menguji status "Di Dalam Radius".',
                    style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary),
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
