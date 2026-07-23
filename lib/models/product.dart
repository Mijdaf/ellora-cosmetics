import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../services/supabase_config.dart';

/// Formats a price in Egyptian Pounds, e.g. `85 EGP`.
String formatEGP(double price) {
  final rounded = price.round();
  return '$rounded EGP';
}

/// One line item in the shopping cart: a product plus how many the shopper
/// wants. Kept as a small mutable holder (not a `Product` field) so the
/// same product can be added, bumped, or removed without touching the
/// static catalog data.
class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class Product {
  final String id; // '' for a not-yet-saved product; a uuid once synced
  final String name;
  final String description;
  final double price;
  final String category; // matches a Category.name from CategoryStore
  final String emoji; // placeholder visual token used by the 3D card face
  final String? imageUrl; // public Supabase Storage URL, if a photo was uploaded
  final Uint8List? imageBytes; // freshly-picked photo not yet uploaded (admin form only)
  final List<String> tags;

  // Extra "product details" surfaced in the detail view. All optional with
  // sensible defaults so nothing above breaks and every card stays cheap
  // to build in the grid — this data is only read when a shopper opens
  // the detail sheet for one product at a time.
  final String story; // a short one-line "why it's special" note
  final List<String> highlights; // 2-4 short tasting/quality notes
  final List<String> ingredients;
  final List<String> allergens;
  final int calories;
  final int prepMinutes;
  final double rating; // out of 5
  final int reviewCount;

  const Product({
    this.id = '',
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.emoji,
    this.imageUrl,
    this.imageBytes,
    this.tags = const [],
    this.story = '',
    this.highlights = const [],
    this.ingredients = const [],
    this.allergens = const [],
    this.calories = 0,
    this.prepMinutes = 0,
    this.rating = 4.8,
    this.reviewCount = 0,
  });

  /// Row payload for Supabase insert/update (excludes `id` — the database
  /// generates/owns that).
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'emoji': emoji,
        'image_url': imageUrl,
        'tags': tags,
        'story': story,
        'highlights': highlights,
        'ingredients': ingredients,
        'allergens': allergens,
        'calories': calories,
        'prep_minutes': prepMinutes,
        'rating': rating,
        'review_count': reviewCount,
      };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        category: m['category'] as String? ?? '',
        emoji: m['emoji'] as String? ?? '',
        imageUrl: m['image_url'] as String?,
        tags: List<String>.from(m['tags'] as List? ?? const []),
        story: m['story'] as String? ?? '',
        highlights: List<String>.from(m['highlights'] as List? ?? const []),
        ingredients: List<String>.from(m['ingredients'] as List? ?? const []),
        allergens: List<String>.from(m['allergens'] as List? ?? const []),
        calories: (m['calories'] as num?)?.toInt() ?? 0,
        prepMinutes: (m['prep_minutes'] as num?)?.toInt() ?? 0,
        rating: (m['rating'] as num?)?.toDouble() ?? 4.8,
        reviewCount: (m['review_count'] as num?)?.toInt() ?? 0,
      );

  Product copyWith({String? id}) => Product(
        id: id ?? this.id,
        name: name,
        description: description,
        price: price,
        category: category,
        emoji: emoji,
        imageUrl: imageUrl,
        imageBytes: imageBytes,
        tags: tags,
        story: story,
        highlights: highlights,
        ingredients: ingredients,
        allergens: allergens,
        calories: calories,
        prepMinutes: prepMinutes,
        rating: rating,
        reviewCount: reviewCount,
      );
}

/// Product catalog backed by the Supabase `products` table. The storefront
/// (`HomeScreen`) reads `ProductStore.products` to render the menu, and the
/// admin dashboard writes to it when a product is added, edited, or
/// deleted — every write round-trips through Supabase first, then updates
/// the local `ValueNotifier` so the UI stays in sync everywhere that
/// listens to it.
class ProductStore {
  ProductStore._();

  static final ValueNotifier<List<Product>> products = ValueNotifier<List<Product>>([]);
  static final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);
  static bool _loaded = false;

  /// Fetches the full catalog from Supabase and replaces the local list.
  static Future<void> loadAll() async {
    try {
      final rows = await SupabaseConfig.client
          .from('products')
          .select()
          .order('created_at');
      products.value = (rows as List).map((r) => Product.fromMap(r as Map<String, dynamic>)).toList();
      _loaded = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads once per app session; safe to call from every screen that needs
  /// the catalog without re-fetching on every rebuild.
  static Future<void> ensureLoaded() async {
    if (!_loaded) await loadAll();
  }

  /// Inserts a new product and appends the server-confirmed row (with its
  /// generated id) to the local list.
  static Future<void> add(Product product) async {
    final row = await SupabaseConfig.client
        .from('products')
        .insert(product.toMap())
        .select()
        .single();
    products.value = [...products.value, Product.fromMap(row)];
  }

  /// Saves changes to an existing product (matched by `product.id`).
  static Future<void> update(Product product) async {
    final row = await SupabaseConfig.client
        .from('products')
        .update(product.toMap())
        .eq('id', product.id)
        .select()
        .single();
    final updated = Product.fromMap(row);
    products.value = [
      for (final p in products.value) if (p.id == product.id) updated else p,
    ];
  }

  /// Removes the product with the given [id] from the catalog.
  static Future<void> removeById(String id) async {
    await SupabaseConfig.client.from('products').delete().eq('id', id);
    products.value = products.value.where((p) => p.id != id).toList();
  }
}
