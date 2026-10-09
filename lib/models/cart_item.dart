import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'product.dart';

class SelectedModularChoice {
  final String optionName;
  final String choiceLabel;
  final double priceDelta;
  const SelectedModularChoice({required this.optionName, required this.choiceLabel, required this.priceDelta});
}

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final IconData productIcon;
  final Color productColor;
  final Uint8List? productImageBytes;
  final String? productImageUrl;
  final CustomizationLevel customizationLevel;

  final String? variantName;
  final double variantPriceDelta;

  final List<SelectedModularChoice> selectedModularChoices;

  final String? bespokeInstructions;
  final String? bespokeMessage;
  final String? bespokeReferenceImageName;
  final String? bespokeReferenceUrl;

  final double unitBasePrice;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productIcon,
    required this.productColor,
    this.productImageBytes,
    this.productImageUrl,
    required this.customizationLevel,
    required this.unitBasePrice,
    this.variantName,
    this.variantPriceDelta = 0,
    this.selectedModularChoices = const [],
    this.bespokeInstructions,
    this.bespokeMessage,
    this.bespokeReferenceImageName,
    this.bespokeReferenceUrl,
    this.quantity = 1,
  });

  double get modularAddOnsTotal => selectedModularChoices.fold(0.0, (sum, c) => sum + c.priceDelta);

  double get unitPrice => unitBasePrice + variantPriceDelta + modularAddOnsTotal;

  double get lineTotal => unitPrice * quantity;

  String get customizationSummary {
    final parts = <String>[];
    if (variantName != null) parts.add(variantName!);
    for (final c in selectedModularChoices) {
      parts.add('${c.optionName}: ${c.choiceLabel}');
    }
    if (customizationLevel == CustomizationLevel.bespoke) {
      if (bespokeMessage != null && bespokeMessage!.isNotEmpty) {
        parts.add('Message: "$bespokeMessage"');
      }
      if (bespokeInstructions != null && bespokeInstructions!.isNotEmpty) {
        parts.add('Design notes provided');
      }
      if (bespokeReferenceImageName != null) {
        parts.add('Reference image attached');
      }
    }
    return parts.isEmpty ? 'No customization' : parts.join(' • ');
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      productId: productId,
      productName: productName,
      productIcon: productIcon,
      productColor: productColor,
      productImageBytes: productImageBytes,
      productImageUrl: productImageUrl,
      customizationLevel: customizationLevel,
      unitBasePrice: unitBasePrice,
      variantName: variantName,
      variantPriceDelta: variantPriceDelta,
      selectedModularChoices: selectedModularChoices,
      bespokeInstructions: bespokeInstructions,
      bespokeMessage: bespokeMessage,
      bespokeReferenceImageName: bespokeReferenceImageName,
      bespokeReferenceUrl: bespokeReferenceUrl,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() => {
    'product_id': productId,
    'product_name': productName,
    'image_url': productImageUrl,
    'customization_level': customizationLevel.name,
    'unit_base_price': unitBasePrice,
    'variant_name': variantName,
    'variant_price_delta': variantPriceDelta,
    'modular_choices': [
      for (final c in selectedModularChoices)
        {'option_name': c.optionName, 'choice_label': c.choiceLabel, 'price_delta': c.priceDelta},
    ],
    'bespoke_instructions': bespokeInstructions,
    'bespoke_message': bespokeMessage,
    'bespoke_reference_name': bespokeReferenceImageName,
    'bespoke_reference_url': bespokeReferenceUrl,
    'quantity': quantity,
  };
}