import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../features/siantri_solar/models/siantri_models.dart';
import '../../features/siantri_solar/providers/siantri_provider.dart';

/// Tombol pengalih peran cepat (Role Switcher) Mode Nelayan vs Mode Operator SPBN
class RoleSwitcherPill extends ConsumerWidget {
  final bool isExpanded;

  const RoleSwitcherPill({
    super.key,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appRoleProvider);
    final isOperator = role == UserRole.operator;

    final container = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Slate 100
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // 1. Pilihan Mode Nelayan
          Expanded(
            flex: isExpanded ? 1 : 0,
            child: InkWell(
              onTap: () {
                ref.read(appRoleProvider.notifier).setRole(UserRole.fisherman);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 12 : 10,
                  vertical: isExpanded ? 9 : 5,
                ),
                decoration: BoxDecoration(
                  gradient: !isOperator ? AppColors.gradientOcean : null,
                  color: !isOperator ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !isOperator
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_boat_rounded,
                      size: isExpanded ? 16 : 14,
                      color: !isOperator ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        isExpanded ? 'Mode Nelayan' : 'Nelayan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isExpanded ? 12 : 11,
                          fontWeight: FontWeight.bold,
                          color: !isOperator ? Colors.white : const Color(0xFF475569),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // 2. Pilihan Mode Operator SPBN
          Expanded(
            flex: isExpanded ? 1 : 0,
            child: InkWell(
              onTap: () {
                ref.read(appRoleProvider.notifier).setRole(UserRole.operator);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 12 : 10,
                  vertical: isExpanded ? 9 : 5,
                ),
                decoration: BoxDecoration(
                  gradient: isOperator
                      ? const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFB45309)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isOperator ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isOperator
                      ? [
                          BoxShadow(
                            color: const Color(0xFFD97706).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_gas_station_rounded,
                      size: isExpanded ? 16 : 14,
                      color: isOperator ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        isExpanded ? 'Operator SPBN' : 'Operator SPBN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isExpanded ? 12 : 11,
                          fontWeight: FontWeight.bold,
                          color: isOperator ? Colors.white : const Color(0xFF475569),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isExpanded) {
      return container;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: container,
    );
  }
}
