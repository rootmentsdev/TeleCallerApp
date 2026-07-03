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
  /// Handles case variations and spelling differences between backend and frontend
  static const Map<String, String> storeNameNormalization = {
    // Calicut -> Kozhikode
    'Calicut': 'Kozhikode',
    'calicut': 'Kozhikode',
    'CALICUT': 'Kozhikode',
    // Cochin -> Edappally
    'Cochin': 'Edappally',
    'cochin': 'Edappally',
    'COCHIN': 'Edappally',
    // MG Road variations
    'mg road': 'MG Road',
    'MG road': 'MG Road',
    'mg Road': 'MG Road',
    'MG_Road': 'MG Road',
    'mg_road': 'MG Road',
    'MG-Road': 'MG Road',
    'mg-road': 'MG Road',
    'M.G. Road': 'MG Road',
    'm.g. road': 'MG Road',
    // Vatakara -> Vadakara
    'Vatakara': 'Vadakara',
    'vatakara': 'Vadakara',
    'VATAKARA': 'Vadakara',
    // Trivandrum variations
    'trivandrum': 'Trivandrum',
    'TRIVANDRUM': 'Trivandrum',
    'Thiruvananthapuram': 'Trivandrum',
    'thiruvananthapuram': 'Trivandrum',
    // Kottayam variations
    'kottayam': 'Kottayam',
    'KOTTAYAM': 'Kottayam',
    // Edappally variations
    'edappally': 'Edappally',
    'EDAPPALLY': 'Edappally',
    'Edapally': 'Edappally',
    'edapally': 'Edappally',
    // Perumbavoor variations
    'perumbavoor': 'Perumbavoor',
    'PERUMBAVOOR': 'Perumbavoor',
    'Perumbavur': 'Perumbavoor',
    'perumbavur': 'Perumbavoor',
    // Thrissur variations
    'thrissur': 'Thrissur',
    'THRISSUR': 'Thrissur',
    'Trichur': 'Thrissur',
    'trichur': 'Thrissur',
    // Palakkad variations
    'palakkad': 'Palakkad',
    'PALAKKAD': 'Palakkad',
    'Palghat': 'Palakkad',
    'palghat': 'Palakkad',
    // Chavakkad variations
    'chavakkad': 'Chavakkad',
    'CHAVAKKAD': 'Chavakkad',
    'Chavakad': 'Chavakkad',
    'chavakad': 'Chavakkad',
    // Edappal variations
    'edappal': 'Edappal',
    'EDAPPAL': 'Edappal',
    'Edapal': 'Edappal',
    'edapal': 'Edappal',
    // Perinthalmanna variations
    'perinthalmanna': 'Perinthalmanna',
    'PERINTHALMANNA': 'Perinthalmanna',
    // Manjeri variations
    'manjeri': 'Manjeri',
    'MANJERI': 'Manjeri',
    // Kottakal variations (Suitor Guy - note: different from Zorucci's Kottakkal)
    'kottakal': 'Kottakal',
    'KOTTAKAL': 'Kottakal',
    // Kozhikode variations
    'kozhikode': 'Kozhikode',
    'KOZHIKODE': 'Kozhikode',
    // Vadakara variations
    'vadakara': 'Vadakara',
    'VADAKARA': 'Vadakara',
    // Kannur variations
    'kannur': 'Kannur',
    'KANNUR': 'Kannur',
    'Cannanore': 'Kannur',
    'cannanore': 'Kannur',
    // Kalpetta variations
    'kalpetta': 'Kalpetta',
    'KALPETTA': 'Kalpetta',
    // Kottakkal variations (Zorucci - different from Kottakal)
    'Kottakkal': 'Kottakkal',
    'kottakkal': 'Kottakkal',
    'KOTTAKKAL': 'Kottakkal',
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

  static const List<String> dapperSquadStores = ['Edappally'];

  /// Map of brand -> store list
  static const Map<String, List<String>> brandStores = {
    'Suitor Guy': suitorGuyStores,
    'Zorucci': zorucciStores,
    'Dapper Squad': dapperSquadStores,
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
    final List<String> options = ['All Stores'];

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

    // Handle "All Stores" special case
    if (storeOption == 'All Stores') {
      return StoreSelection(brand: 'All', location: 'Stores');
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
