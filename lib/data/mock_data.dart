import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/people.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../theme/app_theme.dart';

class MockData {
  static List<Product> products() => [
        Product(
          id: 'P001',
          name: 'Dedication Cake',
          description:
              'Our signature soft chiffon cake layered with creamy custard filling, finished with buttercream icing. A Ruby Ribbon classic since day one.',
          category: ProductCategory.cakes,
          icon: Icons.cake_rounded,
          color: AppColors.ribbonRed,
          basePrice: 495,
          featured: true,
          customizationLevel: CustomizationLevel.modular,
          variants: const [
            ProductVariant(name: 'Regular (7")', priceDelta: 0),
            ProductVariant(name: 'Large (9")', priceDelta: 250),
          ],
          modularOptions: const [
            ModularOption(name: 'Filling', choices: [
              ModularChoice(label: 'Custard'),
              ModularChoice(label: 'Mango Bavarian', priceDelta: 40),
              ModularChoice(label: 'Chocolate Mousse', priceDelta: 40),
            ]),
            ModularOption(name: 'Frosting', choices: [
              ModularChoice(label: 'Buttercream'),
              ModularChoice(label: 'Whipped Cream', priceDelta: 30),
            ]),
            ModularOption(name: 'Toppings', required: false, choices: [
              ModularChoice(label: 'None'),
              ModularChoice(label: 'Fresh Fruits', priceDelta: 60),
              ModularChoice(label: 'Chocolate Shavings', priceDelta: 35),
            ]),
          ],
        ),
        Product(
          id: 'P002',
          name: 'Custom Celebration Cake',
          description:
              'A made-to-order cake designed around your theme — perfect for birthdays, weddings, and milestones. Share your design idea and our decorators will bring it to life.',
          category: ProductCategory.cakes,
          icon: Icons.cake,
          color: AppColors.gold,
          basePrice: 1250,
          featured: true,
          customizationLevel: CustomizationLevel.bespoke,
          variants: const [
            ProductVariant(name: 'Round (8")', priceDelta: 0),
            ProductVariant(name: 'Round (10")', priceDelta: 400),
            ProductVariant(name: 'Two-Tier', priceDelta: 900),
          ],
        ),
        Product(
          id: 'P003',
          name: 'Classic Mamon',
          description: 'Fluffy, buttery mamon topped with a generous layer of butter and sugar.',
          category: ProductCategory.pastries,
          icon: Icons.bakery_dining,
          color: AppColors.ribbonRed,
          basePrice: 25,
          customizationLevel: CustomizationLevel.standard,
          variants: const [
            ProductVariant(name: 'Single'),
            ProductVariant(name: 'Box of 6', priceDelta: 115),
            ProductVariant(name: 'Box of 12', priceDelta: 220),
          ],
        ),
        Product(
          id: 'P004',
          name: 'Ensaymada Supreme',
          description: 'Soft brioche swirl loaded with butter, sugar, and grated cheese on top.',
          category: ProductCategory.pastries,
          icon: Icons.bakery_dining,
          color: AppColors.gold,
          basePrice: 55,
          featured: true,
          customizationLevel: CustomizationLevel.modular,
          modularOptions: const [
            ModularOption(name: 'Topping', choices: [
              ModularChoice(label: 'Classic Cheese'),
              ModularChoice(label: 'Extra Cheese', priceDelta: 15),
              ModularChoice(label: 'Ube Cheese', priceDelta: 20),
            ]),
          ],
        ),
        Product(
          id: 'P005',
          name: 'Chicken Empanada',
          description: 'Flaky hand-pie pastry filled with savory chicken, potatoes, and carrots.',
          category: ProductCategory.pastries,
          icon: Icons.lunch_dining,
          color: AppColors.chocolate,
          basePrice: 45,
          customizationLevel: CustomizationLevel.standard,
          variants: const [ProductVariant(name: 'Single'), ProductVariant(name: 'Pack of 5', priceDelta: 180)],
        ),
        Product(
          id: 'P006',
          name: 'Sliced Wheat Loaf',
          description: 'Soft everyday wheat bread loaf, sliced and ready for sandwiches or toast.',
          category: ProductCategory.breads,
          icon: Icons.breakfast_dining,
          color: AppColors.chocolateSoft,
          basePrice: 85,
          customizationLevel: CustomizationLevel.standard,
          variants: const [ProductVariant(name: 'Regular'), ProductVariant(name: 'Family Size', priceDelta: 45)],
        ),
        Product(
          id: 'P007',
          name: 'Pan de Ruby',
          description: 'Soft dinner rolls with a golden-brown crust, best paired with butter or cheese spread.',
          category: ProductCategory.breads,
          icon: Icons.breakfast_dining,
          color: AppColors.ribbonRed,
          basePrice: 90,
          featured: true,
          customizationLevel: CustomizationLevel.standard,
          variants: const [ProductVariant(name: 'Pack of 6'), ProductVariant(name: 'Pack of 12', priceDelta: 80)],
        ),
        Product(
          id: 'P008',
          name: 'Cheese Loaf Bread',
          description: 'Rich, buttery loaf swirled with real cheese in every slice.',
          category: ProductCategory.breads,
          icon: Icons.bakery_dining,
          color: AppColors.gold,
          basePrice: 120,
          customizationLevel: CustomizationLevel.standard,
          availability: Availability.soldOut,
          variants: const [ProductVariant(name: 'Regular')],
        ),
        Product(
          id: 'P009',
          name: 'Ube Cheese Pandesal',
          description: 'A twist on the Filipino breakfast staple, filled with ube halaya and cheese.',
          category: ProductCategory.breads,
          icon: Icons.breakfast_dining,
          color: AppColors.chocolate,
          basePrice: 95,
          customizationLevel: CustomizationLevel.standard,
          variants: const [ProductVariant(name: 'Pack of 6'), ProductVariant(name: 'Pack of 12', priceDelta: 85)],
        ),
      ];

