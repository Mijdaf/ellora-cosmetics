import 'package:flutter/foundation.dart';

import '../services/supabase_config.dart';
import 'product.dart';

/// A single line within a placed order — a snapshot of one cart item's
/// name/price/quantity at the moment of checkout (kept separate from
/// [Product] so a later catalog edit never changes a past order's total).
class OrderItem {
  final String productName;
  final double unitPrice;
  final int quantity;

  const OrderItem({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;

  factory OrderItem.fromCartItem(CartItem item) => OrderItem(
        productName: item.product.name,
        unitPrice: item.product.price,
        quantity: item.quantity,
      );

  Map<String, dynamic> toMap() => {
        'product_name': productName,
        'unit_price': unitPrice,
        'quantity': quantity,
      };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productName: m['product_name'] as String? ?? '',
        unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0,
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
      );
}

/// A customer's placed order, captured at checkout and stored in the
/// Supabase `orders` table so it survives reloads and is visible to the
/// admin from any device/session.
class Order {
  final String id; // '' until the row is written and Supabase assigns one
  final String fullName;
  final String phone;
  final String address;
  final String paymentMethod; // 'cod' | 'vodafone_cash' | 'instapay'
  final bool isCompleted;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;

  const Order({
    this.id = '',
    required this.fullName,
    required this.phone,
    required this.address,
    this.paymentMethod = 'cod',
    this.isCompleted = false,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  Order copyWith({bool? isCompleted}) => Order(
        id: id,
        fullName: fullName,
        phone: phone,
        address: address,
        paymentMethod: paymentMethod,
        isCompleted: isCompleted ?? this.isCompleted,
        total: total,
        createdAt: createdAt,
        items: items,
      );

  /// Row payload for insert (the `id` and `created_at` columns are
  /// database-owned, so they're left out here).
  Map<String, dynamic> toMap() => {
        'full_name': fullName,
        'phone': phone,
        'address': address,
        'payment_method': paymentMethod,
        'is_completed': isCompleted,
        'total': total,
        'items': items.map((i) => i.toMap()).toList(),
      };

  factory Order.fromMap(Map<String, dynamic> m) => Order(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        address: m['address'] as String? ?? '',
        paymentMethod: m['payment_method'] as String? ?? 'cod',
        isCompleted: m['is_completed'] as bool? ?? false,
        total: (m['total'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        items: (m['items'] as List? ?? const [])
            .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
            .toList(),
      );
}

/// Orders backed by the Supabase `orders` table. The checkout dialog on
/// `CartScreen` inserts a new row here when a customer places an order;
/// the admin dashboard's Orders section listens to `OrderStore.orders` to
/// show them live and lets the owner mark one done or remove it — same
/// pattern as `ProductStore` and `HomeBannerStore`.
class OrderStore {
  OrderStore._();

  static final ValueNotifier<List<Order>> orders = ValueNotifier<List<Order>>([]);
  static bool _loaded = false;

  static Future<void> loadAll() async {
    final rows = await SupabaseConfig.client
        .from('orders')
        .select()
        .order('created_at', ascending: false);
    orders.value = (rows as List).map((r) => Order.fromMap(r as Map<String, dynamic>)).toList();
    _loaded = true;
  }

  static Future<void> ensureLoaded() async {
    if (!_loaded) await loadAll();
  }

  /// Writes a newly placed order. Deliberately does NOT chain `.select()`
  /// after the insert: PostgREST needs a SELECT-RLS pass to return the
  /// inserted row, and the customer placing the order (anon role) has no
  /// SELECT policy on `orders` on purpose — letting anon read rows back
  /// would let any shopper page through every other customer's name,
  /// phone, and address. The generated `id`/`created_at` aren't needed by
  /// the checkout flow, so we just add the locally-built order (the admin
  /// dashboard gets the real row, id included, via its own `loadAll()`).
  static Future<void> add(Order order) async {
    await SupabaseConfig.client.from('orders').insert(order.toMap());
    orders.value = [order, ...orders.value];
  }

  /// Flips (or explicitly sets) the completed state of the order with
  /// the given [id].
  static Future<void> setCompleted(String id, bool isCompleted) async {
    await SupabaseConfig.client
        .from('orders')
        .update({'is_completed': isCompleted})
        .eq('id', id);
    orders.value = [
      for (final o in orders.value)
        if (o.id == id) o.copyWith(isCompleted: isCompleted) else o,
    ];
  }

  /// Removes the order with the given [id] from the dashboard.
  static Future<void> removeById(String id) async {
    await SupabaseConfig.client.from('orders').delete().eq('id', id);
    orders.value = orders.value.where((o) => o.id != id).toList();
  }
}
