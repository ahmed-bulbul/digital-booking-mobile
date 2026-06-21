import 'package:uuid/uuid.dart';
import '../models/booking_models.dart';
import 'api_service.dart';
import '../../core/constants/api_constants.dart';

// Payment methods as backend integer codes
enum PaymentMethod {
  bkash(1, 'bKash', 'MANUAL'),
  nagad(2, 'Nagad', 'MANUAL'),
  card(3, 'Card / Online', 'ONLINE'),
  bankTransfer(4, 'Bank Transfer', 'MANUAL'),
  cash(5, 'Cash', 'MANUAL');

  final int code;
  final String label;
  final String gateway;
  const PaymentMethod(this.code, this.label, this.gateway);
}

class PaymentService {
  final ApiService _api;
  PaymentService(this._api);

  Future<PaymentResult> createPayment({
    required int bookingId,
    required PaymentMethod method,
    String? transactionId,
  }) async {
    final idempotencyKey = const Uuid().v4();
    final body = <String, dynamic>{
      'bookingId': bookingId,
      'method': method.code,
      'gateway': method.gateway,
      if (transactionId != null && transactionId.isNotEmpty)
        'transactionId': transactionId,
    };
    final data = await _api.post(
      ApiConstants.payments,
      body,
      extraHeaders: {'Idempotency-Key': idempotencyKey},
    );
    return PaymentResult.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> markPaymentSuccess(int paymentId) async {
    await _api.post('${ApiConstants.payments}/$paymentId/success', {});
  }

  Future<RefundResult> requestRefund({
    required int bookingId,
    required String reason,
  }) async {
    final data = await _api.post('/api/refunds', {
      'bookingId': bookingId,
      'reason': reason,
    });
    return RefundResult.fromJson(data['data'] as Map<String, dynamic>);
  }
}
