/// Booking Confirmation Lead Model
class BookingConfirmationLead {
  final String id;
  final String customerName;
  final String phone;
  final String store;
  final DateTime bookingDate;
  final DateTime? pickupDate;
  final double totalAmount;
  final String leadStatus;
  final String? attendedBy;
  final double? advanceAmount;
  final String? subCategory;
  final String? category;
  final String? bookingNo;
  final List<BookingItem>? items;

  BookingConfirmationLead({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.store,
    required this.bookingDate,
    this.pickupDate,
    required this.totalAmount,
    required this.leadStatus,
    this.attendedBy,
    this.advanceAmount,
    this.subCategory,
    this.category,
    this.bookingNo,
    this.items,
  });

  /// Factory constructor to create from JSON
  factory BookingConfirmationLead.fromJson(Map<String, dynamic> json) {
    return BookingConfirmationLead(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      store: json['store']?.toString() ?? '',
      bookingDate: _parseDate(json['bookingDate']),
      pickupDate: _parseDate(json['pickupDate']),
      totalAmount: _parseDouble(json['totalAmount']),
      leadStatus: json['leadStatus']?.toString() ?? 'new',
      attendedBy: json['attendedBy']?.toString(),
      advanceAmount: _parseDouble(json['advanceAmount']),
      subCategory: json['subCategory']?.toString(),
      category: json['category']?.toString(),
      bookingNo: json['bookingNo']?.toString(),
      items: _parseItems(json['items']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'phone': phone,
      'store': store,
      'bookingDate': bookingDate.toIso8601String(),
      'pickupDate': pickupDate?.toIso8601String(),
      'totalAmount': totalAmount,
      'leadStatus': leadStatus,
      'attendedBy': attendedBy,
      'advanceAmount': advanceAmount,
      'subCategory': subCategory,
      'category': category,
      'bookingNo': bookingNo,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  /// Helper to parse date
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Helper to parse double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  /// Helper to parse items
  static List<BookingItem>? _parseItems(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    try {
      return value
          .map((item) => BookingItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }
}

/// Booking Item Model
class BookingItem {
  final String itemCode;
  final String itemName;
  final double price;

  BookingItem({
    required this.itemCode,
    required this.itemName,
    required this.price,
  });

  /// Factory constructor to create from JSON
  factory BookingItem.fromJson(Map<String, dynamic> json) {
    return BookingItem(
      itemCode: json['itemCode']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      price: _parseDouble(json['price']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'itemCode': itemCode, 'itemName': itemName, 'price': price};
  }

  /// Helper to parse double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}
