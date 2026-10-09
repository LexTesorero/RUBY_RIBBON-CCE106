import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/staff_crud_service.dart';

class _IconOption {
  final IconData icon;
  final Color color;
  const _IconOption(this.icon, this.color);
}

/// Used only as the placeholder tile for products that don't have a real
/// photo attached (e.g. the seed catalog). Picked automatically from the
/// product's category — staff no longer choose it manually.
_IconOption _fallbackIconFor(ProductCategory category) {
  switch (category) {
    case ProductCategory.cakes:
      return const _IconOption(Icons.cake_rounded, AppColors.ribbonRed);
    case ProductCategory.pastries:
      return const _IconOption(Icons.bakery_dining, AppColors.gold);
    case ProductCategory.breads:
      return const _IconOption(Icons.breakfast_dining, AppColors.chocolate);
  }
}

class _VariantRow {
  final TextEditingController name;
  final TextEditingController price;
  _VariantRow({String name = '', String price = '0'})
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price);
}

class _ChoiceRow {
  final TextEditingController label;
  final TextEditingController price;
  _ChoiceRow({String label = '', String price = '0'})
      : label = TextEditingController(text: label),
        price = TextEditingController(text: price);
}

class _ModularOptionEditor {
  final TextEditingController name;
  bool required;
  List<_ChoiceRow> choices;
  _ModularOptionEditor({String name = '', this.required = true, List<_ChoiceRow>? choices})
      : name = TextEditingController(text: name),
        choices = choices ?? [_ChoiceRow()];
}

