/// Design system for VocalLens.
///
/// Spacing follows a **4pt grid** — every spacing token is a multiple of 4,
/// which keeps vertical rhythm consistent across all screens and scales
/// cleanly on both mobile and web.
///
/// Use the *semantic* tokens (screenPadding, sectionGap, cardInset…) instead
/// of raw numbers so layout intent is explicit and one-line tunable.
class AppSizes {
  // ── Spacing scale (4pt grid) ─────────────────────────
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double xxl  = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;

  // ── Semantic spacing ─────────────────────────────────
  /// Standard horizontal gutter for scrollable screen content.
  static const double screenPadding = 16.0;

  /// Gap between two content sections (cards, carousels, editors…).
  static const double sectionGap = 24.0;

  /// Inner padding of content cards.
  static const double cardInset = 16.0;

  /// Gap between form fields and their labels/actions.
  static const double fieldGap = 12.0;

  /// Horizontal gap between sibling chips/pills.
  static const double chipGap = 8.0;

  /// Minimum comfortable tap target (Material guidance: 48dp).
  static const double minTouchTarget = 48.0;

  /// Scroll content clears the floating bottom player bar comfortably without
  /// excessive empty bottom space.
  static const double playerBarClearance = 180.0;

  // ── Border Radius ────────────────────────────────────
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 14.0;
  static const double radiusXl  = 16.0;
  static const double radiusXxl = 20.0;
  static const double radiusRound = 28.0;

  // ── Font Sizes ────────────────────────────────────────
  static const double fontXs    = 9.0;
  static const double fontSm    = 10.0;
  static const double fontMd    = 11.0;
  static const double fontBase  = 12.0;
  static const double fontMdLg  = 13.0;
  static const double fontLg    = 14.0;
  static const double fontXl    = 15.0;
  static const double fontTitle = 18.0;

  // ── Icon Sizes ────────────────────────────────────────
  static const double iconXs = 13.0;
  static const double iconSm = 16.0;
  static const double iconMd = 18.0;
  static const double iconLg = 20.0;
  static const double iconXl = 22.0;

  // ── Component-Specific ────────────────────────────────
  static const double personaCardHeight   = 168.0;
  static const double personaCardWidth    = 176.0;
  static const double presetCardWidth     = 180.0;
  static const double audioVisualizerH    = 32.0;
  static const double appBarLogoSize      = 7.0;
  static const double appBarLogoBorderR   = 12.0;
  static const double speakButtonPadding  = 16.0;
  static const double historyBadgePad     = 4.0;
  static const double personaAvatarRadius = 16.0;
}
