/// Store model representing a single store with brand and location
class Store {
  final String brand;
  final String location;
  final String normalizedName;

  Store({
    required this.brand,
    required this.location,
    required this.normalizedName,
  });

  /// Factory constructor to create Store from JSON
  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      brand: json['brand'] as String? ?? '',
      location: json['location'] as String? ?? '',
      normalizedName: json['normalizedName'] as String? ?? '',
    );
  }

  /// Convert Store to JSON
  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'location': location,
      'normalizedName': normalizedName,
    };
  }

  @override
  String toString() => normalizedName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Store &&
          runtimeType == other.runtimeType &&
          normalizedName == other.normalizedName;

  @override
  int get hashCode => normalizedName.hashCode;
}

/// Response model for stores API
class StoresResponse {
  final bool success;
  final String message;
  final List<Store> stores;

  StoresResponse({
    required this.success,
    required this.message,
    required this.stores,
  });

  /// Factory constructor to create StoresResponse from JSON
  factory StoresResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final storesList = data['stores'] as List<dynamic>? ?? [];

    return StoresResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      stores:
          storesList
              .map((store) => Store.fromJson(store as Map<String, dynamic>))
              .toList(),
    );
  }
}
