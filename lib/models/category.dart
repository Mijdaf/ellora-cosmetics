import 'package:flutter/foundation.dart';

import '../services/supabase_config.dart';

/// Best-effort Arabic label for a handful of very common bakery category
/// names, so a category the owner typed in English (e.g. "Cakes") still
/// reads naturally instead of sitting in Latin script inside an otherwise
/// fully-Arabic storefront. This only changes what's *displayed* — the
/// stored category name (used for matching products) is untouched, and
/// anything not in this short list falls back to the name as typed.
String categoryDisplayName(String name, bool isArabic) {
  if (!isArabic) return name;
  const known = {
    'cakes': 'كيك',
    'cake': 'كيك',
    'bread': 'خبز',
    'breads': 'خبز',
    'pastries': 'معجنات',
    'pastry': 'معجنات',
    'croissants': 'كرواسون',
    'croissant': 'كرواسون',
    'coffee': 'قهوة',
    'cookies': 'كوكيز',
    'cookie': 'كوكيز',
    'donuts': 'دوناتس',
    'donut': 'دوناتس',
    'cupcakes': 'كب كيك',
    'cupcake': 'كب كيك',
    'sweets': 'حلويات',
    'desserts': 'حلويات',
    'drinks': 'مشروبات',
    'beverages': 'مشروبات',
  };
  return known[name.trim().toLowerCase()] ?? name;
}

/// A single product category (e.g. "Pastries", "Cakes"). Fully owner-managed
/// from the admin dashboard — there is no fixed/hardcoded list baked into
/// the app. Products store the category's `name` as free text, so renaming
/// a category here does not automatically rename it on existing products.
class Category {
  final String id;
  final String name;
  final int position;

  const Category({required this.id, required this.name, this.position = 0});

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        position: (m['position'] as num?)?.toInt() ?? 0,
      );
}

/// Category list backed by the Supabase `categories` table. The storefront
/// (`HomeScreen`) listens to `CategoryStore.categories` to render the
/// filter chips, and the admin dashboard writes to it when the owner adds
/// or removes a category — same live-sync pattern as `ProductStore` and
/// `HomeBannerStore`.
class CategoryStore {
  CategoryStore._();

  static final ValueNotifier<List<Category>> categories = ValueNotifier<List<Category>>([]);
  static bool _loaded = false;

  static Future<void> loadAll() async {
    final rows = await SupabaseConfig.client
        .from('categories')
        .select()
        .order('position');
    categories.value = (rows as List).map((r) => Category.fromMap(r as Map<String, dynamic>)).toList();
    _loaded = true;
  }

  static Future<void> ensureLoaded() async {
    if (!_loaded) await loadAll();
  }

  /// Adds a new category with the given [name] to the end of the list.
  static Future<void> add(String name) async {
    final position = categories.value.length;
    final row = await SupabaseConfig.client
        .from('categories')
        .insert({'name': name, 'position': position})
        .select()
        .single();
    categories.value = [...categories.value, Category.fromMap(row)];
  }

  /// Removes the category with the given [id]. Products already tagged
  /// with its name keep that text value — they just won't match any
  /// filter chip until the owner edits them to a current category.
  static Future<void> removeById(String id) async {
    await SupabaseConfig.client.from('categories').delete().eq('id', id);
    categories.value = categories.value.where((c) => c.id != id).toList();
  }
}
