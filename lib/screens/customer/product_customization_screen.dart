import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/customer_crud_service.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ProductCustomizationScreen extends StatefulWidget {
  final String productId;
  final int initialVariantIndex;
  final int initialQuantity;

  const ProductCustomizationScreen({
    super.key,
    required this.productId,
    this.initialVariantIndex = 0,
    this.initialQuantity = 1,
  });

  @override
  State<ProductCustomizationScreen> createState() => _ProductCustomizationScreenState();
}

class _ProductCustomizationScreenState extends State<ProductCustomizationScreen> {
  late int _variantIndex = widget.initialVariantIndex;
  late int _quantity = widget.initialQuantity;

  // Modular: option name -> selected choice index
  final Map<String, int?> _selectedChoices = {};

  // Bespoke fields
  final _instructionsController = TextEditingController();
  final _messageController = TextEditingController();
  final _crud = CustomerCrudService();
  String? _referenceImageName;
  Uint8List? _referenceBytes;
  String? _referenceUrl;
  bool _uploading = false;

  @override
  void dispose() {
    _instructionsController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickReference() async {
    setState(() => _uploading = true);
    try {
      final picked = await _crud.pickReferenceImage();
      if (picked != null && mounted) {
        setState(() {
          _referenceBytes = picked.bytes;
          _referenceUrl = picked.url;
          _referenceImageName = 'reference_${DateTime.now().millisecondsSinceEpoch % 100000}.jpg';
        });
      }
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not upload the image. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeReference() => setState(() {
        _referenceBytes = null;
        _referenceUrl = null;
        _referenceImageName = null;
      });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final product = appState.products.firstWhere((p) => p.id == widget.productId);
    final variant = product.variants.isNotEmpty ? product.variants[_variantIndex] : null;

    double addOnsTotal = 0;
    final selectedList = <SelectedModularChoice>[];
    if (product.customizationLevel == CustomizationLevel.modular) {
      for (final option in product.modularOptions) {
        final idx = _selectedChoices[option.name];
        if (idx != null) {
          final choice = option.choices[idx];
          addOnsTotal += choice.priceDelta;
          selectedList.add(SelectedModularChoice(optionName: option.name, choiceLabel: choice.label, priceDelta: choice.priceDelta));
        }
      }
    }

    final unitPrice = product.basePrice + (variant?.priceDelta ?? 0) + addOnsTotal;
    final total = unitPrice * _quantity;

    final missingRequired = product.customizationLevel == CustomizationLevel.modular &&
        product.modularOptions.any((o) => o.required && _selectedChoices[o.name] == null);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text('Customize ${product.name}')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 16, offset: const Offset(0, 8))],
                      ),
                      child: ClipOval(
                        child: ProductThumb(icon: product.icon, color: product.color, imageBytes: product.imageBytes, imageUrl: product.imageUrl, size: 148),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      product.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (product.variants.isNotEmpty) ...[
                    const SizedBox(height: 22),
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
                            onSelected: (_) => setState(() => _variantIndex = i),
                          ),
                      ],
                    ),
                  ],
                  if (product.customizationLevel == CustomizationLevel.modular) ...[
                    for (final option in product.modularOptions) ...[
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Text(option.name, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(width: 8),
                          if (option.required)
                            const StatusBadge(label: 'Required', color: AppColors.danger)
                          else
                            const StatusBadge(label: 'Optional', color: AppColors.chocolateSoft),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (int i = 0; i < option.choices.length; i++)
                            AppChoiceChip(
                              label: Text(option.choices[i].priceDelta == 0
                                  ? option.choices[i].label
                                  : '${option.choices[i].label} (+${peso(option.choices[i].priceDelta)})'),
                              selected: _selectedChoices[option.name] == i,
                              onSelected: (_) => setState(() => _selectedChoices[option.name] = i),
                            ),
                        ],
                      ),
                    ],
                  ],
                  if (product.customizationLevel == CustomizationLevel.bespoke) ...[
                    const SizedBox(height: 22),
                    Text('Reference Image', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    if (_referenceImageName == null)
                      OutlinedButton.icon(
                        onPressed: _uploading ? null : _pickReference,
                        icon: const Icon(Icons.upload_rounded),
                        label: Text(_uploading ? 'Uploading…' : 'Upload Reference Image'),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _referenceBytes != null
                                  ? Image.memory(_referenceBytes!, width: 44, height: 44, fit: BoxFit.cover)
                                  : const SizedBox(width: 44, height: 44, child: Icon(Icons.image_rounded, color: AppColors.ribbonRed)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_referenceImageName!, overflow: TextOverflow.ellipsis)),
                            IconButton(icon: const Icon(Icons.close), onPressed: _removeReference),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text('Design Instructions', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _instructionsController,
                      maxLines: 3,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: 'Describe the look you want…'),
                    ),
                    const SizedBox(height: 20),
                    Text('Cake Message (optional)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _messageController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: 'Happy Birthday, Ella!'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: AppColors.chocolateSoft.withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Fixed recipe & size — custom dimensions aren\'t supported.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.chocolateSoft.withOpacity(0.8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(width: 46, child: Center(child: Text('$_quantity', style: Theme.of(context).textTheme.titleMedium))),
                      IconButton.filledTonal(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customization Summary', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 6),
                        if (variant != null) Text('• ${variant.name}'),
                        for (final s in selectedList) Text('• ${s.optionName}: ${s.choiceLabel}'),
                        if (product.customizationLevel == CustomizationLevel.bespoke) ...[
                          if (_referenceImageName != null) const Text('• Reference image attached'),
                          if (_instructionsController.text.isNotEmpty) const Text('• Design instructions provided'),
                          if (_messageController.text.isNotEmpty) Text('• Message: "${_messageController.text}"'),
                        ],
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Unit Price', style: Theme.of(context).textTheme.bodyMedium),
                            Text(peso(unitPrice), style: Theme.of(context).textTheme.titleSmall),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total ($_quantity pc)', style: Theme.of(context).textTheme.titleMedium),
                            Text(peso(total), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.ribbonRed)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: missingRequired || _uploading
                          ? null
                          : () {
                              final item = CartItem(
                                id: appState.nextCartItemId(),
                                productId: product.id,
                                productName: product.name,
                                productIcon: product.icon,
                                productColor: product.color,
                                productImageBytes: product.imageBytes,
                                productImageUrl: product.imageUrl,
                                customizationLevel: product.customizationLevel,
                                unitBasePrice: product.basePrice,
                                variantName: variant?.name,
                                variantPriceDelta: variant?.priceDelta ?? 0,
                                selectedModularChoices: selectedList,
                                bespokeInstructions: _instructionsController.text.isEmpty ? null : _instructionsController.text,
                                bespokeMessage: _messageController.text.isEmpty ? null : _messageController.text,
                                bespokeReferenceImageName: _referenceImageName,
                                bespokeReferenceUrl: _referenceUrl,
                                quantity: _quantity,
                              );
                              appState.addToCart(item);
                              showSuccessSnack(context, '${product.name} added to cart.');
                              Navigator.of(context).popUntil((r) => r.isFirst);
                            },
                      child: Text(missingRequired ? 'Select Required Options' : 'Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}