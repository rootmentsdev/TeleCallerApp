/// Represents a single selected store with brand and location.
class StoreSelection {
  final String brand;
  final String location;

  const StoreSelection({required this.brand, required this.location});
}

/// Utility class for managing store brand > location mapping.
class StoreLocations {
  StoreLocations._(); // Prevent instantiation

  /// Store name normalization mapping (backend names -> frontend names)
  static const Map<String, String> storeNameNormalization = {
    'Calicut': 'Kozhikode',
    'calicut': 'Kozhikode',
    'CALICUT': 'Kozhikode',
    'Cochin': 'Edappally',
    'cochin': 'Edappally',
    'COCHIN': 'Edappally',
  };

  /// Store lists by brand
  static const List<String> suitorGuyStores = [
    'Trivandrum',
    'Kottayam',
    'Edappally',
    'MG Road',
    'Perumbavoor',
    'Thrissur',
    'Palakkad',
    'Chavakkad',
    'Edappal',
    'Perinthalmanna',
    'Manjeri',
    'Kottakal',
    'Kozhikode',
    'Vadakara',
    'Kannur',
    'Kalpetta',
  ];

  static const List<String> zorucciStores = [
    'Edappally',
    'Perinthalmanna',
    'Edappal',
    'Kottakkal',
  ];

  /// Map of brand -> store list
  static const Map<String, List<String>> brandStores = {
    'Suitor Guy': suitorGuyStores,
    'Zorucci': zorucciStores,
  };

  /// Normalize store name from backend format
  static String normalizeStoreName(String? storeName) {
    if (storeName == null || storeName.isEmpty) return '';

    // Check if it's in the normalization map
    if (storeNameNormalization.containsKey(storeName)) {
      return storeNameNormalization[storeName]!;
    }

    // Return as-is if not in map
    return storeName;
  }

  /// Default brand (first entry in map)
  static String get defaultBrand => brandStores.keys.first;

  /// Default location for selected brand
  static String defaultLocationForBrand(String brand) {
    final locations = brandStores[brand];
    return (locations != null && locations.isNotEmpty) ? locations.first : '';
  }

  /// Combined store dropdown options
  static List<String> buildStoreOptions() {
    final List<String> options = [];

    brandStores.forEach((brand, locations) {
      for (final location in locations) {
        options.add('$brand - $location');
      }
    });

    return options;
  }

  /// Converts option string to a StoreSelection model
  static StoreSelection resolveSelection(String? storeOption) {
    final fallbackBrand = defaultBrand;
    final fallbackLocation = defaultLocationForBrand(defaultBrand);

    // Handle null or empty
    if (storeOption == null || storeOption.isEmpty) {
      return StoreSelection(brand: fallbackBrand, location: fallbackLocation);
    }

    final parts = storeOption.split(' - ');
    final brandName = parts.first;
    final locations = brandStores[brandName];

    // Invalid brand fallback
    if (locations == null || locations.isEmpty) {
      return StoreSelection(brand: fallbackBrand, location: fallbackLocation);
    }

    // Without explicit location, return first
    if (parts.length < 2) {
      return StoreSelection(brand: brandName, location: locations.first);
    }

    final locationName = parts[1];
    final resolvedLocation =
        locations.contains(locationName) ? locationName : locations.first;

    return StoreSelection(brand: brandName, location: resolvedLocation);
  }
}
