import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(
          style: danger ? ElevatedButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> showCancelOrderDialog(BuildContext context) async {
  const reasons = [
    'Change of plans',
    'Ordered by mistake',
    'Found a better option',
    'Schedule conflict',
    'Other',
  ];
  String selected = reasons.first;
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel this order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This cannot be undone. Please select a reason:'),
            const SizedBox(height: 12),
            ...reasons.map((r) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(r),
                  value: r,
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v!),
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Order')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, selected),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    ),
  );
}

Future<bool> showRemoveCartItemDialog(BuildContext context) {
  return showConfirmDialog(
    context,
    title: 'Remove item?',
    message: 'This item will be removed from your cart.',
    confirmLabel: 'Remove',
    danger: true,
  );
}

Future<bool> showArchiveProductDialog(BuildContext context, String productName) {
  return showConfirmDialog(
    context,
    title: 'Archive "$productName"?',
    message: 'This product will be hidden from the customer menu. You can re-publish it later by editing it.',
    confirmLabel: 'Archive',
    danger: true,
  );
}

Future<bool> showLogoutDialog(BuildContext context) {
  return showConfirmDialog(
    context,
    title: 'Log out?',
    message: 'You will need to sign in again to place or track orders.',
    confirmLabel: 'Log Out',
    danger: true,
  );
}

Future<bool> showOrderStatusUpdateDialog(BuildContext context, OrderStatus next) {
  return showConfirmDialog(
    context,
    title: 'Update order status?',
    message: 'Mark this order as "${next.label}"? The customer will see this update immediately in Order Tracking.',
    confirmLabel: 'Update Status',
  );
}
