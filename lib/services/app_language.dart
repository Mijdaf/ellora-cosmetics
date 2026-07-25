import 'package:flutter/material.dart';

/// Global *storefront* language switch — English (default) or Arabic.
///
/// Mirrors the `AppMood` pattern in `app_theme.dart`: a single
/// `ValueNotifier` that any widget can listen to with a
/// `ValueListenableBuilder`, so toggling it only rebuilds the small
/// subtree that actually cares, not the whole app.
///
/// Deliberately storefront-only: the admin dashboard never reads this
/// notifier, so it always stays in English for the owner no matter what
/// language a shopper has selected on the public site.
class AppLanguage {
  AppLanguage._();
  static final ValueNotifier<bool> isArabic = ValueNotifier<bool>(false);
  static void toggle() => isArabic.value = !isArabic.value;
}

/// Storefront copy, in English and Arabic, keyed by a short identifier.
///
/// Usage: `S.t('menu', isArabic)` — pass whatever boolean you already got
/// from listening to `AppLanguage.isArabic`, so widgets don't need to read
/// the notifier a second time just to translate a string.
class S {
  S._();

  static const Map<String, String> _en = {
    // Nav bar
    'nav_menu': 'Menu',
    'nav_about': 'About',
    'nav_locations': 'Locations',
    'cart_empty': 'Your cart is empty',
    'cart_items_one': '1 item in cart',
    'cart_items_other': '%d items in cart',
    'subtotal': 'Subtotal',
    'browse_menu': 'Browse menu',
    'view_cart': 'View cart',
    'you_might_also_like': 'You might also like',
    'delivery_estimate': 'Estimated delivery within 2–4 business days',
    'continue_shopping': 'Continue shopping',

    // Hero
    'hero_eyebrow': 'BAKED WITH LOVE, DAILY',
    'hero_headline': 'Fresh Croissants, Pancakes\n& Pastries — Every Morning',
    'hero_body': 'Every loaf, roll and croissant at Nafas is laminated, '
        'proofed and baked in small batches — so what reaches your table '
        'still feels warm from the oven.',
    'explore_menu': 'Explore the Menu',
    'visit_us': 'Visit Us',

    // Menu section
    'baked_fresh_every_day': 'BAKED FRESH EVERY DAY',
    'our_fresh_menu': 'Our Fresh Menu',
    'all': 'All',
    'search_products': 'Search products…',
    'no_products_found': 'No products match your search.',

    // Story banner
    'story_quote':
        '"Nafas" means breath — the pause after the first bite\nof something baked slowly, and with care.',
    'our_story': 'Our Story',

    // Footer
    'baked_with_love': 'BAKED WITH LOVE',
    'footer_tagline':
        'Small-batch pastries, bread and coffee — baked fresh every morning, shared with warmth.',
    'quick_links': 'QUICK LINKS',
    'about_us': 'About Us',
    'contact': 'Contact',
    'copyright': '© 2026 Nafas Bakery. All rights reserved.',
    'made_with_care': 'Made with care, one loaf at a time.',

    // Cart screen
    'your_cart': 'Your Cart',
    'cart_empty_body': 'Add some fresh pastries to get started.',
    'remove': 'Remove',
    'checkout': 'Checkout',
    'each': 'each',

    // Checkout dialog
    'checkout_title': 'Checkout',
    'full_name': 'Full name',
    'phone_number': 'Phone number',
    'delivery_address': 'Delivery address',
    'payment_method': 'Payment method',
    'cash_on_delivery': 'Cash on delivery',
    'vodafone_cash': 'Vodafone Cash',
    'instapay': 'InstaPay',
    'cancel': 'Cancel',
    'place_order': 'Place order',
    'required': 'Required',
    'order_placed': 'Order placed — thank you!',
    'could_not_place_order': 'Could not place order',
    'item_one': 'item',
    'item_other': 'items',
    'pay_via_instapay': 'Pay via InstaPay',
    'pay_via_vodafone_cash': 'Send via Vodafone Cash',
    'vodafone_cash_send_to': 'Send to: %s',
    'number_copied': 'Number copied',
    'send_whatsapp_title': 'One last step',
    'send_whatsapp_body':
        'We\'ve opened WhatsApp with your order details filled in — just tap Send to confirm your order with us.',
    'got_it': 'Got it',

    // Product detail
    'added_to_cart': 'Added to cart',
    'add': 'Add',
    'add_to_cart': 'Add to cart',
    'ingredients': 'INGREDIENTS',
  };

