import 'package:flutter/material.dart';

/// Looks at the first strong (script-bearing) character in [text] and
/// reports whether it's Arabic script — covers the main Arabic block plus
/// the supplement and presentation-forms blocks, which is enough for
/// product names/descriptions typed by the owner.
bool isArabicText(String text) {
  for (final rune in text.runes) {
    final isArabicRune = (rune >= 0x0600 && rune <= 0x06FF) || // Arabic
        (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement
        (rune >= 0xFB50 && rune <= 0xFDFF) || // Arabic Presentation Forms-A
        (rune >= 0xFE70 && rune <= 0xFEFF); // Arabic Presentation Forms-B
    final isLatinRune = (rune >= 0x0041 && rune <= 0x007A);
    if (isArabicRune) return true;
    if (isLatinRune) return false;
    // Digits, spaces, punctuation aren't "strong" — keep scanning.
  }
  return false;
}

/// Text direction to use for owner-entered content (product name,
/// description, story…) based on what script it's actually written in,
/// rather than the shopper's current EN/AR toggle — so an Arabic product
/// name still reads right-to-left even while the storefront UI is in
/// English, and vice versa.
TextDirection autoTextDirection(String text) => isArabicText(text) ? TextDirection.rtl : TextDirection.ltr;

/// Matching text alignment for the same auto-detected direction.
TextAlign autoTextAlign(String text) => isArabicText(text) ? TextAlign.right : TextAlign.left;
