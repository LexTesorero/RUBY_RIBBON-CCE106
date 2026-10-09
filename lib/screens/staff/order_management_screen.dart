import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'staff_order_details_screen.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  OrderStatus? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    var orders = appState.orders.reversed.toList();

    if (_filter != null) orders = orders.where((o) => o.orderStatus == _filter).toList();
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      orders = orders.where((o) => o.id.toLowerCase().contains(q) || o.customerName.toLowerCase().contains(q)).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(hintText: 'Search order number or customer name…', prefixIcon: Icon(Icons.search)),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            children: [
              AppChoiceChip(label: const Text('All'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
              const SizedBox(width: 8),
              for (final s in OrderStatus.values) ...[
                ChoiceChip(label: Text(s.label), selected: _filter == s, onSelected: (_) => setState(() => _filter = s)),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? const EmptyState(icon: Icons.inbox_outlined, title: 'No orders found', subtitle: 'Try a different search term or filter.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _OrderRow(order: orders[i]),
                ),
        ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  final Order order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StaffOrderDetailsScreen(orderId: order.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.id, style: Theme.of(context).textTheme.titleMedium),
                  StatusBadge(label: order.orderStatus.label, color: orderStatusColor(order.orderStatus)),
                ],
              ),
              const SizedBox(height: 4),
              Text(order.customerName, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(DateFormat('MMM d, y • h:mm a').format(order.createdAt), style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(order.fulfillmentMethod == FulfillmentMethod.pickup ? Icons.storefront_rounded : Icons.delivery_dining_rounded, size: 16, color: AppColors.chocolateSoft),
                    const SizedBox(width: 4),
                    Text(order.fulfillmentMethod.label, style: Theme.of(context).textTheme.bodyMedium),
                  ]),
                  StatusBadge(label: order.paymentStatus.label, color: order.paymentStatus.color),
                  Text(peso(order.total), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.ribbonRed)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
