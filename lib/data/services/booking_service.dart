import '../models/booking_models.dart';
import 'api_service.dart';
import '../../core/constants/api_constants.dart';

class BookingService {
  final ApiService _api;
  BookingService(this._api);

  Future<List<MyBooking>> getMyBookings({
    int page = 0,
    int size = 10,
    String? status,
  }) async {
    var path = '${ApiConstants.myBookings}?page=$page&size=$size';
    if (status != null) path += '&status=$status';
    final data = await _api.get(path);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => MyBooking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingDetail> getBookingDetail(int bookingId) async {
    final data = await _api.get('${ApiConstants.bookings}/$bookingId');
    return BookingDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  String ticketUrl(int bookingId) =>
      '${ApiConstants.baseUrl}${ApiConstants.bookings}/$bookingId/ticket';

  Future<Passenger> createPassenger({
    required int userId,
    required String firstName,
    required String lastName,
    String? gender,
    int? age,
    String? phone,
    String? email,
  }) async {
    final data = await _api.post(ApiConstants.passengers, {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      'nationality': 'BD',
    });
    return Passenger.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> lockSeat(int scheduleInventoryId, String sessionId, int lockVersion) async {
    await _api.post(
      '${ApiConstants.inventoryLock}/$scheduleInventoryId/lock',
      {'sessionId': sessionId, 'lockVersion': lockVersion},
    );
  }

  Future<BookingResponse> createBooking({
    required int userId,
    required String sessionId,
    required List<Map<String, dynamic>> items,
    String? couponCode,
  }) async {
    final data = await _api.post(ApiConstants.bookings, {
      'userId': userId,
      'sessionId': sessionId,
      'items': items,
      if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
    });
    return BookingResponse.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> confirmBooking(int bookingId, {String? sessionId}) async {
    var path = '${ApiConstants.bookings}/$bookingId/confirm';
    if (sessionId != null) path += '?sessionId=$sessionId';
    await _api.post(path, {});
  }

  Future<void> cancelBooking(int bookingId, String reason) async {
    await _api.post('${ApiConstants.bookings}/$bookingId/cancel', {'reason': reason});
  }
}
