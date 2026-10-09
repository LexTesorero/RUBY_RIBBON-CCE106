import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'product_customization_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _variantIndex = 0;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final product = appState.products.firstWhere((p) => p.id == widget.productId);
    final soldOut = product.availability == Availability.soldOut;
    final variant = product.variants.isNotEmpty ? product.variants[_variantIndex] : null;
    final unitPrice = product.basePrice + (variant?.priceDelta ?? 0);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ProductThumb(icon: product.icon, color: product.color, imageBytes: product.imageBytes, imageUrl: product.imageUrl, size: 140, availability: product.availability),
            ),
            const SizedBox(height: 20),
            Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(product.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(peso(unitPrice), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.ribbonRed)),
                const SizedBox(width: 10),
                soldOut
                    ? const StatusBadge(label: 'Sold Out', color: AppColors.danger)
                    : const StatusBadge(label: 'Available', color: AppColors.success),
              ],
            ),
            if (product.variants.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Size / Variant', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (int i = 0; i < product.variants.length; i++)
                    AppChoiceChip(
                      label: Text(product.variants[i].priceDelta == 0
                          ? product.variants[i].name
                          : '${product.variants[i].name} (+${peso(product.variants[i].priceDelta)})'),
                      selected: _variantIndex == i,
                      onSelected: soldOut ? null : (_) => setState(() => _variantIndex = i),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _QuantitySelector(
              quantity: _quantity,
              onChanged: soldOut ? null : (q) => setState(() => _quantity = q),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: soldOut
                    ? null
                    : () {
                        if (product.customizationLevel == CustomizationLevel.standard) {
                          final item = CartItem(
                            id: appState.nextCartItemId(),
                            productId: product.id,
                            productName: product.name,
                            productIcon: product.icon,
                            productColor: product.color,
                            productImageBytes: product.imageBytes, productImageUrl: product.imageUrl,
                            customizationLevel: product.customizationLevel,
                            unitBasePrice: product.basePrice,
                            variantName: variant?.name,
                            variantPriceDelta: variant?.priceDelta ?? 0,
                            quantity: _quantity,
                          );
                          appState.addToCart(item);
                          showSuccessSnack(context, '${product.name} added to cart.');
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProductCustomizationScreen(
                              productId: product.id,
                              initialVariantIndex: _variantIndex,
                              initialQuantity: _quantity,
                            ),
                          ));
                        }
                      },
                child: Text(soldOut ? 'Currently Unavailable' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int>? onChanged;
  const _QuantitySelector({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _qtyButton(Icons.remove, () => onChanged?.call(quantity > 1 ? quantity - 1 : 1)),
        Container(
          width: 52,
          alignment: Alignment.center,
          child: Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
        ),
        _qtyButton(Icons.add, () => onChanged?.call(quantity + 1)),
      ],
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.creamDark,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onChanged == null ? null : onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: AppColors.ribbonRed, size: 20)),
      ),
    );
  }
}