import 'package:flutter/foundation.dart';

import 'supabase_config.dart';

/// The owner-editable contact/payment settings shown to customers at
/// checkout: the WhatsApp number orders get sent to, the InstaPay payment
/// link, and the Vodafone Cash number. Backed by a single row in the
/// Supabase `store_settings` table so the owner can change these from the
/// admin dashboard's Settings tab — no code edits or app rebuild needed.
class StoreSettings {
  final String whatsappNumber;
  final String instapayLink;
  final String vodafoneCashNumber;

  const StoreSettings({
    required this.whatsappNumber,
    required this.instapayLink,
    required this.vodafoneCashNumber,
  });

  static const empty = StoreSettings(whatsappNumber: '', instapayLink: '', vodafoneCashNumber: '');

  factory StoreSettings.fromMap(Map<String, dynamic> m) => StoreSettings(
        whatsappNumber: (m['whatsapp_number'] as String?) ?? '',
        instapayLink: (m['instapay_link'] as String?) ?? '',
        vodafoneCashNumber: (m['vodafone_cash_number'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
        'whatsapp_number': whatsappNumber,
        'instapay_link': instapayLink,
        'vodafone_cash_number': vodafoneCashNumber,
      };
}

/// Single-row settings store, same live-sync pattern as `ProductStore` /
/// `HomeBannerStore`: the storefront listens to [settings] to build the
/// WhatsApp / InstaPay / Vodafone Cash links, and the admin dashboard's
/// Settings tab writes to it when the owner hits Save.
class StoreSettingsStore {
  StoreSettingsStore._();

  /// Fixed id for the single settings row (created once via the SQL
  /// snippet in the Settings tab's setup note).
  static const int _rowId = 1;

  static final ValueNotifier<StoreSettings> settings = ValueNotifier<StoreSettings>(StoreSettings.empty);
  static bool _loaded = false;

  static Future<void> loadAll() async {
    final rows = await SupabaseConfig.client
        .from('store_settings')
        .select()
        .eq('id', _rowId)
        .limit(1);
    final list = rows as List;
    settings.value = list.isEmpty ? StoreSettings.empty : StoreSettings.fromMap(list.first as Map<String, dynamic>);
    _loaded = true;
  }

  static Future<void> ensureLoaded() async {
    if (!_loaded) await loadAll();
  }

  /// Upserts the single settings row with new values and updates the
  /// local copy immediately.
  static Future<void> update(StoreSettings newSettings) async {
    await SupabaseConfig.client.from('store_settings').upsert({'id': _rowId, ...newSettings.toMap()});
    settings.value = newSettings;
  }
}
