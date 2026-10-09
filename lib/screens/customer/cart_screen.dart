import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import 'login_screen.dart';
import 'checkout_screen.dart';
import 'customer_shell.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cart = appState.cart;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('My Cart')),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add some delicious treats from the menu to get started.',
              action: ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const CustomerShell()),
                  (r) => false,
                ),
                child: const Text('Browse Products'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _CartTile(item: cart[i]),
                  ),
                ),
                _CartSummary(appState: appState),
              ],
            ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _showDetails(context),
                  child: ProductThumb(icon: item.productIcon, color: item.productColor, imageBytes: item.productImageBytes, imageUrl: item.productImageUrl, size: 56),                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _showDetails(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Text(item.customizationSummary, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: () async {
                    final confirmed = await showRemoveCartItemDialog(context);
                    if (confirmed) {
                      appState.removeFromCart(item.id);
                      if (context.mounted) showSuccessSnack(context, 'Item removed from cart.');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _qtyBtn(Icons.remove, () => appState.updateCartQuantity(item.id, item.quantity > 1 ? item.quantity - 1 : 1)),
                    SizedBox(width: 36, child: Center(child: Text('${item.quantity}'))),
                    _qtyBtn(Icons.add, () => appState.updateCartQuantity(item.id, item.quantity + 1)),
                  ],
                ),
                Text(peso(item.lineTotal), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.ribbonRed)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              ProductThumb(icon: item.productIcon, color: item.productColor, imageBytes: item.productImageBytes, imageUrl: item.productImageUrl, size: 48),              const SizedBox(width: 12),
              Expanded(child: Text(item.productName, style: Theme.of(ctx).textTheme.titleLarge)),
            ]),
            const SizedBox(height: 14),
            Text('Customization', style: Theme.of(ctx).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(item.customizationSummary),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Unit Price'),
                Text(peso(item.unitPrice), style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => Material(
        color: AppColors.creamDark,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 16, color: AppColors.ribbonRed)),
        ),
      );
}

class _CartSummary extends StatelessWidget {
  final AppState appState;
  const _CartSummary({required this.appState});

  @override
  Widget build(BuildContext context) {
    final subtotal = appState.cartSubtotal;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
                Text(peso(subtotal)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleLarge),
                Text(peso(subtotal), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.ribbonRed)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!appState.isLoggedIn) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen(returnToCheckout: true)));
                  } else {
                    appState.primeCheckoutDraftFromProfile();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                  }
                },
                child: const Text('Proceed to Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
