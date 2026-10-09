import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import 'order_confirmation_screen.dart';

enum _PayState { pending, processing, failed }

class PaymentScreen extends StatefulWidget {
  final PaymentMethod method;
  const PaymentScreen({super.key, required this.method});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PayState _state = _PayState.pending;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final total = appState.cartSubtotal;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_state == _PayState.processing) return; // don't leave while saving
        final leave = await showConfirmDialog(context, title: 'Cancel payment?', message: 'Your order will not be placed.', confirmLabel: 'Yes, Cancel', danger: true);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Payment')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Amount to Pay', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(peso(total), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.ribbonRed)),
                      const SizedBox(height: 10),
                      StatusBadge(label: widget.method.label, color: AppColors.gold),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_state != _PayState.failed) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)),
                  child: Column(
                    children: [
                      _MockQrCode(method: widget.method),
                      const SizedBox(height: 14),
                      Text(
                        widget.method == PaymentMethod.qrph
                            ? 'Scan this QR code using any QR Ph-supported banking or e-wallet app.'
                            : 'Open your ${widget.method.label} app and scan this QR, or tap Confirm Payment',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Status', style: Theme.of(context).textTheme.titleMedium),
                    StatusBadge(
                      label: _state == _PayState.processing ? 'Processing…' : 'Pending',
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ] else ...[
                _PaymentFailedCard(onRetry: () => setState(() => _state = _PayState.pending)),
              ],
              const SizedBox(height: 28),
              if (_state != _PayState.failed) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _state == _PayState.processing ? null : () => _confirmPayment(appState),
                    child: Text(_state == _PayState.processing ? 'Confirming…' : 'Confirm Payment'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _state == _PayState.processing
                        ? null
                        : () async {
                            final leave = await showConfirmDialog(context, title: 'Cancel payment?', message: 'Your order will not be placed.', confirmLabel: 'Yes, Cancel', danger: true);
                            if (leave && context.mounted) Navigator.of(context).pop();
                          },
                    child: const Text('Cancel Payment'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPayment(AppState appState) async {
    setState(() => _state = _PayState.processing);
    await Future.delayed(const Duration(milliseconds: 900)); // fake gateway delay
    if (!mounted) return;

    // Saves the order + payment record to Firestore; null means it failed
    // (the error snackbar is shown by AppState and the cart is kept).
    final order = await appState.completeOrderWithPayment(widget.method);
    if (!mounted) return;

    if (order == null) {
      setState(() => _state = _PayState.failed);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderConfirmationScreen(orderId: order.id)),
      (r) => r.isFirst,
    );
  }

  void _simulateFailure() => setState(() => _state = _PayState.failed);
}

class _MockQrCode extends StatelessWidget {
  final PaymentMethod method;
  const _MockQrCode({required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(color: AppColors.chocolate, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 130),
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
              child: Text(method.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.chocolate)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentFailedCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _PaymentFailedCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.danger.withOpacity(0.3))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0x1AC1272D), shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 40),
          ),
          const SizedBox(height: 14),
          Text('Payment Failed', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.danger)),
          const SizedBox(height: 6),
          Text(
            'We couldn\'t process your payment. No charges were made and your cart is unchanged. Please try again.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onRetry, child: const Text('Retry Payment'))),
        ],
      ),
    );
  }
}