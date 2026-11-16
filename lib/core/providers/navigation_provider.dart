import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier untuk mengontrol indeks tab aktif di Bottom Navigation Bar
class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0; // Default index 0: 'SiAntri' (Beranda)

  void setIndex(int index) {
    state = index;
  }
}

/// Provider global untuk navigasi antar tab Bottom Navigation Bar
final bottomNavIndexProvider =
    NotifierProvider<BottomNavIndexNotifier, int>(
  BottomNavIndexNotifier.new,
);
