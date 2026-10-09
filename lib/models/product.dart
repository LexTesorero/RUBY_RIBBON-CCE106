import 'dart:typed_data';
import 'package:flutter/material.dart';

enum ProductCategory { cakes, pastries, breads }

extension ProductCategoryX on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.cakes:
        return 'Cakes';
      case ProductCategory.pastries:
        return 'Pastries';
      case ProductCategory.breads:
        return 'Breads';
    }
  }
}

enum CustomizationLevel { standard, modular, bespoke }

extension CustomizationLevelX on CustomizationLevel {
  String get label {
    switch (this) {
      case CustomizationLevel.standard:
        return 'Standard';
      case CustomizationLevel.modular:
        return 'Modular';
      case CustomizationLevel.bespoke:
        return 'Bespoke';
    }
  }
}

enum Availability { available, soldOut }

enum ProductVisibility { published, hidden }

class ProductVariant {
  final String name;
  final double priceDelta;
  const ProductVariant({required this.name, this.priceDelta = 0});
}

class ModularChoice {
  final String label;
  final double priceDelta;
  const ModularChoice({required this.label, this.priceDelta = 0});
}

class ModularOption {
  final String name;
  final bool required;
  final List<ModularChoice> choices;
  const ModularOption({required this.name, required this.choices, this.required = true});
}

class Product {
  final String id;
  final String name;
  final String description;
  final ProductCategory category;
  final IconData icon;
  final Color color;

  /// A real photo picked from the device (gallery/camera), stored as bytes so
  /// it works the same way on mobile and web without needing a file path.
  /// When null, [ProductThumb] falls back to the [icon]/[color] tile.
  final Uint8List? imageBytes;
  final String? imageUrl;

  final double basePrice;
  final List<ProductVariant> variants;
  final CustomizationLevel customizationLevel;
  final List<ModularOption> modularOptions;
  final bool bespokeAllowReferenceImage;
  final bool bespokeAllowMessage;
  final Availability availability;
  final ProductVisibility visibility;
  final bool featured;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    this.imageBytes,
    this.imageUrl,
    required this.basePrice,
    this.variants = const [],
    this.customizationLevel = CustomizationLevel.standard,
    this.modularOptions = const [],
    this.bespokeAllowReferenceImage = true,
    this.bespokeAllowMessage = true,
    this.availability = Availability.available,
    this.visibility = ProductVisibility.published,
    this.featured = false,
  });

  Product copyWith({
    String? name,
    String? description,
    ProductCategory? category,
    IconData? icon,
    Color? color,
    Uint8List? imageBytes,
    String? imageUrl,
    double? basePrice,
    List<ProductVariant>? variants,
    CustomizationLevel? customizationLevel,
    List<ModularOption>? modularOptions,
    bool? bespokeAllowReferenceImage,
    bool? bespokeAllowMessage,
    Availability? availability,
    ProductVisibility? visibility,
    bool? featured,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      imageBytes: imageBytes ?? this.imageBytes,
      imageUrl: imageUrl ?? this.imageUrl,
      basePrice: basePrice ?? this.basePrice,
      variants: variants ?? this.variants,
      customizationLevel: customizationLevel ?? this.customizationLevel,
      modularOptions: modularOptions ?? this.modularOptions,
      bespokeAllowReferenceImage: bespokeAllowReferenceImage ?? this.bespokeAllowReferenceImage,
      bespokeAllowMessage: bespokeAllowMessage ?? this.bespokeAllowMessage,
      availability: availability ?? this.availability,
      visibility: visibility ?? this.visibility,
      featured: featured ?? this.featured,
    );
  }
}