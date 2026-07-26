import 'package:flutter/foundation.dart';

import '../models/product.dart';

/// Tracks which products the shopper has "wished" (tapped the heart on).
/// Lives for the app session only — same lightweight in-memory approach as
/// the cart in `HomeScreen`, just hoisted to a static store so any screen
/// (product card, product detail) can read/toggle it without threading a
/// callback all the way down.
///
/// Keyed by `product.name`, matching how the cart already identifies a
/// product (see `CartItem` lookups in `home_screen.dart`), so the same
/// product shows the same wished state everywhere it appears.
class WishlistStore {
  WishlistStore._();

  static final ValueNotifier<Set<String>> wished = ValueNotifier<Set<String>>({});

  static bool isWished(Product product) => wished.value.contains(product.name);

  /// Flips the wished state for [product] and returns the new state.
  static bool toggle(Product product) {
    final next = Set<String>.from(wished.value);
    final nowWished = !next.remove(product.name);
    if (nowWished) next.add(product.name);
    wished.value = next;
    return nowWished;
  }
}
