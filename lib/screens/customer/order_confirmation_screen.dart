import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'customer_shell.dart';
import 'order_tracking_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final order = appState.orderById(orderId);

    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0x1A2E8B57), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
              ),
              const SizedBox(height: 18),
              Text('Order Placed!', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('Thank you! Your payment was successful and your order is now being processed.',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order.id, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.ribbonRed)),
                          StatusBadge(label: order.paymentStatus.label, color: order.paymentStatus.color),
                        ],
                      ),
                      Text(DateFormat('EEE, MMM d, y • h:mm a').format(order.createdAt), style: Theme.of(context).textTheme.bodyMedium),
                      const Divider(height: 26),
                      for (final item in order.items) ...[
                        Row(
                          children: [
                            ProductThumb(
                              icon: item.productIcon,
                              color: item.productColor,
                              imageBytes: item.productImageBytes,
                              imageUrl: item.productImageUrl,
                              size: 40,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item.productName} × ${item.quantity}', style: Theme.of(context).textTheme.titleSmall),
                                  Text(item.customizationSummary, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Text(peso(item.lineTotal)),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      const Divider(height: 10),
                      const SizedBox(height: 10),
                      _kv(context, 'Total Amount', peso(order.total), bold: true),
                      _kv(context, 'Payment Method', order.paymentMethodLabel ?? '—'),
                      _kv(context, 'Fulfillment', order.fulfillmentMethod.label),
                      _kv(context, 'Schedule', DateFormat('MMM d, y • h:mm a').format(order.scheduledDateTime)),
                      if (order.deliveryAddress != null) _kv(context, 'Delivery Address', order.deliveryAddress!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id))),
                  child: const Text('Track Order'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const CustomerShell()), (r) => false),
                  child: const Text('Back to Menu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            v,
            style: bold
                ? Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.ribbonRed)
                : Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}