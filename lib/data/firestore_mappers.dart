import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../theme/app_theme.dart';

typedef Doc = DocumentSnapshot<Map<String, dynamic>>;

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

DateTime _date(Object? v) => v is Timestamp ? v.toDate() : DateTime.now();
double _num(Object? v) => (v as num?)?.toDouble() ?? 0;

IconData _icon(ProductCategory c) {
  switch (c) {
    case ProductCategory.cakes:
      return Icons.cake_rounded;
    case ProductCategory.pastries:
      return Icons.bakery_dining;
    case ProductCategory.breads:
      return Icons.breakfast_dining;
  }
}

Color _color(ProductCategory c) {
  switch (c) {
    case ProductCategory.cakes:
      return AppColors.ribbonRed;
    case ProductCategory.pastries:
      return AppColors.gold;
    case ProductCategory.breads:
      return AppColors.chocolate;
  }
}

Product productFromDoc(Doc d) {
  final m = d.data() ?? {};
  final category = _enum(ProductCategory.values, m['category'], ProductCategory.cakes);
  return Product(
    id: d.id,
    name: m['name'] ?? '',
    description: m['description'] ?? '',
    category: category,
    icon: _icon(category),
    color: _color(category),
    imageUrl: m['image_url'],
    basePrice: _num(m['base_price']),
    variants: [
      for (final v in (m['variants'] as List? ?? const []))
        ProductVariant(name: v['name'] ?? '', priceDelta: _num(v['price_delta'])),
    ],
    customizationLevel: _enum(CustomizationLevel.values, m['customization_level'], CustomizationLevel.standard),
    modularOptions: [
      for (final o in (m['modular_options'] as List? ?? const []))
        ModularOption(
          name: o['name'] ?? '',
          required: o['required'] ?? true,
          choices: [
            for (final c in (o['choices'] as List? ?? const []))
              ModularChoice(label: c['label'] ?? '', priceDelta: _num(c['price_delta'])),
          ],
        ),
    ],
    bespokeAllowReferenceImage: m['bespoke_allow_reference_image'] ?? true,
    bespokeAllowMessage: m['bespoke_allow_message'] ?? true,
    availability: _enum(Availability.values, m['availability'], Availability.available),
    visibility: _enum(ProductVisibility.values, m['visibility'], ProductVisibility.published),
    featured: m['featured'] ?? false,
  );
}

Order orderFromDoc(Doc d) {
  final m = d.data() ?? {};
  return Order(
    id: d.id, // the order number is also the Firestore document id
    customerId: m['customer_id'] ?? '',
    customerName: m['customer_name'] ?? '',
    customerContact: m['customer_contact'] ?? '',
    items: [
      for (final i in (m['items'] as List? ?? const []))
        OrderItem(
          productName: i['product_name'] ?? '',
          productIcon: Icons.bakery_dining_rounded,
          productColor: AppColors.ribbonRed,
          productImageUrl: i['image_url'],
          referenceImageUrl: i['reference_url'],
          customizationSummary: i['customization_summary'] ?? '',
          customizationLevel: (m['customization_level'] ?? 'standard') as String,
          unitPrice: _num(i['unit_price']),
          quantity: (i['quantity'] as num?)?.toInt() ?? 1,
        ),
    ],
    subtotal: _num(m['subtotal']),
    total: _num(m['total']),
    fulfillmentMethod: _enum(FulfillmentMethod.values, m['fulfillment_method'], FulfillmentMethod.pickup),
    scheduledDateTime: _date(m['scheduled_at']),
    deliveryAddress: m['delivery_address'],
    paymentMethodLabel: m['payment_method'],
    paymentStatus: _enum(PaymentStatus.values, m['payment_status'], PaymentStatus.pending),
    transactionRef: m['transaction_ref'],
    orderStatus: _enum(OrderStatus.values, m['status'], OrderStatus.received),
    cancellationReason: m['cancellation_reason'],
    createdAt: _date(m['created_at']),
  );
}

PaymentRecord paymentFromDoc(Doc d) {
  final m = d.data() ?? {};
  return PaymentRecord(
    id: d.id,
    orderId: m['order_id'] ?? '',
    method: PaymentMethod.values.firstWhere((x) => x.label == m['method'], orElse: () => PaymentMethod.gcash),
    amount: _num(m['amount']),
    transactionRef: m['reference'] ?? '',
    status: _enum(PaymentRecordStatus.values, m['status'], PaymentRecordStatus.paid),
    date: _date(m['paid_at']),
  );
}

CartItem cartItemFromDoc(Doc d, {ProductCategory? category}) {
  final m = d.data() ?? {};
  final c = category ?? ProductCategory.cakes;
  return CartItem(
    id: d.id, // the Firestore document id
    productId: m['product_id'] ?? '',
    productName: m['product_name'] ?? '',
    productIcon: _icon(c),
    productColor: _color(c),
    productImageUrl: m['image_url'],
    customizationLevel: _enum(CustomizationLevel.values, m['customization_level'], CustomizationLevel.standard),
    unitBasePrice: _num(m['unit_base_price']),
    variantName: m['variant_name'],
    variantPriceDelta: _num(m['variant_price_delta']),
    selectedModularChoices: [
      for (final x in (m['modular_choices'] as List? ?? const []))
        SelectedModularChoice(
          optionName: x['option_name'] ?? '',
          choiceLabel: x['choice_label'] ?? '',
          priceDelta: _num(x['price_delta']),
        ),
    ],
    bespokeInstructions: m['bespoke_instructions'],
    bespokeMessage: m['bespoke_message'],
    bespokeReferenceImageName: m['bespoke_reference_name'],
    bespokeReferenceUrl: m['bespoke_reference_url'],
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
  );
}