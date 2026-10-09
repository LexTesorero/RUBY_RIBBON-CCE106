import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'staff_order_details_screen.dart';

class StaffDashboardScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const StaffDashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final orders = appState.orders;
    final total = orders.length;
    final pending = orders.where((o) => o.orderStatus == OrderStatus.received).length;
    final preparing = orders.where((o) => o.orderStatus == OrderStatus.baking).length;
    final ready = orders.where((o) => o.orderStatus == OrderStatus.ready).length;
    final completed = orders.where((o) => o.orderStatus == OrderStatus.completed).length;
    final totalSales = orders
        .where((o) => o.paymentStatus == PaymentStatus.paid && o.orderStatus != OrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.total);
    final recent = orders.reversed.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(label: 'Total Orders', value: '$total', icon: Icons.receipt_long_rounded, color: AppColors.ribbonRed, onTap: () => onNavigate(1)),
              _StatCard(label: 'Pending (Received)', value: '$pending', icon: Icons.hourglass_top_rounded, color: AppColors.warning, onTap: () => onNavigate(1)),
              _StatCard(label: 'Being Prepared', value: '$preparing', icon: Icons.soup_kitchen_rounded, color: const Color(0xFF3A6FB0), onTap: () => onNavigate(1)),
              _StatCard(label: 'Ready', value: '$ready', icon: Icons.inventory_2_rounded, color: AppColors.gold, onTap: () => onNavigate(1)),
              _StatCard(label: 'Completed', value: '$completed', icon: Icons.task_alt_rounded, color: AppColors.success, onTap: () => onNavigate(1)),
              _StatCard(label: 'Total Sales', value: peso(totalSales), icon: Icons.payments_rounded, color: AppColors.chocolate, onTap: () => onNavigate(3)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Quick Navigation', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _QuickNavButton(icon: Icons.receipt_long_rounded, label: 'Order\nManagement', onTap: () => onNavigate(1))),
              const SizedBox(width: 10),
              Expanded(child: _QuickNavButton(icon: Icons.bakery_dining_rounded, label: 'Product\nManagement', onTap: () => onNavigate(2))),
              const SizedBox(width: 10),
              Expanded(child: _QuickNavButton(icon: Icons.bar_chart_rounded, label: 'Sales &\nAnalytics', onTap: () => onNavigate(3))),
            ],
          ),
          SectionHeader(title: 'Recent Orders', actionLabel: 'View All', onAction: () => onNavigate(1)),
          if (recent.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: EmptyState(icon: Icons.inbox_outlined, title: 'No orders yet', subtitle: ''))
          else
            for (final o in recent)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('${o.id} • ${o.customerName}'),
                  subtitle: Text('${DateFormat('MMM d, h:mm a').format(o.createdAt)} • ${peso(o.total)}'),
                  trailing: StatusBadge(label: o.orderStatus.label, color: orderStatusColor(o.orderStatus)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StaffOrderDetailsScreen(orderId: o.id))),
                ),
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
  final VoidCallback onTap;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.onTap});

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
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color)),
              Text(label, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickNavButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.ribbonRed),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
