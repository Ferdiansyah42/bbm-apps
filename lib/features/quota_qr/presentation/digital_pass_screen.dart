import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/repositories/mock_spbn_repository.dart';
import '../../../core/utils/formatters.dart';

class DigitalPassScreen extends ConsumerWidget {
  const DigitalPassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final letterAsync = ref.watch(recommendationLetterProvider);
    final shipAsync = ref.watch(activeShipProvider);
    final userAsync = ref.watch(fishermanProfileProvider);

    final letter = letterAsync.value;
    final ship = shipAsync.value;
    final user = userAsync.value;

    final String barcode = letter?.barcodeNumber ?? 'REK-DKP-2026-MADURA-001';
    final double remaining = letter?.remainingQuota ?? 270.0;
    final double allocated = letter?.allocatedQuota ?? 450.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kartu Digital & QR Kuota'),
        actions: [
          IconButton(
            tooltip: 'Panduan Scan',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Panduan Pindai QR'),
                  content: const Text(
                    'Tunjukkan QR Code ini kepada Pengawas SPBN di loket pengisian. '
                    'Pengawas akan memindai barcode untuk memvalidasi alokasi kuota solar subsidi dan mencatat volume pengisian kapal Anda.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Mengerti'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KARTU DIGITAL PAS RESMI SPBN
            Card(
              elevation: 2,
              shadowColor: AppColors.primary.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppColors.primary, width: 1.2),
              ),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Header Kartu Digital
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
                              child: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PAS DIGITAL NELAYAN',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                                Text(
                                  'Dinas Kelautan dan Perikanan',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'AKTIF',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),

                    // QR CODE GENERATOR KONTRAST TINGGI (UNTUK CAHAYA MATAHARI DERMAGA)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: barcode,
                            version: QrVersions.auto,
                            size: 200.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.primaryDark,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0B192C),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            barcode,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pindai QR Code di scanner loket pengisian solar',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),

                    // DETAIL KAPAL & KUOTA NELAYAN
                    _buildDetailRow('Pemilik Kapal', user?.name ?? 'Achmad Zaini'),
                    const SizedBox(height: 8),
                    _buildDetailRow('NIK Terdaftar', user?.nik ?? '3528011204850002'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Nama Kapal', ship?.shipName ?? 'KM Mina Jaya'),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Spesifikasi Mesin',
                      '${ship?.enginePk.toStringAsFixed(0) ?? "15"} PK / ${ship?.gtSize.toStringAsFixed(1) ?? "3.0"} GT',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Sisa Kuota Aktif',
                      AppFormatters.formatQuota(remaining, allocated),
                      isHighlight: true,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Masa Berlaku Rekomendasi',
                      letter != null ? AppFormatters.formatDate(letter.validUntil) : '90 Hari',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
