class MyBooking {
  final int bookingId;
  final String bookingRef;
  final String status;
  final DateTime createdAt;
  final DateTime departureAt;
  final DateTime arrivalAt;
  final String sourceName;
  final String destinationName;
  final String productName;
  final String providerName;
  final List<String> seats;
  final double grandTotal;
  final String currency;
  final String paymentStatus;
  final bool ticketAvailable;

  MyBooking({
    required this.bookingId,
    required this.bookingRef,
    required this.status,
    required this.createdAt,
    required this.departureAt,
    required this.arrivalAt,
    required this.sourceName,
    required this.destinationName,
    required this.productName,
    required this.providerName,
    required this.seats,
    required this.grandTotal,
    required this.currency,
    required this.paymentStatus,
    required this.ticketAvailable,
  });

  factory MyBooking.fromJson(Map<String, dynamic> json) => MyBooking(
        bookingId: json['bookingId'] as int,
        bookingRef: json['bookingRef'] as String? ?? '',
        status: _resolveStatus(json['status']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        departureAt: DateTime.parse(json['departureAt'] as String),
        arrivalAt: DateTime.parse(json['arrivalAt'] as String),
        sourceName: json['sourceName'] as String? ?? '',
        destinationName: json['destinationName'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        providerName: json['providerName'] as String? ?? '',
        seats: (json['seats'] as List<dynamic>? ?? []).cast<String>(),
        grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'BDT',
        paymentStatus: _resolvePaymentStatus(json['paymentStatus']),
        ticketAvailable: json['ticketAvailable'] as bool? ?? false,
      );

  static String _resolveStatus(dynamic v) {
    if (v is int) {
      const map = {1: 'PENDING', 2: 'CONFIRMED', 3: 'CANCELLED', 4: 'EXPIRED', 5: 'REFUNDED'};
      return map[v] ?? 'UNKNOWN';
    }
    return v?.toString() ?? 'UNKNOWN';
  }

  static String _resolvePaymentStatus(dynamic v) {
    if (v is int) {
      const map = {1: 'PENDING', 2: 'SUCCESS', 3: 'FAILED', 4: 'REFUNDED'};
      return map[v] ?? 'UNKNOWN';
    }
    return v?.toString() ?? 'UNKNOWN';
  }
}

class BookingResponse {
  final int bookingId;
  final String bookingRef;
  final String status;
  final double grandTotal;
  final String currency;

  BookingResponse({
    required this.bookingId,
    required this.bookingRef,
    required this.status,
    required this.grandTotal,
    required this.currency,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) => BookingResponse(
        bookingId: json['bookingId'] as int,
        bookingRef: json['bookingRef'] as String? ?? '',
        status: MyBooking._resolveStatus(json['status']),
        grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'BDT',
      );
}

class BookingDetail {
  final int bookingId;
  final String bookingRef;
  final String status;
  final double subtotal;
  final double taxTotal;
  final double discountTotal;
  final double grandTotal;
  final String currency;
  final DateTime createdAt;
  final int? scheduleId;
  final String productName;
  final String providerName;
  final String sourceName;
  final String sourceCity;
  final String destinationName;
  final String destinationCity;
  final DateTime? departureAt;
  final DateTime? arrivalAt;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final List<SeatPassenger> items;

  BookingDetail({
    required this.bookingId,
    required this.bookingRef,
    required this.status,
    required this.subtotal,
    required this.taxTotal,
    required this.discountTotal,
    required this.grandTotal,
    required this.currency,
    required this.createdAt,
    this.scheduleId,
    required this.productName,
    required this.providerName,
    required this.sourceName,
    required this.sourceCity,
    required this.destinationName,
    required this.destinationCity,
    this.departureAt,
    this.arrivalAt,
    this.userName,
    this.userEmail,
    this.userPhone,
    required this.items,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) => BookingDetail(
        bookingId: json['bookingId'] as int,
        bookingRef: json['bookingRef'] as String? ?? '',
        status: MyBooking._resolveStatus(json['status']),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
        taxTotal: (json['taxTotal'] as num?)?.toDouble() ?? 0.0,
        discountTotal: (json['discountTotal'] as num?)?.toDouble() ?? 0.0,
        grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'BDT',
        createdAt: DateTime.parse(json['createdAt'] as String),
        scheduleId: json['scheduleId'] as int?,
        productName: json['productName'] as String? ?? '',
        providerName: json['providerName'] as String? ?? '',
        sourceName: json['sourceName'] as String? ?? '',
        sourceCity: json['sourceCity'] as String? ?? '',
        destinationName: json['destinationName'] as String? ?? '',
        destinationCity: json['destinationCity'] as String? ?? '',
        departureAt: json['departureAt'] != null ? DateTime.parse(json['departureAt'] as String) : null,
        arrivalAt: json['arrivalAt'] != null ? DateTime.parse(json['arrivalAt'] as String) : null,
        userName: json['userName'] as String?,
        userEmail: json['userEmail'] as String?,
        userPhone: json['userPhone'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => SeatPassenger.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SeatPassenger {
  final int scheduleInventoryId;
  final String seatNumber;
  final int passengerId;
  final String passengerName;
  final String? gender;
  final String? email;
  final String? phone;
  final String? ticketNumber;
  final double unitPrice;
  final double taxAmount;

  SeatPassenger({
    required this.scheduleInventoryId,
    required this.seatNumber,
    required this.passengerId,
    required this.passengerName,
    this.gender,
    this.email,
    this.phone,
    this.ticketNumber,
    required this.unitPrice,
    required this.taxAmount,
  });

  factory SeatPassenger.fromJson(Map<String, dynamic> json) => SeatPassenger(
        scheduleInventoryId: json['scheduleInventoryId'] as int,
        seatNumber: json['seatNumber'] as String? ?? '',
        passengerId: json['passengerId'] as int,
        passengerName: json['passengerName'] as String? ?? '',
        gender: json['gender'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        ticketNumber: json['ticketNumber'] as String?,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
        taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      );
}

class Passenger {
  final int id;
  final String firstName;
  final String lastName;
  final String gender;

  Passenger({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) => Passenger(
        id: json['passengerId'] as int,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        gender: json['gender'] as String? ?? 'MALE',
      );
}

class PaymentResult {
  final int paymentId;
  final String status;

  PaymentResult({required this.paymentId, required this.status});

  factory PaymentResult.fromJson(Map<String, dynamic> json) => PaymentResult(
        paymentId: json['paymentId'] as int,
        status: _resolveStatus(json['status']),
      );

  static String _resolveStatus(dynamic v) {
    if (v is int) {
      const map = {1: 'PENDING', 2: 'SUCCESS', 3: 'FAILED', 4: 'REFUNDED'};
      return map[v] ?? 'UNKNOWN';
    }
    return v?.toString() ?? 'UNKNOWN';
  }
}

class RefundResult {
  final int id;
  final int bookingId;
  final double amount;
  final String reason;
  final String status;
  final DateTime createdAt;

  RefundResult({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory RefundResult.fromJson(Map<String, dynamic> json) => RefundResult(
        id: json['id'] as int,
        bookingId: json['bookingId'] as int,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        reason: json['reason'] as String? ?? '',
        status: json['status'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
