import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'product_details_screen.dart';

class MenuScreen extends StatefulWidget {
  final VoidCallback onOpenCart;
  const MenuScreen({super.key, required this.onOpenCart});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  ProductCategory? _category;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final products = appState.visibleForCustomer(category: _category, query: _query);
    final featured = _query.isEmpty && _category == null ? appState.featuredProducts : <Product>[];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.ribbonRed, shape: BoxShape.circle),
                      child: const Icon(Icons.cake_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Ruby Ribbon Bakeshop', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    IconButton(
                      onPressed: widget.onOpenCart,
                      icon: Badge(
                        label: Text('${appState.cartItemCount}'),
                        isLabelVisible: appState.cartItemCount > 0,
                        child: const Icon(Icons.shopping_cart_rounded, color: AppColors.ribbonRed),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search cakes, pastries, breads…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _query = '';
                              _searchController.clear();
                            }),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  children: [
                    _CategoryChip(label: 'All', selected: _category == null, onTap: () => setState(() => _category = null)),
                    const SizedBox(width: 8),
                    for (final c in ProductCategory.values) ...[
                      _CategoryChip(label: c.label, selected: _category == c, onTap: () => setState(() => _category = c)),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            if (featured.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 6)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
                  child: Text('Featured', style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    itemCount: featured.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _FeaturedCard(product: featured[i]),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                child: Text('All Products', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            if (products.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No products found',
                    subtitle: 'Try a different search term or category.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ProductCard(product: products[i]),
                    childCount: products.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());  }
}

class _FeaturedCard extends StatelessWidget {
  final Product product;
  const _FeaturedCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumb(icon: product.icon, color: product.color, imageBytes: product.imageBytes, imageUrl: product.imageUrl, size: 52, availability: product.availability),
                const Spacer(),
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(peso(product.basePrice), style: const TextStyle(color: AppColors.ribbonRed, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final soldOut = product.availability == Availability.soldOut;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: product.id))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: ProductThumb(icon: product.icon, color: product.color, imageBytes: product.imageBytes, imageUrl: product.imageUrl, size: 68, availability: product.availability)),
              const SizedBox(height: 10),
              Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'from ${peso(product.basePrice)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.ribbonRed, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  if (soldOut) ...[
                    const SizedBox(width: 6),
                    const StatusBadge(label: 'Sold Out', color: AppColors.danger),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
