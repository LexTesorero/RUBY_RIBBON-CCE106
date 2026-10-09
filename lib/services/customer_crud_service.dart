import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/order_rules.dart';
import 'service_shared.dart';

/// Everything a logged-in customer can do. Every read/write is scoped to the
/// signed-in uid, so a customer only ever sees their own orders (and cart).
class CustomerCrudService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _images = CloudinaryService();

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in first.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _payments => _db.collection('payments');
  CollectionReference<Map<String, dynamic>> get _cart => _db.collection('users').doc(_uid).collection('cart');

  // ---------- Menu (read-only; only published products) ----------
  Stream<Docs> getMenu() =>
      _products.where('visibility', isEqualTo: 'published').snapshots().map((s) => newestFirst(s.docs));

  // ---------- Bespoke reference image (uploaded to Cloudinary) ----------
  Future<PickedImage?> pickReferenceImage({ImageSource source = ImageSource.gallery}) =>
      _images.pickAndUpload(source: source, folder: 'ruby_ribbon/references');

  // ---------- Cart (per-account, optional: the app currently keeps the cart in memory) ----------
  Stream<Docs> getCart() => _cart.snapshots().map((s) => newestFirst(s.docs));

  Future<void> addToCart(Map<String, dynamic> item) => _cart.add({...item, 'created_at': Timestamp.now()});

  Future<void> updateCartQuantity(String itemId, int quantity) async {
    if (quantity < 1) return; // quantity can never go below 1
    await _cart.doc(itemId).update({'quantity': quantity});
  }

  Future<void> removeCartItem(String itemId) => _cart.doc(itemId).delete();

  Future<void> clearCart() async {
    final snap = await _cart.get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  // ---------- Orders ----------
  /// Creates the order and its payment record together. The order number is
  /// also the document id.
  ///
  /// Online payments (GCash / Maya / QR Ph): call only after the simulated
  /// payment succeeds -> saved as 'paid'.
  /// Cash: allowed only for standard orders that are not scheduled ahead ->
  /// saved as 'pending' until staff verifies the cash was received.
  Future<String> placeOrder({
    required String orderNo,
    required String? transactionRef, // null for cash
    required List<Map<String, dynamic>> items,
    required double total,
    required String fulfillmentMethod, // 'pickup' | 'delivery'
    required DateTime schedule,
    required bool isImmediate, // immediate pickup/delivery vs scheduled
    required String paymentMethod, // 'GCash' | 'Maya' | 'QR Ph' | 'Cash'
    required String customerName,
    required String customerContact,
    String? deliveryAddress,
  }) async {
    final uid = _uid;
    final isCash = paymentMethod == 'Cash';

    // Enforce the business rule even if the UI is bypassed.
    // Each item map must contain 'customization_level'.
    final levels = items.map((i) => (i['customization_level'] ?? 'standard') as String).toList();
    final hasModular = levels.contains('modular');
    final hasBespoke = levels.contains('bespoke');
    if (isCash && !isCashAllowed(isImmediate: isImmediate)) {
      throw StateError('Cash is only available for immediate pickup/delivery.');
    }

    final payStatus = isCash ? 'pending' : 'paid';
    final orderRef = _orders.doc(orderNo);
    final paymentRef = _payments.doc('PAY-$orderNo');
    final now = Timestamp.now();

    final batch = _db.batch();
    batch.set(orderRef, {
      'order_no': orderNo,
      'customer_id': uid,
      'customer_name': customerName,
      'customer_contact': customerContact,
      'items': items,
      'has_customized_items': hasModular || hasBespoke,
      'has_bespoke_items': hasBespoke,
      'is_immediate': isImmediate,
      'subtotal': total,
      'total': total,
      'fulfillment_method': fulfillmentMethod,
      'scheduled_at': Timestamp.fromDate(schedule),
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod,
      'payment_status': payStatus,
      'payment_id': paymentRef.id,
      'transaction_ref': transactionRef,
      'status': 'received',
      'created_at': now,
      'updated_at': now,
    });
    batch.set(paymentRef, {
      'order_id': orderNo,
      'customer_id': uid,
      'method': paymentMethod,
      'amount': total,
      'reference': transactionRef,
      'status': payStatus,
      'paid_at': isCash ? null : now,
    });
    await batch.commit();
    return orderNo;
  }

  /// Order history: only this customer's orders.
  Stream<Docs> getMyOrders() =>
      _orders.where('customer_id', isEqualTo: _uid).snapshots().map((s) => newestFirst(s.docs));

  /// Live tracking: updates the moment staff changes the status.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOrder(String orderId) => _orders.doc(orderId).snapshots();

  /// Customers can cancel only while status is 'received' (before baking, or
  /// before the baker accepts a bespoke request). Same rule for all order types.
  Future<void> cancelOrder(String orderId, String reason) async {
    final uid = _uid;
    final ref = _orders.doc(orderId);

    await _db.runTransaction((tx) async {
      final data = (await tx.get(ref)).data();
      if (data == null || data['customer_id'] != uid) throw StateError('Order not found.');
      if (data['status'] != 'received') {
        throw StateError('This order can no longer be cancelled.');
      }

      final wasPaid = data['payment_status'] == 'paid';
      tx.update(ref, {
        'status': 'cancelled',
        'cancellation_reason': reason,
        'payment_status': wasPaid ? 'refunded' : data['payment_status'],
        'updated_at': Timestamp.now(),
      });

      final paymentId = data['payment_id'] as String?;
      if (wasPaid && paymentId != null) {
        tx.update(_payments.doc(paymentId), {'status': 'refunded'});
      }
    });
  }
}