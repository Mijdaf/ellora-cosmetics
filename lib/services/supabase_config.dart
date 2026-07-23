import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Central place for the Supabase project credentials and a couple of
/// tiny helpers used by the admin login flow and image uploads.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://cgiqtrvzjymlmsxktpyi.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnaXF0cnZ6anltbG1zeGt0cHlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQzNTY5MzUsImV4cCI6MjA5OTkzMjkzNX0.zxrEiSJyzVRKeGT7X-H3EDp5bSBVWXmAQ_BikX4X8Tg';

  static Future<void>? _readyFuture;

  /// Call once before `runApp`. Safe to call without awaiting — kicks off
  /// initialization and lets [ready] be awaited later by whichever screen
  /// needs the client first.
  static Future<void> init() {
    _readyFuture ??= Supabase.initialize(url: url, anonKey: anonKey);
    return _readyFuture!;
  }

  /// Await this before touching [client] on any screen that isn't
  /// guaranteed to load after the splash screen's delay (e.g. a direct
  /// deep link straight to `/admin`).
  static Future<void> get ready => _readyFuture ?? init();

  static SupabaseClient get client => Supabase.instance.client;

  /// True while a user session is active (i.e. the admin is logged in).
  static bool get isLoggedIn => client.auth.currentSession != null;

  /// Uploads [bytes] to the given Storage [bucket] under a fresh
  /// timestamp-based filename and returns its public URL. Used for both
  /// product photos (`product-images`) and banner photos (`banner-images`)
  /// — both buckets are public-read/admin-write (see the SQL setup).
  static Future<String> uploadImage({
    required String bucket,
    required Uint8List bytes,
    String fileExt = 'jpg',
  }) async {
    final path = '${DateTime.now().microsecondsSinceEpoch}.$fileExt';
    await client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
