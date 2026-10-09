import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import 'add_edit_product_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  ProductCategory? _category;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    var products = appState.products;
    if (_category != null) products = products.where((p) => p.category == _category).toList();
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      products = products.where((p) => p.name.toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(hintText: 'Search products…', prefixIcon: Icon(Icons.search)),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              children: [
                AppChoiceChip(label: const Text('All'), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
                const SizedBox(width: 8),
                for (final c in ProductCategory.values) ...[
                  AppChoiceChip(label: Text(c.label), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products found', subtitle: 'Try a different search or category.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ProductRow(product: products[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditProductScreen())),
        icon: const Icon(Icons.add),
        foregroundColor: Colors.white70,
        label: const Text('Add Product', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600,),),
        backgroundColor: AppColors.ribbonRed,
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final hidden = product.visibility == ProductVisibility.hidden;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumb(icon: product.icon, color: product.color, imageBytes: product.imageBytes, imageUrl: product.imageUrl, size: 54, availability: product.availability),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: Theme.of(context).textTheme.titleSmall),
                      Text(product.category.label, style: Theme.of(context).textTheme.bodyMedium),
                      Text(peso(product.basePrice), style: const TextStyle(color: AppColors.ribbonRed, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hidden) const StatusBadge(label: 'Hidden', color: AppColors.chocolateSoft),
                    if (product.availability == Availability.soldOut) const StatusBadge(label: 'Sold Out', color: AppColors.danger),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Switch(
                        value: product.availability == Availability.available,
                        activeColor: AppColors.ribbonRed,
                        onChanged: (_) => appState.toggleAvailability(product.id),
                      ),
                      const Flexible(child: Text('Available', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined, color: AppColors.ribbonRed),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditProductScreen(productId: product.id))),
                ),
                IconButton(
                  tooltip: 'Archive',
                  icon: const Icon(Icons.archive_outlined, color: AppColors.chocolateSoft),
                  onPressed: () async {
                    final confirmed = await showArchiveProductDialog(context, product.name);
                    if (confirmed) {
                      appState.archiveProduct(product.id);
                      if (context.mounted) showSuccessSnack(context, '${product.name} archived.');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
