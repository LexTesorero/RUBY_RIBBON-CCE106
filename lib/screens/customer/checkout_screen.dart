import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/order_rules.dart';
import '../../widgets/common_widgets.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: context.read<AppState>().draftContactName);
  late final _contactController = TextEditingController(text: context.read<AppState>().draftContactNumber);
  late final _addressController = TextEditingController(text: context.read<AppState>().draftAddress);

  bool _immediate = true; // Immediate pickup/delivery vs Scheduled
  DateTime? _schedule; // only used when scheduled
  PaymentMethod? _paymentMethod;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cart = appState.cart;
    final subtotal = appState.cartSubtotal;
    final isPickup = appState.draftFulfillment == FulfillmentMethod.pickup;

    // Business rules
    final hasModular = appState.cartHasModular;
    final hasBespoke = appState.cartHasBespoke;
    final cashOk = isCashAllowed(isImmediate: _immediate);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Order Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    for (final item in cart) ...[
                      Row(
                        children: [
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
                      if (item != cart.last) const Divider(height: 20),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: Theme.of(context).textTheme.titleLarge),
                        Text(peso(subtotal), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.ribbonRed)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('Fulfillment Method', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FulfillmentOption(
                    label: 'Pickup',
                    icon: Icons.storefront_rounded,
                    selected: isPickup,
                    onTap: () => setState(() => appState.draftFulfillment = FulfillmentMethod.pickup),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FulfillmentOption(
                    label: 'Delivery',
                    icon: Icons.delivery_dining_rounded,
                    selected: !isPickup,
                    onTap: () => setState(() => appState.draftFulfillment = FulfillmentMethod.delivery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('When do you need it?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FulfillmentOption(
                    label: isPickup ? 'Immediate Pickup' : 'Immediate Delivery',
                    icon: Icons.bolt_rounded,
                    selected: _immediate,
                    onTap: () => _setImmediate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FulfillmentOption(
                    label: 'Scheduled',
                    icon: Icons.event_rounded,
                    selected: !_immediate,
                    onTap: () => _setImmediate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _immediate
                  ? 'We will prepare your order right away. Cash is accepted.'
                  : 'Choose a date and time. Scheduled orders require online payment.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!_immediate) ...[
              const SizedBox(height: 14),
              Text('Scheduled ${isPickup ? 'Pickup' : 'Delivery'} Date & Time', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickSchedule,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.event_rounded)),
                  child: Text(
                    _schedule == null ? 'Tap to select date & time' : DateFormat('EEE, MMM d, y • h:mm a').format(_schedule!),
                    style: TextStyle(color: _schedule == null ? AppColors.chocolateSoft : AppColors.chocolate),
                  ),
                ),
              ),
            ],
            if (!isPickup) ...[
              const SizedBox(height: 18),
              Text('Delivery Address', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'House/Unit No., Street, Barangay, City'),
                validator: (v) {
                  if (appState.draftFulfillment == FulfillmentMethod.delivery && (v == null || v.trim().isEmpty)) {
                    return 'Delivery address is required';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 18),
            Text('Contact Information', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Contact Name', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 18),
            Text('Payment Method', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final m in PaymentMethod.values)
              Builder(builder: (_) {
                final enabled = m != PaymentMethod.cash || cashOk;
                return RadioListTile<PaymentMethod>(
                  contentPadding: EdgeInsets.zero,
                  value: m,
                  groupValue: _paymentMethod,
                  onChanged: enabled ? (v) => setState(() => _paymentMethod = v) : null,
                  title: Text(m.label),
                  subtitle: enabled
                      ? null
                      : Text(
                          'Cash is for immediate pickup/delivery only',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                  secondary: Icon(_iconFor(m), color: enabled ? AppColors.ribbonRed : Colors.grey),
                );
              }),
            if (!_immediate)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Scheduled orders require online payment.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (hasBespoke || hasModular)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Modified and bespoke orders need the baker\'s approval. Cash for these is confirmed by the baker after approval.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'You can cancel an order only before baking/decorating starts.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: ElevatedButton(
            onPressed: () => _proceed(context, appState),
            child: Text(_paymentMethod == PaymentMethod.cash ? 'Place Order' : 'Proceed to Payment'),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;
      case PaymentMethod.gcash:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethod.qrph:
        return Icons.qr_code_rounded;
      case PaymentMethod.maya:
        return Icons.credit_card_rounded;
    }
  }

  void _setImmediate(bool immediate) {
    final resetCash = !immediate && _paymentMethod == PaymentMethod.cash;
    setState(() {
      _immediate = immediate;
      if (immediate) _schedule = null;
      if (resetCash) _paymentMethod = null;
    });
    if (resetCash) {
      showErrorSnack(context, 'Cash is for immediate orders only. Please choose GCash, Maya or QR Ph.');
    }
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 14, minute: 0));
    if (time == null || !mounted) return;
    setState(() => _schedule = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _proceed(BuildContext context, AppState appState) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_immediate && _schedule == null) {
      showErrorSnack(context, 'Please select a fulfillment date and time.');
      return;
    }
    if (_paymentMethod == null) {
      showErrorSnack(context, 'Please select a payment method.');
      return;
    }
    if (_paymentMethod == PaymentMethod.cash &&
        !isCashAllowed(isImmediate: _immediate)) {
      showErrorSnack(context, 'Cash is not available for this order.');
      return;
    }

    appState.draftImmediate = _immediate;
    appState.draftSchedule = _immediate ? DateTime.now() : _schedule;
    appState.draftContactName = _nameController.text;
    appState.draftContactNumber = _contactController.text;
    appState.draftAddress = _addressController.text;
    appState.draftPaymentMethod = _paymentMethod;

    if (_paymentMethod == PaymentMethod.cash) {
      // Cash: no online payment step. Saved as Pending until staff confirm the
      // cash was received (for bespoke: only after the baker accepts).
      final order = await appState.completeOrderWithPayment(PaymentMethod.cash);
      if (order == null || !context.mounted) return; // error already reported via appState.onError
      Navigator.of(context).popUntil((r) => r.isFirst);
      showSuccessSnack(context, 'Order ${order.id} placed. Please pay in cash on pickup/delivery.');
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentScreen(method: _paymentMethod!)));
  }
}

class _FulfillmentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _FulfillmentOption({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ribbonRed : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : AppColors.ribbonRed),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: selected ? Colors.white : AppColors.chocolate, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}