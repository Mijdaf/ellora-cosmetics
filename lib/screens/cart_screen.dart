import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:url_launcher/url_launcher.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/app_language.dart';
import '../services/store_settings.dart';
import '../services/whatsapp_notify.dart';
import '../theme/app_theme.dart';

/// Cart shown as a centered modal dialog (via `showDialog`) instead of a
/// full page — closer to the popup-cart pattern shoppers expect. Reads a
/// live [CartItem] list from the caller and reports changes back up
/// through callbacks; the screen itself holds no cart state.
class CartScreen extends StatelessWidget {
  final List<CartItem> items;
  final bool isDark;
  final bool isArabic;
  final void Function(Product product, int quantity) onQuantityChanged;
  final void Function(Product product) onRemove;
  // Adds one unit of a product the shopper doesn't have yet — used by the
  // "You might also like" strip.
  final void Function(Product product) onAddProduct;
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
    required this.onAddProduct,
    required this.onContinueShopping,
    required this.onOrderPlaced,
  });

  double get _subtotal => items.fold(0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.espressoDark : AppColors.surfaceCream;
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: screenHeight * 0.86),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 40, offset: const Offset(0, 20))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small grab-handle, purely decorative — signals "this is a sheet".
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: textColor.withOpacity(0.18), borderRadius: BorderRadius.circular(4))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_rounded, size: 20, color: AppColors.wheatGoldDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S.t('your_cart', isArabic),
                        style: TextStyle(fontFamily: AppTheme.fontFor(isArabic), fontWeight: FontWeight.w700, fontSize: 19, color: textColor),
                      ),
                    ),
                    IconButton(
                      onPressed: onContinueShopping,
                      icon: Icon(Icons.close_rounded, color: textColor.withOpacity(0.8)),
                      tooltip: S.t('continue_shopping', isArabic),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),
              Flexible(
                child: items.isEmpty
                    ? _EmptyCart(isDark: isDark, isArabic: isArabic, onContinueShopping: onContinueShopping)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...List.generate(items.length, (i) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
                                child: _CartTile(
                                  item: items[i],
                                  isDark: isDark,
                                  isArabic: isArabic,
                                  onQuantityChanged: (qty) => onQuantityChanged(items[i].product, qty),
                                  onRemove: () => onRemove(items[i].product),
                                ),
                              );
                            }),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Icon(Icons.local_shipping_outlined, size: 15, color: textColor.withOpacity(0.6)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    S.t('delivery_estimate', isArabic),
                                    style: TextStyle(fontSize: 12.5, color: textColor.withOpacity(0.6)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _RecommendationsStrip(
                              isDark: isDark,
                              isArabic: isArabic,
                              excludeNames: items.map((c) => c.product.name).toSet(),
                              onAdd: onAddProduct,
                            ),
                          ],
                        ),
                      ),
              ),
              if (items.isNotEmpty)
                _CartSummary(
                  subtotal: _subtotal,
                  isDark: isDark,
                  isArabic: isArabic,
                  items: items,
                  onOrderPlaced: onOrderPlaced,
                  onContinueShopping: onContinueShopping,
                ),
            ],
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              color: AppColors.wheatGold.withOpacity(0.14),
              child: (item.product.imageUrl != null || item.product.imageBytes != null)
                  ? (item.product.imageUrl != null
                      ? Image.network(item.product.imageUrl!, fit: BoxFit.cover, width: 56, height: 56,
                          errorBuilder: (_, __, ___) => Text(item.product.emoji, style: const TextStyle(fontSize: 30)))
                      : Image.memory(item.product.imageBytes!, fit: BoxFit.cover, width: 56, height: 56))
                  : Text(item.product.emoji, style: const TextStyle(fontSize: 30)),
            ),
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
                if (item.product.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.product.description,
                    style: TextStyle(fontSize: 11.5, color: subColor.withOpacity(0.85)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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

/// "You might also like" horizontal strip — pulls from the live product
/// catalog, skipping anything already in the cart, and lets the shopper
/// add a suggestion straight from its quick-add "+" button.
class _RecommendationsStrip extends StatelessWidget {
  final bool isDark;
  final bool isArabic;
  final Set<String> excludeNames;
  final void Function(Product product) onAdd;
  const _RecommendationsStrip({
    required this.isDark,
    required this.isArabic,
    required this.excludeNames,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    return ValueListenableBuilder<List<Product>>(
      valueListenable: ProductStore.products,
      builder: (context, allProducts, __) {
        final suggestions = allProducts.where((p) => !excludeNames.contains(p.name)).take(8).toList();
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.t('you_might_also_like', isArabic),
              style: TextStyle(fontFamily: AppTheme.fontFor(isArabic), fontWeight: FontWeight.w700, fontSize: 15, color: textColor),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _RecommendationCard(
                  product: suggestions[i],
                  isDark: isDark,
                  onAdd: () => onAdd(suggestions[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Product product;
  final bool isDark;
  final VoidCallback onAdd;
  const _RecommendationCard({required this.product, required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : AppColors.surfaceCream;

    return Container(
      width: 128,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 90,
                width: double.infinity,
                child: (product.imageUrl != null || product.imageBytes != null)
                    ? (product.imageUrl != null
                        ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: AppColors.wheatGold.withOpacity(0.14), child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 30)))))
                        : Image.memory(product.imageBytes!, fit: BoxFit.cover))
                    : Container(color: AppColors.wheatGold.withOpacity(0.14), child: Center(child: Text(product.emoji, style: const TextStyle(fontSize: 30)))),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: AppColors.wheatGold,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onAdd,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.add_rounded, size: 14, color: AppColors.espressoDeep),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  formatEGP(product.price),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.wheatGoldDark),
                ),
              ],
            ),
          ),
        ],
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
  final VoidCallback onContinueShopping;
  const _CartSummary({
    required this.subtotal,
    required this.isDark,
    required this.isArabic,
    required this.items,
    required this.onOrderPlaced,
    required this.onContinueShopping,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.espressoDeep : AppColors.cream,
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
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
          const SizedBox(height: 6),
          TextButton(
            onPressed: onContinueShopping,
            child: Text(S.t('continue_shopping', isArabic), style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.7))),
          ),
        ],
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
  String _paymentMethod = 'vodafone_cash';
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
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context); // grabbed before popping, so it survives the dialog closing
      final cartContext = navigator.context;
      navigator.pop(); // close the checkout dialog itself
      widget.onOrderPlaced();
      messenger.showSnackBar(
        SnackBar(content: Text(S.t('order_placed', widget.isArabic))),
      );

      if (_paymentMethod == 'instapay') {
        // Send the customer to InstaPay to actually pay first. Auto-opening
        // WhatsApp right now (before they've paid) would just be noise, so
        // instead show a dialog with a "Send via WhatsApp" button they tap
        // themselves once they're back from paying.
        final link = StoreSettingsStore.settings.value.instapayLink;
        if (link.isNotEmpty) {
          try {
            await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
          } catch (_) {
            // Non-fatal — the order is already saved regardless.
          }
        }
        if (!cartContext.mounted) return;
        showDialog(
          context: cartContext,
          builder: (_) => _InstapayPaidDialog(order: order, isDark: widget.isDark, isArabic: widget.isArabic),
        );
      } else {
        // Best-effort: opens a wa.me link with the order details pre-filled
        // so the customer just has to tap send — no API/token involved.
        // Never blocks or fails the checkout if it can't open.
        unawaited(WhatsAppNotify.sendOrder(order));
        // Tell the customer WhatsApp is already open with their order
        // details filled in, so they know to tap Send there to confirm.
        showDialog(
          context: cartContext,
          builder: (_) => _SendWhatsAppReminderDialog(isDark: widget.isDark, isArabic: widget.isArabic),
        );
      }
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
                          value: 'vodafone_cash',
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v ?? 'vodafone_cash'),
                          title: Text(S.t('vodafone_cash', widget.isArabic), style: TextStyle(fontSize: 13.5, color: textColor)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        RadioListTile<String>(
                          value: 'instapay',
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v ?? 'vodafone_cash'),
                          title: Text(S.t('instapay', widget.isArabic), style: TextStyle(fontSize: 13.5, color: textColor)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        const SizedBox(height: 8),
                        _PayNowLink(paymentMethod: _paymentMethod, isArabic: widget.isArabic, textColor: textColor),
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

/// Shown under the payment-method radios once InstaPay or Vodafone Cash is
/// selected. InstaPay opens the owner's payment link directly; Vodafone
/// Cash has no universal deep link, so it just shows the number with a
/// tap-to-copy action — the customer sends the transfer themselves from
/// their own Vodafone Cash app, then taps "Place order". Both values come
/// live from `StoreSettingsStore`, which the owner edits from the
/// dashboard's Settings tab — nothing hardcoded here.
class _PayNowLink extends StatelessWidget {
  final String paymentMethod;
  final bool isArabic;
  final Color textColor;
  const _PayNowLink({required this.paymentMethod, required this.isArabic, required this.textColor});

  Future<void> _openInstapay(BuildContext context, String link) async {
    final uri = Uri.parse(link);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Non-fatal — the customer can still place the order and pay another way.
    }
  }

  Future<void> _copyVodafoneNumber(BuildContext context, String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.t('number_copied', isArabic))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInstapay = paymentMethod == 'instapay';
    return ValueListenableBuilder<StoreSettings>(
      valueListenable: StoreSettingsStore.settings,
      builder: (context, settings, __) {
        final link = settings.instapayLink;
        final number = settings.vodafoneCashNumber;
        // Not configured from the dashboard yet — nothing useful to show.
        if (isInstapay && link.isEmpty) return const SizedBox.shrink();
        if (!isInstapay && number.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.wheatGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          // The message and the action button used to sit in one Row. Once
          // the button's own label ("Send via Vodafone Cash" / "Pay via
          // InstaPay") claimed its width first, the Expanded message text
          // was left with almost no room — down to a sliver a single
          // character wide, so it wrapped one letter per line instead of
          // reading as a sentence. Stacking them (message on top, button
          // on its own line below) gives each the full container width, so
          // both wrap and align normally.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(isInstapay ? Icons.link_rounded : Icons.copy_rounded, size: 16, color: textColor.withOpacity(0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: isInstapay
                        ? Text(S.t('pay_via_instapay', isArabic), style: TextStyle(fontSize: 12.5, color: textColor))
                        : Text(
                            S.t('vodafone_cash_send_to', isArabic).replaceAll('%s', number),
                            style: TextStyle(fontSize: 12.5, color: textColor),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => isInstapay ? _openInstapay(context, link) : _copyVodafoneNumber(context, number),
                  child: Text(
                    isInstapay ? S.t('pay_via_instapay', isArabic) : S.t('pay_via_vodafone_cash', isArabic),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shown after a customer checks out with InstaPay: we've just sent them to
/// the owner's InstaPay link in another tab to actually pay. Unlike the
/// other payment methods, WhatsApp isn't auto-opened here — that would fire
/// before they've paid — so this gives them a button to send the order
/// details over WhatsApp themselves once they're back.
class _InstapayPaidDialog extends StatelessWidget {
  final Order order;
  final bool isDark;
  final bool isArabic;
  const _InstapayPaidDialog({required this.order, required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    return AlertDialog(
      backgroundColor: isDark ? AppColors.espressoDark : AppColors.cream,
      icon: const Icon(Icons.check_circle_rounded, color: AppColors.wheatGoldDark, size: 32),
      title: Text(
        S.t('instapay_paid_title', isArabic),
        style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        textAlign: TextAlign.center,
      ),
      content: Text(
        S.t('instapay_paid_body', isArabic),
        style: TextStyle(fontSize: 13.5, color: textColor.withOpacity(0.85)),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            unawaited(WhatsAppNotify.sendOrder(order));
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.chat_rounded, size: 18),
          label: Text(S.t('send_via_whatsapp', isArabic)),
        ),
      ],
    );
  }
}

/// Small confirmation dialog shown right after an order is placed,
/// reminding the customer that WhatsApp is already open (via
/// [WhatsAppNotify.sendOrder]) with their order details filled in, and
/// that they still need to tap Send there themselves.
class _SendWhatsAppReminderDialog extends StatelessWidget {
  final bool isDark;
  final bool isArabic;
  const _SendWhatsAppReminderDialog({required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    return AlertDialog(
      backgroundColor: isDark ? AppColors.espressoDark : AppColors.cream,
      icon: const Icon(Icons.chat_rounded, color: AppColors.wheatGoldDark, size: 32),
      title: Text(
        S.t('send_whatsapp_title', isArabic),
        style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        textAlign: TextAlign.center,
      ),
      content: Text(
        S.t('send_whatsapp_body', isArabic),
        style: TextStyle(fontSize: 13.5, color: textColor.withOpacity(0.85)),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.t('got_it', isArabic)),
        ),
      ],
    );
  }
}
