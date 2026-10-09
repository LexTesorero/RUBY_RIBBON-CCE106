import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  static const _steps = [OrderStatus.received, OrderStatus.baking, OrderStatus.ready, OrderStatus.completed];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final order = appState.orderById(orderId);

    if (order == null) {
      return Scaffold(appBar: AppBar(title: const Text('Order Tracking')), body: const EmptyState(icon: Icons.error_outline, title: 'Order not found', subtitle: ''));
    }

    final cancelled = order.orderStatus == OrderStatus.cancelled;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text('Order ${order.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.id, style: Theme.of(context).textTheme.titleLarge),
                        StatusBadge(label: order.orderStatus.label, color: orderStatusColor(order.orderStatus)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (cancelled) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Cancelled — ${order.cancellationReason ?? 'No reason provided'}', style: const TextStyle(color: AppColors.danger))),
                          ],
                        ),
                      ),
                    ] else
                      _StatusStepper(current: order.orderStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _InfoCard(order: order),
            const SizedBox(height: 18),
            Text('Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    for (final item in order.items) ...[
                      Row(
                        children: [
                          ProductThumb(icon: item.productIcon, color: item.productColor, imageBytes: item.productImageBytes, imageUrl: item.productImageUrl, size: 40),                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.productName} × ${item.quantity}', style: Theme.of(context).textTheme.titleSmall),
                                Text(item.customizationSummary, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          Text(peso(item.lineTotal)),
                        ],
                      ),
                      if (item != order.items.last) const Divider(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (order.isCancellableByCustomer)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                  onPressed: () async {
                    final reason = await showCancelOrderDialog(context);
                    if (reason != null) {
                      appState.cancelOrder(order.id, reason);
                      if (context.mounted) showSuccessSnack(context, 'Order cancelled.');
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Order'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Order order;
  const _InfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(context, 'Payment Status', order.paymentStatus.label, valueColor: order.paymentStatus.color),
            _row(context, 'Payment Method', order.paymentMethodLabel ?? '—'),
            _row(context, 'Transaction Ref.', order.transactionRef ?? '—'),
            _row(context, 'Fulfillment', order.fulfillmentMethod.label),
            _row(context, 'Scheduled', DateFormat('MMM d, y • h:mm a').format(order.scheduledDateTime)),
            if (order.deliveryAddress != null) _row(context, 'Delivery Address', order.deliveryAddress!),
            _row(context, 'Total', peso(order.total), bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v, {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? (bold ? AppColors.ribbonRed : AppColors.chocolate),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final OrderStatus current;
  const _StatusStepper({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = OrderTrackingScreen._steps;
    final currentIndex = current.stepIndex;
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: i <= currentIndex ? AppColors.ribbonRed : AppColors.creamDark,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      i < currentIndex ? Icons.check : Icons.circle,
                      size: i < currentIndex ? 16 : 8,
                      color: i <= currentIndex ? Colors.white : AppColors.chocolateSoft,
                    ),
                  ),
                  if (i != steps.length - 1)
                    Container(width: 2, height: 32, color: i < currentIndex ? AppColors.ribbonRed : AppColors.creamDark),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  steps[i].label,
                  style: TextStyle(
                    fontWeight: i == currentIndex ? FontWeight.w800 : FontWeight.w500,
                    color: i <= currentIndex ? AppColors.chocolate : AppColors.chocolateSoft,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
