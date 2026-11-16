import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/siantri_models.dart';
import '../providers/siantri_provider.dart';

class SiAntriSolarScreen extends ConsumerStatefulWidget {
  const SiAntriSolarScreen({super.key});

  @override
  ConsumerState<SiAntriSolarScreen> createState() => _SiAntriSolarScreenState();
}

class _SiAntriSolarScreenState extends ConsumerState<SiAntriSolarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _driverNameController = TextEditingController();
  final _plateController = TextEditingController();
  final _litersController = TextEditingController();

  VehicleTypeConfig _selectedVehicle = kVehicleTypes[2]; // Default: Truk Roda 6 (80 L)

  @override
  void initState() {
    super.initState();
    _litersController.text = _selectedVehicle.maxQuotaLiters.toInt().toString();
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _plateController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  void _onVehicleChanged(VehicleTypeConfig? newVehicle) {
    if (newVehicle == null) return;
    setState(() {
      _selectedVehicle = newVehicle;
      final currentInput = double.tryParse(_litersController.text) ?? 0;
      if (currentInput > newVehicle.maxQuotaLiters || currentInput == 0) {
        _litersController.text = newVehicle.maxQuotaLiters.toInt().toString();
      }
    });
  }

  void _submitRegistration() {
    if (!_formKey.currentState!.validate()) return;

    final driverName = _driverNameController.text.trim();
    final plate = _plateController.text.trim().toUpperCase();
    final liters = double.parse(_litersController.text.trim());

    final ticket = ref.read(siAntriProvider.notifier).registerQueue(
          driverName: driverName,
          plateNumber: plate,
          vehicleType: _selectedVehicle,
          requestedLiters: liters,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nomor Antrean ${ticket.queueNumber} berhasil diterbitkan!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Bersihkan form
    _driverNameController.clear();
    _plateController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(siAntriProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_gas_station_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SiAntri Solar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'SPBU 54.693.01 Pamekasan - Madura',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // 1. HEADER & STATUS BAR
            // ==========================================
            _buildHeaderStatusBar(context, state),

            const SizedBox(height: 16),

            // SIMULASI GEOFENCE SWITCHER (DEMO CONTROL)
            _buildGeofenceSimBar(context, state),

            const SizedBox(height: 16),

            // ==========================================
            // 3. KARTU TIKET ANTREAN DIGITAL (Jika sudah mendaftar)
            // ==========================================
            if (state.currentTicket != null) ...[
              _buildDigitalTicketCard(context, state.currentTicket!),
              const SizedBox(height: 16),
            ],

            // ==========================================
            // 2. MODUL AMBIL NOMOR ANTREAN (FORM INPUT)
            // ==========================================
            if (state.currentTicket == null) ...[
              _buildQueueRegistrationForm(context, state),
              const SizedBox(height: 16),
            ],

            // ==========================================
            // 4. MODUL DAFTAR ANTREAN LIVE (FIFO)
            // ==========================================
            _buildLiveQueueModule(context, state),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // WIDGET 1: HEADER & STATUS BAR
  // -------------------------------------------------------------
  Widget _buildHeaderStatusBar(BuildContext context, SiAntriState state) {
    return Card(
      elevation: 1,
      shadowColor: AppColors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.ev_station_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ketersediaan Solar',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Solar Subsidi JBT',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
                // Badge Ketersediaan
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.isAvailable ? AppColors.successContainer : AppColors.dangerContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: state.isAvailable ? AppColors.success.withOpacity(0.4) : AppColors.danger.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isAvailable ? AppColors.success : AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isAvailable ? 'Tersedia' : 'Habis',
                        style: TextStyle(
                          color: state.isAvailable ? AppColors.success : AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            // Dua Kolom Statistik: Sisa Stok & Antrean Aktif
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sisa Stok Tangki SPBU', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.water_drop_rounded, size: 18, color: AppColors.accentSolar),
                          const SizedBox(width: 4),
                          Text(
                            AppFormatters.formatLiters(state.tankStockLiters),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 38, color: AppColors.border),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jumlah Antrean Aktif', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.directions_car_rounded, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '${state.activeQueueCount} Kendaraan',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Bar Simulasi Geofence Demo
  Widget _buildGeofenceSimBar(BuildContext context, SiAntriState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: state.isInsideGeofence ? AppColors.successContainer.withOpacity(0.5) : AppColors.dangerContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: state.isInsideGeofence ? AppColors.success.withOpacity(0.4) : AppColors.danger.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.isInsideGeofence ? Icons.near_me_rounded : Icons.location_off_rounded,
            color: state.isInsideGeofence ? AppColors.success : AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isInsideGeofence
                      ? 'Geofence Valid: Anda berada di area SPBU (${state.currentDistanceMeters.toStringAsFixed(0)} m)'
                      : 'Di Luar Radius SPBU (${state.currentDistanceMeters.toStringAsFixed(0)} m > 100 m)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: state.isInsideGeofence ? AppColors.success : AppColors.danger,
                  ),
                ),
                Text(
                  state.isInsideGeofence ? 'Pendaftaran antrean dibuka' : 'Pendaftaran antrean terkunci otomatis',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Tombol Simulasi Cepat
          TextButton(
            onPressed: () {
              final newStatus = !state.isInsideGeofence;
              ref.read(siAntriProvider.notifier).setGeofenceStatus(newStatus, newStatus ? 25.0 : 350.0);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(50, 30),
            ),
            child: Text(
              state.isInsideGeofence ? 'Simulasi Luar' : 'Simulasi Masuk',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: state.isInsideGeofence ? AppColors.danger : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // WIDGET 2: FORM PENGAMBILAN ANTREAN
  // -------------------------------------------------------------
  Widget _buildQueueRegistrationForm(BuildContext context, SiAntriState state) {
    return Card(
      elevation: 1,
      shadowColor: AppColors.primary.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ambil Nomor Antrean Kendaraan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Lengkapi identitas kendaraan untuk verifikasi kuota solar subsidi',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              // 1. Nama Lengkap Sopir
              TextFormField(
                controller: _driverNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap Sopir',
                  hintText: 'Contoh: H. Abdul Wahid',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Nama sopir wajib diisi';
                  if (val.trim().length < 3) return 'Nama minimal 3 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. Nomor Polisi / Plat Nomor (Seri Madura 'M')
              TextFormField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  labelText: 'Nomor Polisi (Seri Madura M)',
                  hintText: 'Contoh: M 4582 BG',
                  helperText: 'Wajib berpelat wilayah Madura (Awalan M)',
                  helperStyle: const TextStyle(fontSize: 11, color: AppColors.secondary),
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Plat nomor wajib diisi';
                  final trimmed = val.trim().toUpperCase();
                  if (!trimmed.startsWith('M')) {
                    return 'Plat nomor harus berawalan huruf M (Wilayah Madura)';
                  }
                  final plateRegex = RegExp(r'^M\s?[0-9]{1,4}\s?[A-Z]{1,3}$');
                  if (!plateRegex.hasMatch(trimmed)) {
                    return 'Format plat tidak valid (contoh: M 1234 AB)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 3. Dropdown Jenis Kendaraan & Kuota Maksimal
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Jenis Kendaraan & Kuota Maksimal',
                  prefixIcon: const Icon(Icons.directions_bus_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<VehicleTypeConfig>(
                    value: _selectedVehicle,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: kVehicleTypes.map((v) {
                      return DropdownMenuItem<VehicleTypeConfig>(
                        value: v,
                        child: Text(
                          '${v.name} (Maks ${v.maxQuotaLiters.toInt()} L)',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: _onVehicleChanged,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Input Jumlah Permintaan (Liter)
              TextFormField(
                controller: _litersController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                decoration: InputDecoration(
                  labelText: 'Jumlah Permintaan Solar (Liter)',
                  hintText: 'Maks ${_selectedVehicle.maxQuotaLiters.toInt()} Liter',
                  suffixText: 'Liter',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  prefixIcon: const Icon(Icons.local_gas_station_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Jumlah liter wajib diisi';
                  final amount = double.tryParse(val.trim());
                  if (amount == null || amount <= 0) return 'Masukkan jumlah liter yang valid (> 0)';
                  if (amount > _selectedVehicle.maxQuotaLiters) {
                    return 'Melebihi kuota maksimal ${_selectedVehicle.name} (${_selectedVehicle.maxQuotaLiters.toInt()} L)';
                  }
                  if (amount > state.tankStockLiters) {
                    return 'Melebihi sisa stok solar SPBU (${state.tankStockLiters.toInt()} L)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 5. Tombol Ambil Antrean (Terkunci jika di luar radius geofence)
              FilledButton(
                onPressed: state.isInsideGeofence ? _submitRegistration : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: state.isInsideGeofence ? 2 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      state.isInsideGeofence ? Icons.qr_code_rounded : Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.isInsideGeofence ? 'Daftar & Dapatkan Tiket QR' : 'Tombol Terkunci (Di Luar SPBU)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              if (!state.isInsideGeofence) ...[
                const SizedBox(height: 10),
                const Text(
                  'Tombol pendaftaran otomatis terkunci karena GPS mendeteksi kendaraan Anda belum berada di dalam radius 100m SPBU.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // WIDGET 3: KARTU TIKET ANTREAN DIGITAL (QR CODE)
  // -------------------------------------------------------------
  Widget _buildDigitalTicketCard(BuildContext context, SiAntriTicket ticket) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                  SizedBox(width: 6),
                  Text(
                    'TIKET ANTREAN AKTIF',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'NOMOR ANTREAN ANDA',
              style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.queueNumber,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),

            // QR CODE (qr_flutter)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: ticket.qrData,
                    version: QrVersions.auto,
                    size: 190.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primaryDark,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan di Dispenser SPBU',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Rincian Tiket: Plat Nomor, Kuota, Estimasi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildTicketRow('Plat Nomor', ticket.plateNumber, isBold: true),
                  const SizedBox(height: 8),
                  _buildTicketRow('Sopir Terdaftar', ticket.driverName),
                  const SizedBox(height: 8),
                  _buildTicketRow('Jenis Kendaraan', ticket.vehicleType.name),
                  const SizedBox(height: 8),
                  _buildTicketRow('Permintaan Solar', '${ticket.requestedLiters.toInt()} Liter', highlight: true),
                  const SizedBox(height: 8),
                  _buildTicketRow('Estimasi Pelayanan', '${AppFormatters.formatTime(ticket.estimatedTime)} WIB'),
                ],
              ),
            ),

            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(siAntriProvider.notifier).cancelTicket();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nomor antrean telah dibatalkan.')),
                );
              },
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Batalkan / Ambil Ulang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketRow(String label, String value, {bool isBold = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: highlight || isBold ? FontWeight.bold : FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // WIDGET 4: MODUL DAFTAR ANTREAN LIVE (FIFO)
  // -------------------------------------------------------------
  Widget _buildLiveQueueModule(BuildContext context, SiAntriState state) {
    return Card(
      elevation: 1,
      shadowColor: AppColors.primary.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.queue_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Antrean Live (FIFO)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Urutan pelayanan dispenser solar SPBU',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${state.liveQueues.length} Antre',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.info),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List Kendaraan FIFO
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.liveQueues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = state.liveQueues[index];
                return _buildLiveQueueItemCard(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveQueueItemCard(LiveQueueItem item) {
    final bool isServing = item.isServing;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isServing ? AppColors.successContainer.withOpacity(0.35) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isServing ? AppColors.success.withOpacity(0.6) : AppColors.border,
          width: isServing ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Nomor Antrean Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isServing ? AppColors.success : AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.queueNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Detail Plat & Kendaraan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.plateNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${item.driverName}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.vehicleName} (${item.liters.toInt()} L)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isServing ? AppColors.successContainer : AppColors.warningContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isServing ? AppColors.success : AppColors.warning,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isServing ? Icons.local_gas_station_rounded : Icons.access_time_rounded,
                  size: 13,
                  color: isServing ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  isServing ? 'Dilayani' : item.estimatedWaitTime,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isServing ? AppColors.success : const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
