import 'dart:async';

import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/app_language.dart';
import '../services/whatsapp_notify.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';

/// Full shopping-cart screen. Reads a live [CartItem] list from the caller
/// and reports changes back up through callbacks — the screen itself holds
/// no cart state, so it always reflects whatever is currently in the cart
/// on the home screen, even if the user backgrounds/returns to it.
class CartScreen extends StatelessWidget {
  final List<CartItem> items;
  final bool isDark;
  final bool isArabic;
  final void Function(Product product, int quantity) onQuantityChanged;
  final void Function(Product product) onRemove;
  final VoidCallback onContinueShopping;
  // Called once an order has been placed (checkout form submitted), so the
  // caller (HomeScreen) can clear the live cart it owns.
  final VoidCallback onOrderPlaced;

  const CartScreen({
    super.key,
    required this.items,
    required this.isDark,
    required this.isArabic,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onContinueShopping,
    required this.onOrderPlaced,
  });

  double get _subtotal => items.fold(0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.espressoDark : AppColors.surfaceCream;
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        title: Text(
          S.t('your_cart', isArabic),
          style: TextStyle(fontFamily: AppTheme.fontFor(isArabic), fontWeight: FontWeight.w600, fontSize: 22, color: textColor),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: AnimatedBackground(isDark: isDark)),
          items.isEmpty
              ? _EmptyCart(isDark: isDark, isArabic: isArabic, onContinueShopping: onContinueShopping)
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, i) => _CartTile(
                            item: items[i],
                            isDark: isDark,
                            isArabic: isArabic,
                            onQuantityChanged: (qty) => onQuantityChanged(items[i].product, qty),
                            onRemove: () => onRemove(items[i].product),
                          ),
                        ),
                      ),
                      _CartSummary(
                        subtotal: _subtotal,
                        isDark: isDark,
                        isArabic: isArabic,
                        items: items,
                        onOrderPlaced: onOrderPlaced,
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final bool isDark;
  final bool isArabic;
  final VoidCallback onContinueShopping;
  const _EmptyCart({required this.isDark, required this.isArabic, required this.onContinueShopping});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.wheatGold.withOpacity(0.7)),
          const SizedBox(height: 18),
          Text(
            S.t('cart_empty', isArabic),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            S.t('cart_empty_body', isArabic),
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onContinueShopping,
            child: Text(S.t('browse_menu', isArabic)),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  final bool isDark;
  final bool isArabic;
  final void Function(int quantity) onQuantityChanged;
  final VoidCallback onRemove;

  const _CartTile({
    required this.item,
    required this.isDark,
    required this.isArabic,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    final subColor = isDark ? AppColors.cream.withOpacity(0.6) : AppColors.espressoDark.withOpacity(0.6);
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : AppColors.surfaceCream;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.wheatGold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(item.product.emoji, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatEGP(item.product.price)} ${S.t('each', isArabic)}',
                  style: TextStyle(fontSize: 12.5, color: subColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _QtyControl(
                qty: item.quantity,
                isDark: isDark,
                onChanged: onQuantityChanged,
              ),
              const SizedBox(height: 8),
              Text(
                formatEGP(item.total),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.wheatGoldDark),
              ),
            ],
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, size: 18, color: subColor),
            tooltip: S.t('remove', isArabic),
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final bool isDark;
  final void Function(int quantity) onChanged;
  const _QtyControl({required this.qty, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniButton(icon: Icons.remove_rounded, color: textColor, onTap: () => onChanged(qty - 1)),
          SizedBox(
            width: 22,
            child: Text('$qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textColor)),
          ),
          _MiniButton(icon: Icons.add_rounded, color: textColor, onTap: () => onChanged(qty + 1)),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MiniButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double subtotal;
  final bool isDark;
  final bool isArabic;
  final List<CartItem> items;
  final VoidCallback onOrderPlaced;
  const _CartSummary({
    required this.subtotal,
    required this.isDark,
    required this.isArabic,
    required this.items,
    required this.onOrderPlaced,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.espressoDeep : AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.t('subtotal', isArabic), style: TextStyle(fontSize: 15, color: textColor.withOpacity(0.75))),
                Text(
                  formatEGP(subtotal),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _CheckoutDialog(
                    items: items,
                    subtotal: subtotal,
                    isDark: isDark,
                    isArabic: isArabic,
                    onOrderPlaced: () {
                      onOrderPlaced();
                      Navigator.of(context).pop(); // close cart, back to the storefront
                    },
                  ),
                ),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(S.t('checkout', isArabic)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collects the customer's name, phone, address, and payment method, then
/// writes an [Order] into `OrderStore` — the in-memory list the admin
/// dashboard's Orders section reads from.
class _CheckoutDialog extends StatefulWidget {
  final List<CartItem> items;
  final double subtotal;
  final bool isDark;
  final bool isArabic;
  final VoidCallback onOrderPlaced;

  const _CheckoutDialog({
    required this.items,
    required this.subtotal,
    required this.isDark,
    required this.isArabic,
    required this.onOrderPlaced,
  });

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _paymentMethod = 'cod';
  bool _placing = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _placing = true);
    final order = Order(
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      paymentMethod: _paymentMethod,
      total: widget.subtotal,
      createdAt: DateTime.now(),
      items: widget.items.map(OrderItem.fromCartItem).toList(),
    );
    try {
      await OrderStore.add(order);
      // Best-effort: opens a wa.me link with the order details pre-filled
      // so the owner just has to tap send — no API/token involved. Never
      // blocks or fails the checkout if it can't open.
      unawaited(WhatsAppNotify.sendOrder(order));
      if (!mounted) return;
      Navigator.of(context).pop(); // close the checkout dialog itself
      widget.onOrderPlaced();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t('order_placed', widget.isArabic))),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.t('could_not_place_order', widget.isArabic)}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppColors.cream : AppColors.espressoDeep;
    return Dialog(
      backgroundColor: widget.isDark ? AppColors.espressoDark : AppColors.cream,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.t('checkout_title', widget.isArabic), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 4),
                Text(
                  '${widget.items.length} ${widget.items.length == 1 ? S.t('item_one', widget.isArabic) : S.t('item_other', widget.isArabic)} · ${formatEGP(widget.subtotal)}',
                  style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6)),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _name,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(labelText: S.t('full_name', widget.isArabic)),
                          validator: (v) => (v == null || v.trim().isEmpty) ? S.t('required', widget.isArabic) : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: S.t('phone_number', widget.isArabic)),
                          validator: (v) => (v == null || v.trim().isEmpty) ? S.t('required', widget.isArabic) : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _address,
                          style: TextStyle(color: textColor),
                          maxLines: 2,
                          decoration: InputDecoration(labelText: S.t('delivery_address', widget.isArabic)),
                          validator: (v) => (v == null || v.trim().isEmpty) ? S.t('required', widget.isArabic) : null,
                        ),
                        const SizedBox(height: 16),
                        Text(S.t('payment_method', widget.isArabic), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                        RadioListTile<String>(
                          value: 'cod',
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v ?? 'cod'),
                          title: Text(S.t('cash_on_delivery', widget.isArabic), style: TextStyle(fontSize: 13.5, color: textColor)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        RadioListTile<String>(
                          value: 'vodafone_cash',
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v ?? 'cod'),
                          title: Text(S.t('vodafone_cash', widget.isArabic), style: TextStyle(fontSize: 13.5, color: textColor)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        RadioListTile<String>(
                          value: 'instapay',
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v ?? 'cod'),
                          title: Text(S.t('instapay', widget.isArabic), style: TextStyle(fontSize: 13.5, color: textColor)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _placing ? null : () => Navigator.of(context).pop(), child: Text(S.t('cancel', widget.isArabic))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _placing ? null : _placeOrder,
                      child: _placing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.espressoDeep),
                            )
                          : Text(S.t('place_order', widget.isArabic)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