  static List<Customer> customers() => [
        Customer(
          id: 'C001',
          name: 'Lex Tesorero',
          email: 'lex@gmail.com',
          password: '123456',
          contact: '09126518840',
          address: 'Indangan, Davao City',
        ),
      ];

  static List<StaffAccount> staff() => const [
        StaffAccount(id: 'S001', name: 'Aida Reyes', email: 'staff@rubyribbon.ph', password: 'staff123', role: StaffRole.manager),
        StaffAccount(id: 'S002', name: 'Boy Domingo', email: 'baker@rubyribbon.ph', password: 'baker123', role: StaffRole.staff),
      ];

  /// A few pre-seeded orders + payments so Order Management, Order History
  /// and the Analytics dashboard have something to show on first launch.
  static List<Order> seedOrders() {
    final now = DateTime.now();
    return [
      Order(
        id: 'RR-1001',
        customerId: 'C001',
        customerName: 'Maria Santos',
        customerContact: '0917 123 4567',
        items: [
          OrderItem(
            productName: 'Dedication Cake',
            productIcon: Icons.cake_rounded,
            productColor: AppColors.ribbonRed,
            customizationSummary: 'Regular (7") • Filling: Custard • Frosting: Buttercream',
            unitPrice: 495,
            quantity: 1,
          ),
        ],
        subtotal: 495,
        total: 495,
        fulfillmentMethod: FulfillmentMethod.pickup,
        scheduledDateTime: now.subtract(const Duration(days: 6)),
        paymentMethodLabel: 'GCash',
        paymentStatus: PaymentStatus.paid,
        transactionRef: 'GC-88213456',
        orderStatus: OrderStatus.completed,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Order(
        id: 'RR-1002',
        customerId: 'C001',
        customerName: 'Maria Santos',
        customerContact: '0917 123 4567',
        items: [
          OrderItem(
            productName: 'Ensaymada Supreme',
            productIcon: Icons.bakery_dining,
            productColor: AppColors.gold,
            customizationSummary: 'Topping: Ube Cheese',
            unitPrice: 75,
            quantity: 6,
          ),
        ],
        subtotal: 450,
        total: 450,
        fulfillmentMethod: FulfillmentMethod.delivery,
        deliveryAddress: 'Blk 4 Lot 12, Sampaguita St., Davao City',
        scheduledDateTime: now.subtract(const Duration(days: 3)),
        paymentMethodLabel: 'Maya',
        paymentStatus: PaymentStatus.paid,
        transactionRef: 'MY-22910873',
        orderStatus: OrderStatus.ready,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Order(
        id: 'RR-1003',
        customerId: 'C001',
        customerName: 'Maria Santos',
        customerContact: '0917 123 4567',
        items: [
          OrderItem(
            productName: 'Custom Celebration Cake',
            productIcon: Icons.cake,
            productColor: AppColors.gold,
            customizationSummary: 'Two-Tier • Message: "Happy 18th, Ella!"',
            unitPrice: 2150,
            quantity: 1,
          ),
        ],
        subtotal: 2150,
        total: 2150,
        fulfillmentMethod: FulfillmentMethod.pickup,
        scheduledDateTime: now.add(const Duration(days: 2)),
        paymentMethodLabel: 'QR Ph',
        paymentStatus: PaymentStatus.paid,
        transactionRef: 'QR-10938221',
        orderStatus: OrderStatus.baking,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Order(
        id: 'RR-1004',
        customerId: 'C001',
        customerName: 'Maria Santos',
        customerContact: '0917 123 4567',
        items: [
          OrderItem(
            productName: 'Pan de Ruby',
            productIcon: Icons.breakfast_dining,
            productColor: AppColors.ribbonRed,
            customizationSummary: 'Pack of 12',
            unitPrice: 170,
            quantity: 2,
          ),
        ],
        subtotal: 340,
        total: 340,
        fulfillmentMethod: FulfillmentMethod.pickup,
        scheduledDateTime: now.subtract(const Duration(hours: 5)),
        paymentMethodLabel: 'GCash',
        paymentStatus: PaymentStatus.paid,
        transactionRef: 'GC-77102345',
        orderStatus: OrderStatus.received,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      Order(
        id: 'RR-1005',
        customerId: 'C001',
        customerName: 'Maria Santos',
        customerContact: '0917 123 4567',
        items: [
          OrderItem(
            productName: 'Classic Mamon',
            productIcon: Icons.bakery_dining,
            productColor: AppColors.ribbonRed,
            customizationSummary: 'Box of 12',
            unitPrice: 245,
            quantity: 1,
          ),
        ],
        subtotal: 245,
        total: 245,
        fulfillmentMethod: FulfillmentMethod.delivery,
        deliveryAddress: 'Blk 4 Lot 12, Sampaguita St., Davao City',
        scheduledDateTime: now.subtract(const Duration(days: 10)),
        paymentMethodLabel: 'Maya',
        paymentStatus: PaymentStatus.refunded,
        transactionRef: 'MY-19938122',
        orderStatus: OrderStatus.cancelled,
        cancellationReason: 'Change of plans',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];
  }

  static List<PaymentRecord> seedPayments(List<Order> orders) {
    final list = <PaymentRecord>[];
    for (final o in orders) {
      if (o.transactionRef == null) continue;
      PaymentMethod method = PaymentMethod.gcash;
      if (o.paymentMethodLabel == 'Maya') method = PaymentMethod.maya;
      if (o.paymentMethodLabel == 'QR Ph') method = PaymentMethod.qrph;
      list.add(PaymentRecord(
        id: 'PAY-${o.id}',
        orderId: o.id,
        method: method,
        amount: o.total,
        transactionRef: o.transactionRef!,
        status: o.paymentStatus == PaymentStatus.paid || o.paymentStatus == PaymentStatus.refunded
            ? PaymentRecordStatus.paid
            : PaymentRecordStatus.pending,
        date: o.createdAt,
      ));
    }
    return list;
  }
}
