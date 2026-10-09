import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'cart_item.dart';

enum FulfillmentMethod { pickup, delivery }

extension FulfillmentMethodX on FulfillmentMethod {
  String get label => this == FulfillmentMethod.pickup ? 'Pickup' : 'Delivery';
}

enum PaymentStatus { pending, paid, failed, refunded }

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.pending:
        return const Color(0xFFCB8A00);
      case PaymentStatus.paid:
        return const Color(0xFF2E8B57);
      case PaymentStatus.failed:
        return const Color(0xFFC1272D);
      case PaymentStatus.refunded:
        return const Color(0xFF6F5A52);
    }
  }
}

enum OrderStatus { received, baking, ready, completed, cancelled }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.received:
        return 'Received';
      case OrderStatus.baking:
        return 'Baking & Decorating';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.received:
        return 0;
      case OrderStatus.baking:
        return 1;
      case OrderStatus.ready:
        return 2;
      case OrderStatus.completed:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }
}

/// A frozen copy of a cart item at the time the order was placed, so later
/// catalog edits never change historical order details.
class OrderItem {
  final String productName;
  final IconData productIcon;
  final Color productColor;
  final Uint8List? productImageBytes;
  final String? productImageUrl;
  final String? referenceImageUrl;
  final String customizationSummary;
  final double unitPrice;
  final int quantity;

  /// 'standard' | 'modular' | 'bespoke' (the product's customization level
  /// when the order was placed).
  final String customizationLevel;

  const OrderItem({
    required this.productName,
    required this.productIcon,
    required this.productColor,
    this.productImageBytes,
    this.productImageUrl,
    this.referenceImageUrl,
    required this.customizationSummary,
    required this.unitPrice,
    required this.quantity,
    this.customizationLevel = 'standard',
  });

  double get lineTotal => unitPrice * quantity;

  /// Modular or bespoke.
  bool get isCustomized => customizationLevel != 'standard';

  factory OrderItem.fromCartItem(CartItem item, {String customizationLevel = 'standard'}) => OrderItem(
        productName: item.productName,
        productIcon: item.productIcon,
        productColor: item.productColor,
        productImageBytes: item.productImageBytes,
        productImageUrl: item.productImageUrl,
        referenceImageUrl: item.bespokeReferenceUrl,
        customizationSummary: item.customizationSummary,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        customizationLevel: customizationLevel,
      );
}

class Order {
  final String id; // order number, e.g. RR-1001
  final String customerId;
  final String customerName;
  final String customerContact;
  final List<OrderItem> items;
  final double subtotal;
  final double total;
  final FulfillmentMethod fulfillmentMethod;
  final DateTime scheduledDateTime;
  final String? deliveryAddress;
  final String? paymentMethodLabel;
  PaymentStatus paymentStatus;
  final String? transactionRef;
  OrderStatus orderStatus;
  String? cancellationReason;
  final DateTime createdAt;

  /// True for immediate pickup/delivery (no scheduled date).
  final bool isImmediate;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerContact,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.fulfillmentMethod,
    required this.scheduledDateTime,
    this.deliveryAddress,
    this.paymentMethodLabel,
    this.paymentStatus = PaymentStatus.pending,
    this.transactionRef,
    this.orderStatus = OrderStatus.received,
    this.cancellationReason,
    required this.createdAt,
    this.isImmediate = false,
  });

  /// Staff: can cancel any order that is not yet completed/cancelled
  /// (the original rule is kept: only while "received").
  bool get isCancellable => orderStatus == OrderStatus.received;

  bool get hasCustomizedItems => items.any((i) => i.isCustomized);
  bool get hasModularItems => items.any((i) => i.customizationLevel == 'modular');
  bool get hasBespokeItems => items.any((i) => i.customizationLevel == 'bespoke');

  /// Customer: only before baking/decorating starts (standard, modular and
  /// bespoke alike). For bespoke, the baker accepting = status leaves "received".
  bool get isCancellableByCustomer => orderStatus == OrderStatus.received;
}