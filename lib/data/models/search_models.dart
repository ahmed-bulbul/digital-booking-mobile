// Backend enums use @JsonValue on getCode(), so type and status arrive as ints.
String _parseInventoryType(dynamic v) {
  if (v == null) return 'SEAT';
  if (v is String) return v;
  const map = {1: 'SEAT', 2: 'BERTH', 3: 'ROOM', 4: 'CABIN'};
  return map[v as int] ?? 'SEAT';
}

String _parseInventoryStatus(dynamic v) {
  if (v == null) return 'UNAVAILABLE';
  if (v is String) return v;
  const map = {1: 'AVAILABLE', 2: 'LOCKED', 3: 'BOOKED', 4: 'CANCELLED', 5: 'MAINTENANCE'};
  return map[v as int] ?? 'UNAVAILABLE';
}

class SearchResult {
  final int scheduleId;
  final int routeId;
  final String productName;
  final String? productImageUrl;
  final int providerId;
  final String providerName;
  final String sourceName;
  final String destinationName;
  final DateTime departureAt;
  final DateTime arrivalAt;
  final int availableCount;
  final int durationMinutes;
  final double minPrice;
  final String currency;

  SearchResult({
    required this.scheduleId,
    required this.routeId,
    required this.productName,
    this.productImageUrl,
    required this.providerId,
    required this.providerName,
    required this.sourceName,
    required this.destinationName,
    required this.departureAt,
    required this.arrivalAt,
    required this.availableCount,
    required this.durationMinutes,
    required this.minPrice,
    required this.currency,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        scheduleId: json['scheduleId'] as int,
        routeId: json['routeId'] as int,
        productName: json['productName'] as String? ?? '',
        productImageUrl: json['productImageUrl'] as String?,
        providerId: json['providerId'] as int,
        providerName: json['providerName'] as String? ?? '',
        sourceName: json['sourceName'] as String? ?? '',
        destinationName: json['destinationName'] as String? ?? '',
        departureAt: DateTime.parse(json['departureAt'] as String),
        arrivalAt: DateTime.parse(json['arrivalAt'] as String),
        availableCount: json['availableCount'] as int? ?? 0,
        durationMinutes: json['durationMinutes'] as int? ?? 0,
        minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'BDT',
      );
}

class InventoryItem {
  final int scheduleInventoryId;
  final int inventoryId;
  final String itemNumber;
  final int classId;
  final String className;
  final String type;
  final Map<String, dynamic> attributes;
  final String status;
  final int lockVersion;
  final double finalPrice;
  final double taxAmount;
  final String currency;

  InventoryItem({
    required this.scheduleInventoryId,
    required this.inventoryId,
    required this.itemNumber,
    required this.classId,
    required this.className,
    required this.type,
    required this.attributes,
    required this.status,
    required this.lockVersion,
    required this.finalPrice,
    required this.taxAmount,
    required this.currency,
  });

  bool get isAvailable => status == 'AVAILABLE';

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        scheduleInventoryId: json['scheduleInventoryId'] as int,
        inventoryId: json['inventoryId'] as int,
        itemNumber: json['itemNumber']?.toString() ?? '',
        classId: json['classId'] as int? ?? 0,
        className: json['className'] as String? ?? '',
        type: _parseInventoryType(json['type']),
        attributes: (json['attributes'] as Map?)?.cast<String, dynamic>() ?? {},
        status: _parseInventoryStatus(json['status']),
        lockVersion: json['lockVersion'] as int? ?? 0,
        finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
        taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'BDT',
      );
}

class ScheduleInventoryLayout {
  final int scheduleId;
  final List<InventoryItem> items;

  ScheduleInventoryLayout({required this.scheduleId, required this.items});

  factory ScheduleInventoryLayout.fromJson(Map<String, dynamic> json) => ScheduleInventoryLayout(
        scheduleId: json['scheduleId'] as int,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
