import 'user_service.dart';

class VariantService {
  VariantService._();

  static const List<String> _variants = ['A', 'B', 'C'];
  static String? _overrideVariant;

  static String get variantId {
    if (_overrideVariant != null) {
      return _overrideVariant!;
    }

    final uuid = UserService.uuid;
    if (uuid.isEmpty) {
      return _variants.first;
    }

    final bucket = uuid.hashCode.abs() % _variants.length;
    return _variants[bucket];
  }

  static void overrideVariant(String variant) {
    if (variant.isEmpty) return;
    _overrideVariant = variant;
  }

  static void clearOverride() {
    _overrideVariant = null;
  }

  static void setFallbackVariant() {
    _overrideVariant = 'fallback_b';
  }
}
