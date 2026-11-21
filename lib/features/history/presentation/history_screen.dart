import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/mock_spbn_repository.dart';
import '../../../core/utils/formatters.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Pengisian Solar'),
        actions: [
          IconButton(
            tooltip: 'Segarkan Riwayat',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(transactionHistoryProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionHistoryProvider);
        },
        child: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Gagal memuat riwayat: $err'),
          ),
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Center(
                child: Text('Belum ada riwayat transaksi pengisian.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return _buildTransactionCard(context, tx);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionHistory tx) {
    final bool isAnomaly = tx.isAnomaly;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isAnomaly ? AppColors.danger.withValues(alpha: 0.5) : AppColors.border,
          width: isAnomaly ? 1.4 : 1.0,
        ),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Baris: Ref & Badge Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isAnomaly ? AppColors.dangerContainer : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isAnomaly ? Icons.warning_amber_rounded : Icons.local_gas_station_rounded,
                        size: 18,
                        color: isAnomaly ? AppColors.danger : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.transactionRef,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          AppFormatters.formatDateTime(tx.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAnomaly ? AppColors.dangerContainer : AppColors.successContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAnomaly ? 'Anomali' : 'Normal',
                    style: TextStyle(
                      color: isAnomaly ? AppColors.danger : AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, color: AppColors.divider),
            ),

            // Volume Pengisian
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Volume Solar Bersubsidi',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                Text(
                  '+ ${AppFormatters.formatLiters(tx.volumeLiters)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isAnomaly ? AppColors.danger : AppColors.primary,
                  ),
                ),
              ],
            ),

            // Detail Explainability jika Transaksi Terdeteksi Anomali (Blueprint Bab 5.3 & 6.1)
            if (isAnomaly) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_alt_rounded, size: 16, color: AppColors.danger),
                        const SizedBox(width: 6),
                        Text(
                          'Catatan Audit AI (Skor Anomali: ${((tx.anomalyScore ?? 0.86) * 100).toStringAsFixed(0)}%):',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...tx.anomalyReasons.map(
                      (reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                reason,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
