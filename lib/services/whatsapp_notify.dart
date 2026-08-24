import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import 'store_settings.dart';

/// Sends new-order details to the owner over WhatsApp using a plain
/// `wa.me` deep link (no WhatsApp Business API / no token needed) — it
/// just opens a WhatsApp chat with the message pre-filled, and the owner
/// taps send. Works the same on web, mobile, and desktop.
class WhatsAppNotify {
  WhatsAppNotify._();

  /// Builds the wa.me link for a placed [order] and opens it in a new
  /// tab/WhatsApp app. Best-effort: if it fails to launch (e.g. popup
  /// blocked) or the owner hasn't set a WhatsApp number yet from the
  /// dashboard's Settings tab, it's silently ignored so it never blocks
  /// checkout.
  static Future<void> sendOrder(Order order) async {
    final ownerPhone = StoreSettingsStore.settings.value.whatsappNumber;
    if (ownerPhone.isEmpty) return;
    final message = _buildMessage(order);
    final uri = Uri.parse(
      'https://wa.me/$ownerPhone?text=${Uri.encodeComponent(message)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Non-fatal — the order is already saved in Supabase regardless.
    }
  }

  static String _buildMessage(Order order) {
    final buffer = StringBuffer()
      ..writeln('💄 *New order — Ellora Cosmetics*')
      ..writeln()
      ..writeln('*Name:* ${order.fullName}')
      ..writeln('*Phone:* ${order.phone}')
      ..writeln('*Address:* ${order.address}')
      ..writeln('*Payment:* ${_paymentLabel(order.paymentMethod)}')
      ..writeln()
      ..writeln('*Items:*');

    for (final item in order.items) {
      buffer.writeln('• ${item.productName} x${item.quantity} — ${_egp(item.lineTotal)}');
    }

    buffer
      ..writeln()
      ..writeln('*Total: ${_egp(order.total)}*');

    return buffer.toString();
  }

  static String _paymentLabel(String method) {
    switch (method) {
      case 'vodafone_cash':
        return 'Vodafone Cash';
      case 'instapay':
        return 'InstaPay';
      case 'cod':
      default:
        return 'Cash on delivery';
    }
  }

  static String _egp(double amount) => 'EGP ${amount.toStringAsFixed(2)}';
}
