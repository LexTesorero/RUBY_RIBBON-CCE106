import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'order_management_screen.dart';

enum _DateFilter { today, thisWeek, thisMonth, custom }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _DateFilter _filter = _DateFilter.thisMonth;
  DateTimeRange? _customRange;

  DateTime? get _start {
    final now = DateTime.now();
    switch (_filter) {
      case _DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case _DateFilter.thisWeek:
        return now.subtract(Duration(days: now.weekday - 1));
      case _DateFilter.thisMonth:
        return DateTime(now.year, now.month, 1);
      case _DateFilter.custom:
        return _customRange?.start;
    }
  }

  DateTime? get _end {
    if (_filter == _DateFilter.custom) return _customRange?.end.add(const Duration(days: 1));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final analytics = appState.computeAnalytics(start: _start, end: _end);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              AppChoiceChip(label: const Text('Today'), selected: _filter == _DateFilter.today, onSelected: (_) => setState(() => _filter = _DateFilter.today)),
              AppChoiceChip(label: const Text('This Week'), selected: _filter == _DateFilter.thisWeek, onSelected: (_) => setState(() => _filter = _DateFilter.thisWeek)),
              AppChoiceChip(label: const Text('This Month'), selected: _filter == _DateFilter.thisMonth, onSelected: (_) => setState(() => _filter = _DateFilter.thisMonth)),
              AppChoiceChip(
                label: Text(_customRange == null ? 'Custom Range' : '${_customRange!.start.month}/${_customRange!.start.day} - ${_customRange!.end.month}/${_customRange!.end.day}'),
                selected: _filter == _DateFilter.custom,
                onSelected: (_) async {
                  final range = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now().add(const Duration(days: 1)));
                  if (range != null) setState(() {
                    _customRange = range;
                    _filter = _DateFilter.custom;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _MetricCard(label: 'Total Sales', value: peso(analytics.totalSales), color: AppColors.ribbonRed, onTap: () {}),
              _MetricCard(label: 'Total Orders', value: '${analytics.totalOrders}', color: AppColors.chocolate, onTap: _openOrders),
              _MetricCard(label: 'Completed Orders', value: '${analytics.completedOrders}', color: AppColors.success, onTap: _openOrders),
              _MetricCard(label: 'Pending Orders', value: '${analytics.pendingOrders}', color: AppColors.warning, onTap: _openOrders),
              _MetricCard(label: 'Cancelled Orders', value: '${analytics.cancelledOrders}', color: AppColors.danger, onTap: _openOrders),
            ],
          ),
          SectionHeader(title: 'Payment Status Summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  for (final status in PaymentStatus.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(label: status.label, color: status.color),
                          Text('${analytics.paymentStatusSummary[status] ?? 0} orders'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SectionHeader(title: 'Sales by Product'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: analytics.salesByProduct.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('No sales recorded for this period.'))
                  : Column(
                      children: [
                        for (final e in (analytics.salesByProduct.entries.toList()..sort((a, b) => b.value.compareTo(a.value))))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis)),
                                Text('${analytics.unitsByProduct[e.key] ?? 0} sold', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(width: 10),
                                Text(peso(e.value), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ribbonRed)),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          SectionHeader(title: 'Sales by Category'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: analytics.salesByCategory.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('No sales recorded for this period.'))
                  : Column(
                      children: [
                        for (final e in analytics.salesByCategory.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key.label),
                                Text(peso(e.value), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ribbonRed)),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          SectionHeader(title: 'Sales Over Time'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: analytics.salesOverTime.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('No sales recorded for this period.'))
                  : Column(
                      children: [
                        for (final e in (analytics.salesOverTime.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key),
                                Text(peso(e.value), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ribbonRed)),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          SectionHeader(title: 'Payment Method Breakdown'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  for (final m in PaymentMethod.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m.label),
                          Text('${(analytics.paymentMethodBreakdown[m]?[0] ?? 0)} txns'),
                          Text(peso(analytics.paymentMethodBreakdown[m]?[1] ?? 0), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ribbonRed)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _openOrders() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Order Management')), body: const OrderManagementScreen())));
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  const _MetricCard({required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
