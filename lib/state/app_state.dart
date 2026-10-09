import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import '../data/firestore_mappers.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../models/people.dart';
import '../models/product.dart';
import '../services/customer_auth_service.dart';
import '../services/customer_crud_service.dart';
import '../services/staff_auth_service.dart';
import '../services/staff_crud_service.dart';
import '../utils/order_rules.dart';

enum UserRole { customer, staff }

enum AuthStatus { initializing, signedOut, loadingProfile, unverified, customer, staff }

class AnalyticsResult {
  final double totalSales;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final Map<PaymentStatus, int> paymentStatusSummary;
  final Map<String, double> salesByProduct;
  final Map<String, int> unitsByProduct;
  final Map<ProductCategory, double> salesByCategory;
  final Map<String, double> salesOverTime; // key: yyyy-mm-dd
  final Map<PaymentMethod, List<num>> paymentMethodBreakdown; // [count, amount]

  AnalyticsResult({
    required this.totalSales,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.paymentStatusSummary,
    required this.salesByProduct,
    required this.unitsByProduct,
    required this.salesByCategory,
    required this.salesOverTime,
    required this.paymentMethodBreakdown,
  });
}

class AppState extends ChangeNotifier {
  AppState() {
    _authSub = _auth.userChanges().listen(_onAuthChanged);
  }

  final _rand = Random();

  UserRole? role;

  // ---- Session (Firebase Auth + Firestore) ----
  final CustomerAuthService customerAuth = CustomerAuthService();
  final StaffAuthService staffAuth = StaffAuthService();
  final CustomerCrudService _customerCrud = CustomerCrudService();
  final StaffCrudService _staffCrud = StaffCrudService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthStatus authStatus = AuthStatus.initializing;
  Customer? currentCustomer;
  StaffAccount? currentStaff;
  void Function(String message)? onError;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  final List<StreamSubscription<dynamic>> _dataSubs = [];
  String? _sessionUid;
  bool _sessionVerified = false;

  bool get isLoggedIn => currentCustomer != null;

  // Email/password accounts must verify their email; Google accounts already are.
  bool _isVerified(User u) => u.emailVerified || !u.providerData.any((p) => p.providerId == 'password');

