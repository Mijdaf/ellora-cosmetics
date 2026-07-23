import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../services/supabase_config.dart';

/// A single slide in the promotional banner strip near the top of Home
/// (seasonal offers, new drops, "free delivery" announcements, etc).
/// Owner-managed from the admin dashboard; the photo lives in the
/// `banner-images` Supabase Storage bucket and this row just points at it.
class HomeBanner {
  final String id;
  final String imageUrl;
  final int position;

  const HomeBanner({required this.id, required this.imageUrl, this.position = 0});

  factory HomeBanner.fromMap(Map<String, dynamic> m) => HomeBanner(
        id: m['id'] as String,
        imageUrl: m['image_url'] as String,
        position: (m['position'] as num?)?.toInt() ?? 0,
      );
}

/// Banner strip backed by the Supabase `banners` table. The storefront
/// (`HomeScreen`) listens to `HomeBannerStore.banners` to render the
/// slideshow, and the admin dashboard writes to it when a banner is
/// added, reordered, or removed — same live-sync pattern as
/// `ProductStore`.
class HomeBannerStore {
  HomeBannerStore._();

  static final ValueNotifier<List<HomeBanner>> banners = ValueNotifier<List<HomeBanner>>([]);
  static bool _loaded = false;

  static Future<void> loadAll() async {
    final rows = await SupabaseConfig.client
        .from('banners')
        .select()
        .order('position');
    banners.value = (rows as List).map((r) => HomeBanner.fromMap(r as Map<String, dynamic>)).toList();
    _loaded = true;
  }

  static Future<void> ensureLoaded() async {
    if (!_loaded) await loadAll();
  }

  /// Uploads [imageBytes] to Storage, then adds a new banner row pointing
  /// at it to the end of the strip.
  static Future<void> addFromBytes(Uint8List imageBytes) async {
    final url = await SupabaseConfig.uploadImage(
      bucket: 'banner-images',
      bytes: imageBytes,
      fileExt: 'jpg',
    );
    final position = banners.value.length;
    final row = await SupabaseConfig.client
        .from('banners')
        .insert({'image_url': url, 'position': position})
        .select()
        .single();
    banners.value = [...banners.value, HomeBanner.fromMap(row)];
  }

  /// Removes the banner with the given [id].
  static Future<void> removeById(String id) async {
    await SupabaseConfig.client.from('banners').delete().eq('id', id);
    banners.value = banners.value.where((b) => b.id != id).toList();
  }

  /// Persists a new order (used after a drag-to-reorder) by writing each
  /// banner's new `position`. Updates the local list immediately
  /// (optimistic) then syncs positions in the background.
  static Future<void> reorder(List<HomeBanner> newOrder) async {
    banners.value = List<HomeBanner>.from(newOrder);
    for (var i = 0; i < newOrder.length; i++) {
      await SupabaseConfig.client
          .from('banners')
          .update({'position': i})
          .eq('id', newOrder[i].id);
    }
  }
}
