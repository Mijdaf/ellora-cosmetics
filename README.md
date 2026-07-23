# Nafas Bakery (نفَـس) — Flutter Web Storefront

A bakery storefront built in Flutter, styled from your logo's exact palette:

| Color | Hex | Sampled from |
|---|---|---|
| Espresso (background) | `#693720` | logo background |
| Wheat Gold | `#F9AF18` | wheat stalk / accents |
| Cream/White | `#FFFDF7` | wordmark |

**Fonts:** Poppins (Latin body/UI) + Cairo (Arabic brand moments), via `google_fonts`.

**Fonts (chosen to fit a bakery, not a corporate app):**
- **Fraunces** (soft-serif, editorial) — used for the "Nafas" wordmark and all headlines. Reads warm and handmade rather than generic.
- **Inter** — used for body copy, descriptions and UI chrome, so long text stays crisp and easy to read.

All content is in English only (no Arabic).

**Your real logo** is used directly (`assets/images/logo.jpg`) in the nav
bar badge, the hero centerpiece, and the footer — each wrapped in a soft gold
ring that matches the wheat-gold accent.

**Lined background texture** — a custom-painted, slowly drifting diagonal
line pattern (`LinedBackground`) echoes the wheat stalk's parallel strokes.
It runs behind the hero (gold-on-dark) and the menu/story sections
(gold-on-cream), tying every section to the same visual language instead of
feeling like flat, disconnected blocks.

**Tighter color harmony** — every surface pulls from one unified palette
(`surfaceCream`, `cardBorder`, `espresso`/`espressoDeep`/`espressoDark`) so
cards, sections and the nav bar read as one family rather than separate colors.

**Animation — all built with Flutter's own `Transform`/`Matrix4`/`AnimationController`, no extra engine required:**
- `WheatLogo3D` — your real logo, floating with a perspective-matrix tilt that follows the cursor, framed by a breathing gold glow.
- `ProductCard3D` — each menu card tilts in 3D toward the mouse and lifts with a matching drop shadow + gold border glow.
- The hero background gradient slowly drifts between espresso tones (ambient, not static).
- The "Nafas" wordmark reveals letter-by-letter on load, like it's being hand-set.
- The CTA button has a breathing gold glow (pulse loop).
- Nav bar condenses + shadows on scroll; the logo badge pulses and slowly rotates; the cart icon bounces and the badge count animates in when an item is added.
- The add-to-cart button on each card does a spring "pop" and briefly flashes a checkmark on tap.
- Menu cards cascade into view with a staggered fade + slide as the grid appears.
- The story banner and footer fade + slide into view the first time they scroll into the viewport (`ScrollReveal`).
- Floating parallax pastry emoji drift across the hero banner; animated gold underline on nav link hover.

**Product details** — tapping anywhere on a menu card (not the gold "+" button)
opens a details dialog (`lib/widgets/product_detail_sheet.dart`): a hero
banner with the item's tag, a star rating, a short "why it's special" story,
2-3 tasting highlights, calories/prep-time/category pills, ingredient and
allergen chips, and a quantity stepper feeding a bigger add-to-cart button.
It's a single lightweight fade+scale dialog (no blur, no continuous
animation tickers) built from the existing theme, so it opens instantly and
doesn't add any ongoing frame cost to the page. `Product` gained optional
fields (`story`, `highlights`, `ingredients`, `allergens`, `calories`,
`prepMinutes`, `rating`, `reviewCount`) — all defaulted, so nothing else
had to change.

## Setup (run locally — this project's platform folders aren't generated yet)

```bash
# 1. Unzip, then from inside the folder:
flutter create . --platforms=web   # scaffolds web/ and other platform boilerplate
flutter pub get
flutter run -d chrome
```

To build a deployable static site:

```bash
flutter build web
# output in build/web/ — deploy anywhere (Netlify, Firebase Hosting, GitHub Pages, etc.)
```

## Replacing the logo image

Your uploaded logo is copied to `assets/images/logo.jpg`. It's not wired into
any widget by default (the app draws its own vector wheat mark so it can
rotate/animate smoothly), but you can drop it into the hero or nav bar with:

```dart
Image.asset('assets/images/logo.jpg')
```

## Structure

```
lib/
  main.dart
  theme/app_theme.dart        # colors & fonts
  models/product.dart         # menu data (swap for a real API later)
  widgets/
    wheat_logo_3d.dart        # rotating 3D wheat glyph
    product_card_3d.dart      # tilting product cards
    hero_section.dart         # banner with parallax
    nav_bar.dart
  screens/home_screen.dart    # ties it all together
```

## Next steps you may want

- Wire `demoProducts` to a real backend (Firestore, REST API, etc.)
- Add a cart/checkout screen (the cart icon already tracks a running count)
- Add real product photography instead of emoji placeholders
- If you want *true* 3D models (rotatable GLB assets, e.g. an actual 3D
  croissant), add the `model_viewer_plus` package — happy to wire that in too.
