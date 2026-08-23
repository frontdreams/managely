import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/admin_providers.dart';
import '../services/admin_repository.dart';

/// Admin-only. Charts revenue aggregated from stored RevenueCat webhook
/// events (see managely-backend/routes/admin.js) — never a live call to
/// RevenueCat's API, which doesn't expose bulk analytics. Gated the same
/// way as [UserManagementScreen].
class RevenueScreen extends ConsumerWidget {
  const RevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(adminRevenueProvider);
    final range = ref.watch(revenueRangeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Revenue')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _RangeFilter(
              selected: range,
              onChanged: (r) => ref.read(revenueRangeProvider.notifier).state = r,
            ),
            const SizedBox(height: 20),
            revenueAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: _ErrorState(onRetry: () => ref.invalidate(adminRevenueProvider)),
              ),
              data: (summary) => _RevenueContent(summary: summary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeFilter extends StatelessWidget {
  final RevenueRange selected;
  final ValueChanged<RevenueRange> onChanged;
  const _RangeFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = {
      RevenueRange.last7Days: '7 Days',
      RevenueRange.last30Days: '30 Days',
      RevenueRange.last90Days: '90 Days',
    };

    return Row(
      children: options.entries.map((entry) {
        final isSelected = entry.key == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected ? Colors.white : null,
                      ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RevenueContent extends StatelessWidget {
  final RevenueSummary summary;
  const _RevenueContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Revenue',
                value: currencyFormat.format(summary.totalRevenue),
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Transactions',
                value: '${summary.transactionCount}',
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Revenue Over Time', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        if (summary.series.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No revenue in this range yet.', style: theme.textTheme.bodyMedium),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: _RevenueBarChart(series: summary.series),
          ),
      ],
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  final List<RevenuePoint> series;
  const _RevenueBarChart({required this.series});

  @override
  Widget build(BuildContext context) {
    final maxY = series.map((p) => p.amount).fold<double>(0, (a, b) => a > b ? a : b);
    final safeMaxY = maxY == 0 ? 10.0 : maxY * 1.2;
    // Thin out x-axis labels if there are many points.
    final labelStep = (series.length / 6).ceil().clamp(1, series.length);

    return BarChart(
      BarChartData(
        maxY: safeMaxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = series[group.x.toInt()];
              return BarTooltipItem(
                '\$${point.amount.toStringAsFixed(2)}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: DateFormat.MMMd().format(point.date),
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.normal),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '\$${value.toInt()}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= series.length || i % labelStep != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat.Md().format(series[i].date),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppColors.borderLight, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < series.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: series[i].amount,
                  color: AppColors.primary,
                  width: series.length > 20 ? 4 : 12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value, style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
          const SizedBox(height: 12),
          const Text('Couldn\'t load revenue data.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}