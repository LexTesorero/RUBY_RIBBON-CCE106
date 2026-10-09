import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';

class StaffOrderDetailsScreen extends StatelessWidget {
  final String orderId;
  const StaffOrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final order = appState.orderById(orderId);

    if (order == null) {
      return Scaffold(appBar: AppBar(title: const Text('Order Details')), body: const EmptyState(icon: Icons.error_outline, title: 'Order not found', subtitle: ''));
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text('Order ${order.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(label: order.orderStatus.label, color: orderStatusColor(order.orderStatus)),
                StatusBadge(label: order.paymentStatus.label, color: order.paymentStatus.color),
              ],
            ),
            const SizedBox(height: 18),
            Text('Customer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _kv(context, 'Name', order.customerName),
                    _kv(context, 'Contact', order.customerContact),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Products', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    for (final item in order.items) ...[
                      Row(
                        children: [
                          ProductThumb(icon: item.productIcon, color: item.productColor, imageBytes: item.productImageBytes, imageUrl: item.productImageUrl, size: 44),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.productName} × ${item.quantity}', style: Theme.of(context).textTheme.titleSmall),
                                Text(item.customizationSummary, style: Theme.of(context).textTheme.bodyMedium),
                                if (item.referenceImageUrl != null) ...[
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.referenceImageUrl!,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Text('Reference image unavailable', style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(peso(item.lineTotal)),
                        ],
                      ),
                      if (item != order.items.last) const Divider(height: 22),
                    ],
                    const Divider(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order Total', style: Theme.of(context).textTheme.titleMedium),
                        Text(peso(order.total), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.ribbonRed)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => _showPaymentRecord(context, order),
                  icon: const Icon(Icons.receipt_rounded, size: 18),
                  label: const Text('View Payment'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _kv(context, 'Method', order.paymentMethodLabel ?? '—'),
                    _kv(context, 'Transaction Ref.', order.transactionRef ?? '—'),
                    _kv(context, 'Status', order.paymentStatus.label, valueColor: order.paymentStatus.color),
                  ],
                ),
              ),
            ),
            if (order.paymentMethodLabel == 'Cash' && order.orderStatus != OrderStatus.cancelled) ...[
              const SizedBox(height: 10),
              _CashPaymentControl(order: order),
            ],
            const SizedBox(height: 18),
            Text('Fulfillment', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _kv(context, 'Method', order.fulfillmentMethod.label),
                    _kv(context, 'Schedule', order.isImmediate ? 'Immediate' : DateFormat('MMM d, y • h:mm a').format(order.scheduledDateTime)),
                    if (order.deliveryAddress != null) _kv(context, 'Delivery Address', order.deliveryAddress!),
                    if (order.cancellationReason != null) _kv(context, 'Cancellation Reason', order.cancellationReason!, valueColor: AppColors.danger),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _ActionButtons(order: order),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(child: Text(v, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, color: valueColor ?? AppColors.chocolate))),
        ],
      ),
    );
  }

  void _showPaymentRecord(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Payment Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv(ctx, 'Order', order.id),
            _kv(ctx, 'Method', order.paymentMethodLabel ?? '—'),
            _kv(ctx, 'Amount', peso(order.total)),
            _kv(ctx, 'Transaction Ref.', order.transactionRef ?? '—'),
            _kv(ctx, 'Status', order.paymentStatus.label, valueColor: order.paymentStatus.color),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Order order;
  const _ActionButtons({required this.order});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final status = order.orderStatus;

    if (status == OrderStatus.completed || status == OrderStatus.cancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(status == OrderStatus.completed ? Icons.task_alt_rounded : Icons.cancel_rounded,
                color: status == OrderStatus.completed ? AppColors.success : AppColors.danger),
            const SizedBox(width: 10),
            Expanded(child: Text('This order is ${status.label.toLowerCase()}. No further actions available.')),
          ],
        ),
      );
    }

    OrderStatus? nextStatus;
    String? nextLabel;
    if (status == OrderStatus.received) {
      nextStatus = OrderStatus.baking;
      nextLabel = order.hasCustomizedItems ? 'Accept Order & Start Preparation' : 'Start Preparation';
    } else if (status == OrderStatus.baking) {
      nextStatus = OrderStatus.ready;
      nextLabel = 'Mark Ready';
    } else if (status == OrderStatus.ready) {
      nextStatus = OrderStatus.completed;
      nextLabel = 'Mark Completed';
    }

    return Column(
      children: [
        if (nextStatus != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(nextLabel!),
              onPressed: () async {
                final target = nextStatus!;
                final confirmed = await showOrderStatusUpdateDialog(context, target);
                if (confirmed) {
                  appState.updateOrderStatus(order.id, target);
                  if (context.mounted) showSuccessSnack(context, 'Order marked as "${target.label}".');
                }
              },
            ),
          ),
        // Staff can still cancel (emergencies, refunds). Customers use
        // isCancellableByCustomer on their own screen.
        if (order.isCancellable) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Order'),
              onPressed: () async {
                final reason = await showCancelOrderDialog(context);
                if (reason != null) {
                  appState.cancelOrder(order.id, reason);
                  if (context.mounted) showSuccessSnack(context, 'Order cancelled.');
                }
              },
            ),
          ),
        ],
        // Cash is handled by _CashPaymentControl in the Payment section.
        if (order.paymentStatus == PaymentStatus.pending && order.paymentMethodLabel != 'Cash') ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.verified_rounded),
              label: const Text('Verify Payment as Paid'),
              onPressed: () async {
                final confirmed = await showConfirmDialog(context,
                    title: 'Verify payment?',
                    message: 'Only do this after confirming the payment through your official channel (e.g. bank transfer receipt).');
                if (confirmed) {
                  appState.staffVerifyPaymentAsPaid(order.id);
                  if (context.mounted) showSuccessSnack(context, 'Payment marked as Paid.');
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Staff control for CASH orders: confirm cash received, or revert to unpaid.
/// Shown in the Payment section so it also works after the order is Completed.
/// For modular/bespoke orders, cash can be confirmed only after the baker
/// accepts the order (status moves past "Received").
class _CashPaymentControl extends StatelessWidget {
  final Order order;
  const _CashPaymentControl({required this.order});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final isPaid = order.paymentStatus == PaymentStatus.paid;
    final isPending = order.paymentStatus == PaymentStatus.pending;
    if (!isPaid && !isPending) return const SizedBox.shrink(); // refunded/failed: not editable

    if (isPending) {
      final needsApproval = order.hasCustomizedItems && order.orderStatus == OrderStatus.received;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Mark Cash as Paid'),
              onPressed: needsApproval
                  ? null
                  : () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Confirm cash received?',
                        message: 'Confirm that you have received ${peso(order.total)} in cash from the customer.',
                      );
                      if (confirmed) {
                        appState.staffSetCashPaid(order.id, paid: true);
                        if (context.mounted) showSuccessSnack(context, 'Payment marked as Paid.');
                      }
                    },
            ),
          ),
          if (needsApproval)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Modified/bespoke order: accept it (Start Preparation) before confirming cash.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.undo_rounded),
        label: const Text('Mark as Unpaid'),
        onPressed: () async {
          final confirmed = await showConfirmDialog(
            context,
            title: 'Mark as unpaid?',
            message: 'Use this only to correct a mistake. The payment will go back to Pending.',
          );
          if (confirmed) {
            appState.staffSetCashPaid(order.id, paid: false);
            if (context.mounted) showSuccessSnack(context, 'Payment set back to Pending.');
          }
        },
      ),
    );
  }
}