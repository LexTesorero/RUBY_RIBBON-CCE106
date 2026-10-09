enum PaymentMethod { gcash, qrph, maya, cash }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.gcash:
        return 'GCash';
      case PaymentMethod.qrph:
        return 'QR Ph';
      case PaymentMethod.maya:
        return 'Maya';
      case PaymentMethod.cash:
        return 'Cash';
    }
  }
}

enum PaymentRecordStatus { pending, paid, failed, refunded }

extension PaymentRecordStatusX on PaymentRecordStatus {
  String get label {
    switch (this) {
      case PaymentRecordStatus.pending:
        return 'Pending';
      case PaymentRecordStatus.paid:
        return 'Paid';
      case PaymentRecordStatus.failed:
        return 'Failed';
      case PaymentRecordStatus.refunded:
        return 'Refunded';
    }
  }
}

class PaymentRecord {
  final String id;
  final String orderId;
  final PaymentMethod method;
  final double amount;
  final String transactionRef;
  final PaymentRecordStatus status;
  final DateTime date;

  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.transactionRef,
    required this.status,
    required this.date,
  });
}