  void _onAuthChanged(User? user) {
    if (user != null && user.uid == _sessionUid && _isVerified(user) == _sessionVerified) return;
    // Keep the cart when a guest logs in or verification changes;
    // clear it on sign-out or when a different account signs in.
    _stopSession();

    if (user == null) {
      authStatus = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    _sessionUid = user.uid;
    _sessionVerified = _isVerified(user);
    authStatus = AuthStatus.loadingProfile;
    notifyListeners();

    _profileSub = _db.collection('users').doc(user.uid).snapshots().listen(
          (snap) => _onProfile(user, snap),
          onError: _onDataError,
        );
  }

  void _onProfile(User user, DocumentSnapshot<Map<String, dynamic>> snap) {
    final m = snap.data();
    if (m == null) return; // profile document is still being created

    if (m['role'] == 'staff') {
      role = UserRole.staff;
      currentCustomer = null;
      currentStaff = StaffAccount(
        id: user.uid,
        name: m['name'] ?? user.displayName ?? 'Staff',
        email: m['email'] ?? user.email ?? '',
        password: '',
      );
      if (authStatus != AuthStatus.staff) {
        authStatus = AuthStatus.staff;
        _bindStaffData();
      }
    } else if (m['role'] == 'customer') {
      if (!_sessionVerified) {
        authStatus = AuthStatus.unverified;
        notifyListeners();
        return;
      }
      role = UserRole.customer;
      currentStaff = null;
      currentCustomer = Customer(
        id: user.uid,
        name: m['name'] ?? '',
        email: m['email'] ?? user.email ?? '',
        password: '',
        contact: m['contact'] ?? '',
        address: m['address'] ?? '',
      );
      if (authStatus != AuthStatus.customer) {
        authStatus = AuthStatus.customer;
        _bindCustomerData();
      }
    } else {
      signOut(); // unknown role: never let the account in
      return;
    }
    notifyListeners();
  }

  // Customers only receive published products and their OWN orders.
  void _bindCustomerData() {
    _dataSubs.addAll([
      _customerCrud.getMenu().listen((docs) {
        _products = docs.map(productFromDoc).toList();
        notifyListeners();
      }, onError: _onDataError),
      _customerCrud.getMyOrders().listen((docs) {
        _orders = _sortedOrders(docs.map(orderFromDoc).toList());
        notifyListeners();
      }, onError: _onDataError),
      _customerCrud.getCart().listen((docs) {
        _cartDocs = List<Doc>.from(docs);
        notifyListeners();
      }, onError: _onDataError),
    ]);

    // Items added while signed out move into the account's cart.
    if (_guestCart.isNotEmpty) {
      final pending = [..._guestCart];
      _guestCart.clear();
      for (final item in pending) {
        _run(() => _customerCrud.addToCart(item.toMap()));
      }
    }
  }

  // Staff receive every product, order and payment.
  void _bindStaffData() {
    _dataSubs.addAll([
      _staffCrud.getProducts().listen((docs) {
        _products = docs.map(productFromDoc).toList();
        notifyListeners();
      }, onError: _onDataError),
      _staffCrud.getOrders().listen((docs) {
        _orders = _sortedOrders(docs.map(orderFromDoc).toList());
        notifyListeners();
      }, onError: _onDataError),
      _staffCrud.getPayments().listen((docs) {
        final list = docs.map(paymentFromDoc).toList();
        list.sort((PaymentRecord a, PaymentRecord b) => a.date.compareTo(b.date));
        _payments = list;
        notifyListeners();
      }, onError: _onDataError),
    ]);
  }

  /// Oldest first (screens reverse it when they want newest first).
  List<Order> _sortedOrders(List<Order> list) {
    list.sort((Order a, Order b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  void _stopSession() {
    _profileSub?.cancel();
    _profileSub = null;
    for (final s in _dataSubs) {
      s.cancel();
    }
    _dataSubs.clear();
    _sessionUid = null;
    _sessionVerified = false;
    role = null;
    currentCustomer = null;
    currentStaff = null;
    _products = [];
    _orders = [];
    _payments = [];
    _cartDocs = [];
    draftFulfillment = FulfillmentMethod.pickup;
    draftSchedule = null;
    draftAddress = '';
    draftContactName = '';
    draftContactNumber = '';
    draftPaymentMethod = null;
    draftImmediate = true;
  }

  Future<void> recheckVerification() async {
    if (await customerAuth.checkVerified()) _onAuthChanged(_auth.currentUser);
  }

  Future<void> signOut() => customerAuth.signout(); // signs out Google + Firebase
  void logout() => signOut();
  void staffLogout() => signOut();

  void updateProfile({String? name, String? contact, String? address}) {
    final c = currentCustomer;
    if (c == null) return;
    if (name != null) c.name = name;
    if (contact != null) c.contact = contact;
    if (address != null) c.address = address;
    notifyListeners();
    _run(() => customerAuth.updateProfile(name: c.name, contact: c.contact, address: c.address));
  }

  void _onDataError(Object e) => onError?.call('Could not load data. Check your connection.');

  Future<void> _run(Future<void> Function() job) async {
    try {
      await job();
    } on StateError catch (e) {
      onError?.call(e.message);
    } on FirebaseException catch (e) {
      onError?.call(e.code == 'permission-denied'
          ? 'You do not have permission to do that.'
          : 'Could not save changes. Check your connection and try again.');
    } catch (_) {
      onError?.call('Something went wrong. Please try again.');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    for (final s in _dataSubs) {
      s.cancel();
    }
    super.dispose();
  }

  // ---- Catalog ----
  List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);

  List<Product> visibleForCustomer({ProductCategory? category, String query = ''}) {
    return _products.where((p) {
      if (p.visibility != ProductVisibility.published) return false;
      if (category != null && p.category != category) return false;
      if (query.trim().isNotEmpty && !p.name.toLowerCase().contains(query.trim().toLowerCase())) return false;
      return true;
    }).toList();
  }

  List<Product> get featuredProducts =>
      _products.where((p) => p.featured && p.visibility == ProductVisibility.published).toList();

  void addProduct(Product p) => _run(() => _saveProduct(p, isNew: true));
  void editProduct(Product p) => _run(() => _saveProduct(p, isNew: false));
  void archiveProduct(String id) => _run(() => _staffCrud.archiveProduct(id));

  void toggleAvailability(String id) {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final wasSoldOut = _products[idx].availability == Availability.soldOut;
    _run(() => _staffCrud.setAvailability(id, wasSoldOut));
  }

  Future<void> _saveProduct(Product p, {required bool isNew}) => _staffCrud.saveProduct(
        id: isNew ? null : p.id,
        name: p.name,
        description: p.description,
        category: p.category.name,
        basePrice: p.basePrice,
        variants: [for (final v in p.variants) {'name': v.name, 'price_delta': v.priceDelta}],
        customizationLevel: p.customizationLevel.name,
        modularOptions: [
          for (final o in p.modularOptions)
            {
              'name': o.name,
              'required': o.required,
              'choices': [for (final c in o.choices) {'label': c.label, 'price_delta': c.priceDelta}],
            },
        ],
        bespokeAllowReferenceImage: p.bespokeAllowReferenceImage,
        bespokeAllowMessage: p.bespokeAllowMessage,
        availability: p.availability.name,
        visibility: p.visibility.name,
        featured: p.featured,
        imageUrl: p.imageUrl,
      );

  /// Ignored for new products (Firestore assigns the id); kept so the form compiles unchanged.
  String nextProductId() => 'P${(_products.length + 1).toString().padLeft(3, '0')}-${_rand.nextInt(900) + 100}';

  // ---- Cart (stored in Firestore: users/{uid}/cart) ----
  List<Doc> _cartDocs = [];
  final List<CartItem> _guestCart = []; // items added before login; uploaded at login

  List<CartItem> get cart {
    if (currentCustomer == null) return List.unmodifiable(_guestCart);
    return List.unmodifiable([
      for (final d in _cartDocs)
        cartItemFromDoc(d, category: _categoryOf(d.data()?['product_id'] as String?)),
    ]);
  }

  ProductCategory? _categoryOf(String? productId) {
    for (final p in _products) {
      if (p.id == productId) return p.category;
    }
    return null;
  }

  /// 'standard' | 'modular' | 'bespoke' for a cart item, taken from its product.
  /// If the product can't be found, an item with a reference image is treated
  /// as bespoke, otherwise standard.
  String _levelOf(CartItem item) {
    for (final p in _products) {
      if (p.name == item.productName) return p.customizationLevel.name;
    }
    return item.bespokeReferenceUrl != null ? 'bespoke' : 'standard';
  }

  bool get cartHasModular => cart.any((CartItem c) => _levelOf(c) == 'modular');
  bool get cartHasBespoke => cart.any((CartItem c) => _levelOf(c) == 'bespoke');

  int get cartItemCount => cart.fold<int>(0, (int sum, CartItem c) => sum + c.quantity);

  double get cartSubtotal => cart.fold<double>(0.0, (double sum, CartItem c) => sum + c.lineTotal);

  void addToCart(CartItem item) {
    if (currentCustomer == null) {
      _guestCart.add(item);
      notifyListeners();
      return;
    }
    _run(() => _customerCrud.addToCart(item.toMap()));
  }

  void updateCartQuantity(String cartItemId, int quantity) {
    if (quantity < 1) return;
    if (currentCustomer == null) {
      final idx = _guestCart.indexWhere((c) => c.id == cartItemId);
      if (idx != -1) {
        _guestCart[idx] = _guestCart[idx].copyWith(quantity: quantity);
        notifyListeners();
      }
      return;
    }
    _run(() => _customerCrud.updateCartQuantity(cartItemId, quantity));
  }

  void removeFromCart(String cartItemId) {
    if (currentCustomer == null) {
      _guestCart.removeWhere((c) => c.id == cartItemId);
      notifyListeners();
      return;
    }
    _run(() => _customerCrud.removeCartItem(cartItemId));
  }

  void clearCart() {
    if (currentCustomer == null) {
      _guestCart.clear();
      notifyListeners();
      return;
    }
    _run(_customerCrud.clearCart);
  }

  String nextCartItemId() => 'CART-${DateTime.now().microsecondsSinceEpoch}';

  // ---- Checkout draft (in-memory only, cleared after order placed) ----
  FulfillmentMethod draftFulfillment = FulfillmentMethod.pickup;
  DateTime? draftSchedule;
  String draftAddress = '';
  String draftContactName = '';
  String draftContactNumber = '';
  PaymentMethod? draftPaymentMethod;
  bool draftImmediate = true; // immediate pickup/delivery vs scheduled

  void primeCheckoutDraftFromProfile() {
    draftContactName = currentCustomer?.name ?? '';
    draftContactNumber = currentCustomer?.contact ?? '';
    draftAddress = currentCustomer?.address ?? '';
  }

  // ---- Orders & Payments ----
  List<Order> _orders = [];
  List<PaymentRecord> _payments = [];

  List<Order> get orders => List.unmodifiable(_orders);
  List<PaymentRecord> get payments => List.unmodifiable(_payments);

  List<Order> ordersForCurrentCustomer() {
    final customerId = currentCustomer?.id;
    if (customerId == null) return [];
    final mine = _orders.where((Order o) => o.customerId == customerId).toList();
    return mine.reversed.toList(); // newest first
  }

  Order? orderById(String id) {
    for (final Order o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Places the order.
  ///  - GCash / Maya / QR Ph: called by the Payment screen once the (mock)
  ///    payment is approved -> saved as Paid.
  ///  - Cash: called directly from Checkout -> saved as Pending until staff
  ///    confirms the cash was received. Only allowed for standard orders that
  ///    are not scheduled ahead of time.
  /// Saves the order AND its payment record in one batch, and only then clears
  /// the cart. Returns null (cart kept) if saving fails.
  Future<Order?> completeOrderWithPayment(PaymentMethod method) async {
    final customer = currentCustomer;
    if (customer == null || cart.isEmpty) {
      onError?.call('Your cart is empty or you are not logged in.');
      return null;
    }

    final isCash = method == PaymentMethod.cash;
    final orderNo = 'RR-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
    final String? txnRef = isCash ? null : _generateTxnRef(method);
    final List<OrderItem> items = [
      for (final c in cart) OrderItem.fromCartItem(c, customizationLevel: _levelOf(c)),
    ];
    final double total = cartSubtotal;
    final isImmediate = draftImmediate;
    final schedule = isImmediate ? DateTime.now() : (draftSchedule ?? DateTime.now().add(const Duration(days: 1)));

    // Business rule: cash only for IMMEDIATE orders.
    if (isCash && !isCashAllowed(isImmediate: isImmediate)) {
      onError?.call('Cash is only available for immediate pickup/delivery.');
      return null;
    }

    final order = Order(
      id: orderNo,
      customerId: customer.id,
      customerName: draftContactName.isNotEmpty ? draftContactName : customer.name,
      customerContact: draftContactNumber.isNotEmpty ? draftContactNumber : customer.contact,
      items: items,
      subtotal: total,
      total: total,
      fulfillmentMethod: draftFulfillment,
      scheduledDateTime: schedule,
      deliveryAddress: draftFulfillment == FulfillmentMethod.delivery ? draftAddress : null,
      paymentMethodLabel: method.label,
      paymentStatus: isCash ? PaymentStatus.pending : PaymentStatus.paid,
      transactionRef: txnRef,
      orderStatus: OrderStatus.received,
      createdAt: DateTime.now(),
      isImmediate: isImmediate,
    );

    try {
      await _customerCrud
          .placeOrder(
            orderNo: orderNo,
            transactionRef: txnRef,
            items: [
              for (final i in items)
                {
                  'product_name': i.productName,
                  'unit_price': i.unitPrice,
                  'quantity': i.quantity,
                  'customization_summary': i.customizationSummary,
                  'customization_level': i.customizationLevel,
                  'image_url': i.productImageUrl,
                  'reference_url': i.referenceImageUrl,
                },
            ],
            total: total,
            fulfillmentMethod: order.fulfillmentMethod.name,
            schedule: order.scheduledDateTime,
            isImmediate: isImmediate,
            paymentMethod: method.label,
            customerName: order.customerName,
            customerContact: order.customerContact,
            deliveryAddress: order.deliveryAddress,
          )
          .timeout(const Duration(seconds: 20));
    } on StateError catch (e) {
      onError?.call(e.message);
      return null;
    } on TimeoutException {
      onError?.call('Saving your order timed out. Check your connection and try again.');
      return null;
    } on FirebaseException catch (e) {
      onError?.call(e.code == 'permission-denied'
          ? 'Order could not be recorded (permission denied).'
          : 'Order could not be recorded. Check your connection and try again.');
      return null;
    } catch (_) {
      onError?.call('Something went wrong while saving your order. Please try again.');
      return null;
    }

    // Saved: show it instantly (the Firestore stream will replace the list), then clear the cart.
    if (orderById(orderNo) == null) _orders.add(order);
    draftFulfillment = FulfillmentMethod.pickup;
    draftSchedule = null;
    draftPaymentMethod = null;
    draftImmediate = true;
    clearCart(); // also notifies listeners
    return order;
  }

  String _generateTxnRef(PaymentMethod method) {
    final prefix = method == PaymentMethod.gcash ? 'GC' : (method == PaymentMethod.maya ? 'MY' : 'QR');
    final number = 10000000 + _rand.nextInt(89999999);
    return '$prefix-$number';
  }

  /// Staff: moves the order exactly one step forward (the service enforces the sequence).
  void updateOrderStatus(String orderId, OrderStatus status) => _run(() => _staffCrud.advanceOrderStatus(orderId));

  /// Both staff and customers: only while the order is "received" (before
  /// baking/decorating, or before the baker accepts a bespoke request).
  void cancelOrder(String orderId, String reason) {
    final o = orderById(orderId);
    if (o == null) return;
    final isStaff = role == UserRole.staff;
    final allowed = isStaff ? o.isCancellable : o.isCancellableByCustomer;
    if (!allowed) {
      if (!isStaff) onError?.call('This order can no longer be cancelled (preparation has started).');
      return;
    }
    _run(() => isStaff ? _staffCrud.cancelOrder(orderId, reason) : _customerCrud.cancelOrder(orderId, reason));
  }

  /// Staff-only explicit verification of a pending payment (also used to
  /// confirm cash received).
  void staffVerifyPaymentAsPaid(String orderId) => _run(() => _staffCrud.verifyPayment(orderId));

  /// Staff-only, CASH orders: mark cash as received (paid) or revert to pending.
  void staffSetCashPaid(String orderId, {required bool paid}) =>
      _run(() => _staffCrud.setCashPaymentStatus(orderId, paid: paid));

  // ---- Analytics ----
  AnalyticsResult computeAnalytics({DateTime? start, DateTime? end}) {
    final rangeStart = start ?? DateTime(2000);
    final rangeEnd = end ?? DateTime.now().add(const Duration(days: 3650));
    final List<Order> inRange =
        _orders.where((Order o) => o.createdAt.isAfter(rangeStart) && o.createdAt.isBefore(rangeEnd)).toList();

    double totalSales = 0.0;
    final salesByProduct = <String, double>{};
    final unitsByProduct = <String, int>{};
    final salesByCategory = <ProductCategory, double>{};
    final salesOverTime = <String, double>{};
    final paymentStatusSummary = <PaymentStatus, int>{};
    int completed = 0, pending = 0, cancelled = 0;

    for (final o in inRange) {
      paymentStatusSummary[o.paymentStatus] = (paymentStatusSummary[o.paymentStatus] ?? 0) + 1;
      if (o.orderStatus == OrderStatus.completed) completed++;
      if (o.orderStatus == OrderStatus.cancelled) cancelled++;
      if (o.orderStatus != OrderStatus.completed && o.orderStatus != OrderStatus.cancelled) pending++;

      final countsForSales = o.orderStatus != OrderStatus.cancelled && o.paymentStatus == PaymentStatus.paid;
      if (countsForSales) {
        totalSales += o.total;
        final dayKey =
            '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2, '0')}-${o.createdAt.day.toString().padLeft(2, '0')}';
        salesOverTime[dayKey] = (salesOverTime[dayKey] ?? 0.0) + o.total;

        for (final item in o.items) {
          salesByProduct[item.productName] = (salesByProduct[item.productName] ?? 0.0) + item.lineTotal;
          unitsByProduct[item.productName] = (unitsByProduct[item.productName] ?? 0) + item.quantity;
          if (_products.isNotEmpty) {
            final cat = _products.firstWhere((p) => p.name == item.productName, orElse: () => _products.first).category;
            salesByCategory[cat] = (salesByCategory[cat] ?? 0.0) + item.lineTotal;
          }
        }
      }
    }

    final paymentMethodBreakdown = <PaymentMethod, List<num>>{};
    for (final p in _payments.where(
        (p) => p.status == PaymentRecordStatus.paid && p.date.isAfter(rangeStart) && p.date.isBefore(rangeEnd))) {
      final List<num> existing = paymentMethodBreakdown[p.method] ?? <num>[0, 0];
      paymentMethodBreakdown[p.method] = <num>[existing[0] + 1, existing[1] + p.amount];
    }

    return AnalyticsResult(
      totalSales: totalSales,
      totalOrders: inRange.length,
      completedOrders: completed,
      pendingOrders: pending,
      cancelledOrders: cancelled,
      paymentStatusSummary: paymentStatusSummary,
      salesByProduct: salesByProduct,
      unitsByProduct: unitsByProduct,
      salesByCategory: salesByCategory,
      salesOverTime: salesOverTime,
      paymentMethodBreakdown: paymentMethodBreakdown,
    );
  }
}