  static const Map<String, String> _ar = {
    // Nav bar
    'nav_menu': 'القائمة',
    'nav_about': 'من نحن',
    'nav_locations': 'الفروع',
    'cart_empty': 'سلتك فارغة',
    'cart_items_one': 'قطعة واحدة في السلة',
    'cart_items_other': '%d قطع في السلة',
    'subtotal': 'الإجمالي',
    'browse_menu': 'تصفح القائمة',
    'view_cart': 'عرض السلة',
    'you_might_also_like': 'قد يعجبك أيضًا',
    'delivery_estimate': 'التوصيل المتوقع خلال 2–4 أيام عمل',
    'continue_shopping': 'إكمال التسوق',

    // Hero
    'hero_eyebrow': 'يُخبز بحب، يوميًا',
    'hero_headline': 'كرواسون وبان كيك\nومعجنات طازجة كل صباح',
    'hero_body':
        'كل رغيف وقطعة كرواسون في نفس تُعجن وتُخبز بدفعات صغيرة — لتصل إلى مائدتك وهي لا تزال دافئة من الفرن.',
    'explore_menu': 'تصفح القائمة',
    'visit_us': 'زورونا',

    // Menu section
    'baked_fresh_every_day': 'يُخبز طازجًا كل يوم',
    'our_fresh_menu': 'قائمتنا الطازجة',
    'all': 'الكل',
    'search_products': 'ابحث عن منتج…',
    'no_products_found': 'لا توجد منتجات مطابقة لبحثك.',

    // Story banner
    'story_quote': '"نفس" تعني التنفّس — تلك اللحظة بعد أول قضمة\nمن شيء خُبز ببطء وعناية.',
    'our_story': 'قصتنا',

    // Footer
    'baked_with_love': 'يُخبز بحب',
    'footer_tagline': 'معجنات وخبز وقهوة بدفعات صغيرة — تُخبز طازجة كل صباح، وتُقدَّم بدفء.',
    'quick_links': 'روابط سريعة',
    'about_us': 'من نحن',
    'contact': 'تواصل معنا',
    'copyright': '© 2026 مخبز نفس. جميع الحقوق محفوظة.',
    'made_with_care': 'يُصنع بعناية، رغيفًا تلو الآخر.',

    // Cart screen
    'your_cart': 'سلتك',
    'cart_empty_body': 'أضف بعض المعجنات الطازجة للبدء.',
    'remove': 'إزالة',
    'checkout': 'إتمام الطلب',
    'each': 'للقطعة',

    // Checkout dialog
    'checkout_title': 'إتمام الطلب',
    'full_name': 'الاسم بالكامل',
    'phone_number': 'رقم الهاتف',
    'delivery_address': 'عنوان التوصيل',
    'payment_method': 'طريقة الدفع',
    'cash_on_delivery': 'الدفع عند الاستلام',
    'vodafone_cash': 'فودافون كاش',
    'instapay': 'إنستاباي',
    'cancel': 'إلغاء',
    'place_order': 'تأكيد الطلب',
    'required': 'مطلوب',
    'order_placed': 'تم تأكيد الطلب — شكرًا لك!',
    'could_not_place_order': 'تعذر إتمام الطلب',
    'item_one': 'قطعة',
    'item_other': 'قطع',
    'pay_via_instapay': 'ادفع عبر إنستاباي',
    'pay_via_vodafone_cash': 'حوّل عبر فودافون كاش',
    'vodafone_cash_send_to': 'حوّل إلى: %s',
    'number_copied': 'تم نسخ الرقم',
    'send_whatsapp_title': 'خطوة أخيرة',
    'send_whatsapp_body': 'فتحنا لك واتساب برسالة جاهزة بتفاصيل طلبك — اضغط إرسال لتأكيد طلبك معنا.',
    'got_it': 'تمام',

    // Product detail
    'added_to_cart': 'أُضيف إلى السلة',
    'add': 'إضافة',
    'add_to_cart': 'أضف إلى السلة',
    'ingredients': 'المكونات',
  };

  static String t(String key, bool ar) {
    final map = ar ? _ar : _en;
    return map[key] ?? _en[key] ?? key;
  }
}
