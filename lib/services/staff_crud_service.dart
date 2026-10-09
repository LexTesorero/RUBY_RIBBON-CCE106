import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'service_shared.dart';

/// Everything bakery staff can do. Every write first confirms the signed-in
/// account really has the staff role (Firestore rules enforce it too).
class StaffCrudService {
  static const _flow = ['received', 'baking', 'ready', 'completed'];

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _images = CloudinaryService();

  String? _verifiedUid;

  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _payments => _db.collection('payments');

  Future<void> _requireStaff() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please log in first.');
    if (_verifiedUid == user.uid) return;
    final snap = await _db.collection('users').doc(user.uid).get();
    if (snap.data()?['role'] != 'staff') throw StateError('Staff access only.');
    _verifiedUid = user.uid;
  }

  // ---------- Product photo (uploaded to Cloudinary) ----------
  Future<PickedImage?> pickImage({ImageSource source = ImageSource.gallery}) async {
    await _requireStaff();
    return _images.pickAndUpload(source: source, folder: 'ruby_ribbon/products');
  }

  // ---------- Products ----------
  /// Staff see every product, including hidden/archived ones.
  Stream<Docs> getProducts() => _products.snapshots().map((s) => newestFirst(s.docs));

  /// Add (id == null) or update (id given). Returns the product id.
  Future<String> saveProduct({
    String? id,
    required String name,
    required String description,
    required String category, // 'cakes' | 'pastries' | 'breads'
    required double basePrice,
    List<Map<String, dynamic>> variants = const [], // [{name, price_delta}]
    String customizationLevel = 'standard', // 'standard' | 'modular' | 'bespoke'
    List<Map<String, dynamic>> modularOptions = const [], // [{name, required, choices:[{label, price_delta}]}]
    bool bespokeAllowReferenceImage = true,
    bool bespokeAllowMessage = true,
    String availability = 'available', // 'available' | 'soldOut'
    String visibility = 'published', // 'published' | 'hidden'
    bool featured = false,
    String? imageUrl, // pass the existing URL when editing without changing the photo
  }) async {
    await _requireStaff();

    final data = {
      'name': name,
      'description': description,
      'category': category,
      'base_price': basePrice,
      'variants': variants,
      'customization_level': customizationLevel,
      'modular_options': modularOptions,
      'bespoke_allow_reference_image': bespokeAllowReferenceImage,
      'bespoke_allow_message': bespokeAllowMessage,
      'availability': availability,
      'visibility': visibility,
      'featured': featured,
      'image_url': imageUrl,
      'updated_at': Timestamp.now(),
    };

    if (id == null) {
      final ref = await _products.add({...data, 'created_at': Timestamp.now()});
      return ref.id;
    }
    await _products.doc(id).update(data);
    return id;
  }

  Future<void> setAvailability(String id, bool available) async {
    await _requireStaff();
    await _products.doc(id).update({
      'availability': available ? 'available' : 'soldOut',
      'updated_at': Timestamp.now(),
    });
  }

  /// Hides the product from the customer menu without deleting it.
  Future<void> archiveProduct(String id) async {
    await _requireStaff();
    await _products.doc(id).update({
      'visibility': 'hidden',
      'archived': true,
      'updated_at': Timestamp.now(),
    });
  }

  Future<void> deleteProduct(String id) async {
    await _requireStaff();
    await _products.doc(id).delete();
  }

  // ---------- Orders ----------
  /// All orders, newest first. Pass a status to filter.
  Stream<Docs> getOrders({String? status}) {
    Query<Map<String, dynamic>> q = _orders;
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((s) => newestFirst(s.docs));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOrder(String orderId) => _orders.doc(orderId).snapshots();

  /// Received -> Baking & Decorating -> Ready -> Completed, one step at a time.
  Future<String> advanceOrderStatus(String orderId) async {
    await _requireStaff();
    final ref = _orders.doc(orderId);

    return _db.runTransaction((tx) async {
      final data = (await tx.get(ref)).data();
      if (data == null) throw StateError('Order not found.');

      final i = _flow.indexOf(data['status'] as String);
      if (i == -1 || i == _flow.length - 1) throw StateError('This order cannot be advanced further.');
      final next = _flow[i + 1];
      tx.update(ref, {'status': next, 'updated_at': Timestamp.now()});
      return next;
    });
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    await _requireStaff();
    final ref = _orders.doc(orderId);

    await _db.runTransaction((tx) async {
      final data = (await tx.get(ref)).data();
      if (data == null) throw StateError('Order not found.');
      final status = data['status'];
      if (status == 'completed' || status == 'cancelled') {
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

  // ---------- Payments ----------
  Stream<Docs> getPayments() => _payments.snapshots().map((s) {
        final list = [...s.docs];
        list.sort((a, b) {
          final at = a.data()['paid_at'] as Timestamp?;
          final bt = b.data()['paid_at'] as Timestamp?;
          if (at == null || bt == null) return 0;
          return bt.compareTo(at);
        });
        return list;
      });

  Future<DocumentSnapshot<Map<String, dynamic>>?> getPaymentForOrder(String orderId) async {
    await _requireStaff();
    final snap = await _payments.where('order_id', isEqualTo: orderId).limit(1).get();
    return snap.docs.isEmpty ? null : snap.docs.first;
  }

  /// The explicit verification action. An unpaid online order can only become
  /// Paid through this, never by a plain status edit.
  Future<void> verifyPayment(String orderId) async {
    await _requireStaff();
    final orderRef = _orders.doc(orderId);

    await _db.runTransaction((tx) async {
      final data = (await tx.get(orderRef)).data();
      if (data == null) throw StateError('Order not found.');
      if (data['payment_status'] != 'pending') throw StateError('Only pending payments can be verified.');
      tx.update(orderRef, {'payment_status': 'paid', 'updated_at': Timestamp.now()});

      final paymentId = data['payment_id'] as String?;
      if (paymentId != null) {
        tx.update(_payments.doc(paymentId), {'status': 'paid', 'paid_at': Timestamp.now()});
      }
    });
  }

  /// CASH ONLY. Staff can mark a cash order Paid (cash received) or back to
  /// Pending (to correct a mistake), at any point until the order is cancelled
  /// (including after it is Completed, since cash is usually collected at
  /// pickup/delivery). Online payments cannot be changed this way.
  Future<void> setCashPaymentStatus(String orderId, {required bool paid}) async {
    await _requireStaff();
    final orderRef = _orders.doc(orderId);

    await _db.runTransaction((tx) async {
      final data = (await tx.get(orderRef)).data();
      if (data == null) throw StateError('Order not found.');
      if (data['payment_method'] != 'Cash') {
        throw StateError('Only cash payments can be changed manually.');
      }
      if (data['status'] == 'cancelled') {
        throw StateError('A cancelled order\'s payment cannot be changed.');
      }

      // Modular/bespoke: cash can be confirmed only after the baker has accepted the order.
      if (paid) {
        final items = (data['items'] as List?) ?? const [];
        final hasCustomized =
            items.any((i) => i is Map && (i['customization_level'] ?? 'standard') != 'standard');
        if (hasCustomized && data['status'] == 'received') {
          throw StateError('Accept the order first (Start Preparation), then confirm the cash payment.');
        }
      }

      final current = data['payment_status'];
      if (current != 'pending' && current != 'paid') {
        throw StateError('This payment can no longer be changed.');
      }

      final target = paid ? 'paid' : 'pending';
      if (current == target) return; // already in that state

      final now = Timestamp.now();
      tx.update(orderRef, {'payment_status': target, 'updated_at': now});

      final paymentId = data['payment_id'] as String?;
      if (paymentId != null) {
        tx.update(_payments.doc(paymentId), {
          'status': target,
          'paid_at': paid ? now : null,
        });
      }
    });
  }

  // ---------- Analytics ----------
  Stream<Docs> watchOrdersBetween(DateTime start, DateTime end) => _orders
      .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .snapshots()
      .map((s) => s.docs);
}