class AddEditProductScreen extends StatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Product? _existing;

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late ProductCategory _category;
  late CustomizationLevel _level;
  late Availability _availability;
  late ProductVisibility _visibility;
  Uint8List? _imageBytes;
  final StaffCrudService _crud = StaffCrudService();
  String? _imageUrl;
  bool _uploading = false;
  late List<_VariantRow> _variants;
  late List<_ModularOptionEditor> _modularOptions;
  late bool _bespokeAllowImage;
  late bool _bespokeAllowMessage;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _existing = widget.productId == null ? null : appState.products.firstWhere((p) => p.id == widget.productId);

    _nameController = TextEditingController(text: _existing?.name ?? '');
    _descController = TextEditingController(text: _existing?.description ?? '');
    _priceController = TextEditingController(text: _existing != null ? _existing.basePrice.toStringAsFixed(0) : '');
    _category = _existing?.category ?? ProductCategory.cakes;
    _level = _existing?.customizationLevel ?? CustomizationLevel.standard;
    _availability = _existing?.availability ?? Availability.available;
    _visibility = _existing?.visibility ?? ProductVisibility.published;
    _imageBytes = _existing?.imageBytes;
    _imageUrl = _existing?.imageUrl;

    _variants = (_existing?.variants ?? const [])
        .map((v) => _VariantRow(name: v.name, price: v.priceDelta.toStringAsFixed(0)))
        .toList();
    if (_variants.isEmpty) _variants.add(_VariantRow(name: 'Regular'));

    _modularOptions = (_existing?.modularOptions ?? const [])
        .map((o) => _ModularOptionEditor(
              name: o.name,
              required: o.required,
              choices: o.choices.map((c) => _ChoiceRow(label: c.label, price: c.priceDelta.toStringAsFixed(0))).toList(),
            ))
        .toList();

    _bespokeAllowImage = _existing?.bespokeAllowReferenceImage ?? true;
    _bespokeAllowMessage = _existing?.bespokeAllowMessage ?? true;
  }

  bool get _isEdit => _existing != null;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _uploading = true);
    try {
      final picked = await _crud.pickImage(source: source); // picks + uploads to Cloudinary
      if (picked == null || !mounted) return;
      setState(() {
        _imageBytes = picked.bytes;
        _imageUrl = picked.url;
      });
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not upload the photo. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.chocolateSoft.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.ribbonRed),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick a photo from your device'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.ribbonRed),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use your device camera'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_imageBytes != null || _imageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.danger)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    setState(() { _imageBytes = null; _imageUrl = null; });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(_isEdit ? 'Edit Product' : 'Add Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Text('Product Photo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Upload a real photo from this device\'s gallery or camera.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showPhotoSourceSheet,
              child: Container(
                width: double.infinity,
                height: 170,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.creamDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.chocolateSoft.withOpacity(0.35)),
                ),
                child: _uploading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.ribbonRed))
                  : (_imageBytes != null || _imageUrl != null)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : Image.network(_imageUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined))),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: _PhotoActionButton(icon: Icons.edit_rounded, onTap: _showPhotoSourceSheet),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.chocolate.withOpacity(0.55)),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add a photo',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.chocolate,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text('From gallery or camera', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Product Description'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final c in ProductCategory.values)
                  AppChoiceChip(label: Text(c.label), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Base Price (₱)', prefixText: '₱ '),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('Available Sizes / Variants', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (int i = 0; i < _variants.length; i++) _variantEditor(i),
            TextButton.icon(
              onPressed: () => setState(() => _variants.add(_VariantRow())),
              icon: const Icon(Icons.add),
              label: const Text('Add Variant'),
            ),
            const SizedBox(height: 14),
            Text('Customization Level', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final l in CustomizationLevel.values)
                  AppChoiceChip(label: Text(l.label), selected: _level == l, onSelected: (_) => setState(() => _level = l)),
              ],
            ),
            const SizedBox(height: 6),
            if (_level == CustomizationLevel.standard)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(10)),
                child: const Text('Standard products need no additional customization configuration.', style: TextStyle(fontSize: 12)),
              ),
            if (_level == CustomizationLevel.modular) ...[
              const SizedBox(height: 10),
              for (int i = 0; i < _modularOptions.length; i++) _modularOptionEditor(i),
              TextButton.icon(
                onPressed: () => setState(() => _modularOptions.add(_ModularOptionEditor())),
                icon: const Icon(Icons.add),
                label: const Text('Add Modular Option'),
              ),
            ],
            if (_level == CustomizationLevel.bespoke) ...[
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow reference image upload'),
                value: _bespokeAllowImage,
                onChanged: (v) => setState(() => _bespokeAllowImage = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow written design instructions & message'),
                value: _bespokeAllowMessage,
                onChanged: (v) => setState(() => _bespokeAllowMessage = v),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(10)),
                child: const Text(
                  'Sizes remain fixed to the variants above and the structural recipe cannot be changed by customers.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Availability'),
              subtitle: Text(_availability == Availability.available ? 'Available' : 'Sold Out'),
              value: _availability == Availability.available,
              activeColor: AppColors.ribbonRed,
              onChanged: (v) => setState(() => _availability = v ? Availability.available : Availability.soldOut),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visibility'),
              subtitle: Text(_visibility == ProductVisibility.published ? 'Published (visible in customer menu)' : 'Hidden'),
              value: _visibility == ProductVisibility.published,
              activeColor: AppColors.ribbonRed,
              onChanged: (v) => setState(() => _visibility = v ? ProductVisibility.published : ProductVisibility.hidden),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(onPressed: _save, child: Text(_isEdit ? 'Save Changes' : 'Save Product'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _variantEditor(int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(controller: _variants[i].name, decoration: const InputDecoration(labelText: 'Size / Variant name')),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _variants[i].price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '+₱'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
            onPressed: _variants.length <= 1 ? null : () => setState(() => _variants.removeAt(i)),
          ),
        ],
      ),
    );
  }

  Widget _modularOptionEditor(int i) {
    final option = _modularOptions[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: TextFormField(controller: option.name, decoration: const InputDecoration(labelText: 'Option name (e.g. Flavor)'))),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () => setState(() => _modularOptions.removeAt(i)),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Required'),
            value: option.required,
            onChanged: (v) => setState(() => option.required = v),
          ),
          Text('Choices', style: Theme.of(context).textTheme.bodyMedium),
          for (int j = 0; j < option.choices.length; j++)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(flex: 2, child: TextFormField(controller: option.choices[j].label, decoration: const InputDecoration(labelText: 'Choice label'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: option.choices[j].price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '+₱'))),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.danger),
                    onPressed: option.choices.length <= 1 ? null : () => setState(() => option.choices.removeAt(j)),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: () => setState(() => option.choices.add(_ChoiceRow())),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Choice'),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final fallbackIcon = _fallbackIconFor(_category);

    final variants = _variants
        .where((v) => v.name.text.trim().isNotEmpty)
        .map((v) => ProductVariant(name: v.name.text.trim(), priceDelta: double.tryParse(v.price.text) ?? 0))
        .toList();

    final modularOptions = _level == CustomizationLevel.modular
        ? _modularOptions
            .where((o) => o.name.text.trim().isNotEmpty)
            .map((o) => ModularOption(
                  name: o.name.text.trim(),
                  required: o.required,
                  choices: o.choices
                      .where((c) => c.label.text.trim().isNotEmpty)
                      .map((c) => ModularChoice(label: c.label.text.trim(), priceDelta: double.tryParse(c.price.text) ?? 0))
                      .toList(),
                ))
            .where((o) => o.choices.isNotEmpty)
            .toList()
        : <ModularOption>[];

    final product = Product(
      id: _existing?.id ?? appState.nextProductId(),
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      icon: fallbackIcon.icon,
      color: fallbackIcon.color,
      imageBytes: _imageBytes,
      imageUrl: _imageUrl,
      basePrice: double.parse(_priceController.text),
      variants: variants,
      customizationLevel: _level,
      modularOptions: modularOptions,
      bespokeAllowReferenceImage: _bespokeAllowImage,
      bespokeAllowMessage: _bespokeAllowMessage,
      availability: _availability,
      visibility: _visibility,
      featured: _existing?.featured ?? false,
    );

    if (_isEdit) {
      appState.editProduct(product);
      showSuccessSnack(context, 'Product updated.');
    } else {
      appState.addProduct(product);
      showSuccessSnack(context, 'Product added to catalog.');
    }
    Navigator.of(context).pop();
  }
}

class _PhotoActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PhotoActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}