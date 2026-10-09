import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class SummaryCard extends StatelessWidget {
  final double totalSpent;
  final int transactionCount;
  final double monthlySpent;

  const SummaryCard({
    super.key,
    required this.totalSpent,
    required this.transactionCount,
    required this.monthlySpent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng Chi Tiêu',
                style: TextStyle(
                  color: colorScheme.onPrimary.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.account_balance_wallet,
                color: colorScheme.onPrimary.withValues(alpha: 0.85),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppConstants.formatCurrency(totalSpent),
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: colorScheme.onPrimary.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context,
                label: 'Giao dịch',
                value: '$transactionCount',
                icon: Icons.receipt_long,
              ),
              Container(
                height: 36,
                width: 1,
                color: colorScheme.onPrimary.withValues(alpha: 0.2),
              ),
              _buildStatItem(
                context,
                label: 'Tháng này',
                value: AppConstants.formatCurrency(monthlySpent),
                icon: Icons.calendar_today,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: onPrimary.withValues(alpha: 0.8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: onPrimary,
          ),
        ),
      ],
    );
  }
}
