import 'package:telecaller_app/utils/date_formatter.dart';
import 'package:telecaller_app/utils/store_location.dart';

/// Model class for Complaint data
class ComplaintModel {
  final String id;
  final String name;
  final String phone;
  final String store;
  final String type;
  final String date;
  final String functionDate;
  final String subCategory;
  final String remarks;
  final String callStatus;
  final String leadStatus;
  final bool isExpanded;
  final Map<String, dynamic> rawData;

  ComplaintModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.store,
    required this.type,
    required this.date,
    required this.functionDate,
    required this.subCategory,
    required this.remarks,
    required this.callStatus,
    required this.leadStatus,
    this.isExpanded = false,
    required this.rawData,
  });

  /// Create ComplaintModel from API response
  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    // Normalize store name from backend
    final rawStore = json['store']?.toString() ?? '';
    final normalizedStore = StoreLocations.normalizeStoreName(rawStore);

    return ComplaintModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      phone: json['phone']?.toString() ?? '',
      store: normalizedStore,
      type: json['leadType']?.toString() ?? 'Enquiry',
      date: _formatDate(json['createdAt']),
      functionDate: json['functionDate']?.toString() ?? '',
      subCategory: json['subCategory']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      callStatus: json['callStatus']?.toString() ?? 'Not Called',
      leadStatus: json['leadStatus']?.toString() ?? 'No Status',
      rawData: json,
    );
  }

  /// Format date from ISO string
  static String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      final date = DateTime.parse(dateValue.toString());
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '${DateFormatter.formatDate(date)} $hour:$minute';
    } catch (e) {
      return dateValue.toString();
    }
  }

  /// Convert to Map for UI display
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'store': store,
      'type': type,
      'date': date,
      'functionDate': functionDate,
      'subCategory': subCategory,
      'remarks': remarks,
      'callStatus': callStatus,
      'leadStatus': leadStatus,
      'isExpanded': isExpanded,
      'rawData': rawData,
    };
  }

  /// Create a copy with updated fields
  ComplaintModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? store,
    String? type,
    String? date,
    String? functionDate,
    String? subCategory,
    String? remarks,
    String? callStatus,
    String? leadStatus,
    bool? isExpanded,
    Map<String, dynamic>? rawData,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      store: store ?? this.store,
      type: type ?? this.type,
      date: date ?? this.date,
      functionDate: functionDate ?? this.functionDate,
      subCategory: subCategory ?? this.subCategory,
      remarks: remarks ?? this.remarks,
      callStatus: callStatus ?? this.callStatus,
      leadStatus: leadStatus ?? this.leadStatus,
      isExpanded: isExpanded ?? this.isExpanded,
      rawData: rawData ?? this.rawData,
    );
  }
}
