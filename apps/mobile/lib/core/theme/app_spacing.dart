import 'package:flutter/material.dart';

/// Tekka Design System - Spacing & Dimensions
///
/// Based on 4dp base unit with 8dp grid alignment.
abstract class AppSpacing {
  AppSpacing._();

  // ==========================================================================
  // SPACING SCALE (4dp base)
  // ==========================================================================

  /// 0dp - No spacing
  static const double space0 = 0;

  /// 4dp - Tight internal spacing
  static const double space1 = 4;

  /// 8dp - Component internal spacing
  static const double space2 = 8;

  /// 12dp - Related elements
  static const double space3 = 12;

  /// 16dp - Standard padding
  static const double space4 = 16;

  /// 20dp - Medium spacing
  static const double space5 = 20;

  /// 24dp - Section spacing
  static const double space6 = 24;

  /// 32dp - Large spacing
  static const double space8 = 32;

  /// 40dp - Screen margins
  static const double space10 = 40;

  /// 48dp - Extra large
  static const double space12 = 48;

  // ==========================================================================
  // EDGE INSETS HELPERS
  // ==========================================================================

  /// Screen horizontal padding (16dp)
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: space4,
  );

  /// Screen padding (16dp all sides)
  static const EdgeInsets screenPadding = EdgeInsets.all(space4);

  /// Card internal padding (12dp)
  static const EdgeInsets cardPadding = EdgeInsets.all(space3);

  /// Card internal padding large (16dp)
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(space4);

  /// Section vertical spacing (24dp)
  static const EdgeInsets sectionVertical = EdgeInsets.symmetric(
    vertical: space6,
  );

  /// Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: space6,
    vertical: space3,
  );

  /// Chip padding
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space2,
  );

  /// Input field padding
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space3,
  );

  /// Trust block padding
  static const EdgeInsets trustBlockPadding = EdgeInsets.all(space4);

  /// Chat bubble padding
  static const EdgeInsets chatBubblePadding = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space3,
  );

  // ==========================================================================
  // BORDER RADIUS
  // ==========================================================================

  /// No radius (0dp)
  static const double radiusNone = 0;

  /// Extra small (4dp) - Chips, small elements
  static const double radiusXs = 4;

  /// Small (8dp) - Cards, buttons
  static const double radiusSm = 8;

  /// Medium (12dp) - Modals, sheets
  static const double radiusMd = 12;

  /// Large (16dp) - Large cards
  static const double radiusLg = 16;

  /// Extra large (24dp) - Bottom sheets
  static const double radiusXl = 24;

  /// Full (9999dp) - Pills, avatars, FAB
  static const double radiusFull = 9999;

  /// Border radius for cards
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(radiusSm),
  );

  /// Border radius for buttons
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(radiusSm),
  );

  /// Border radius for chips
  static const BorderRadius chipRadius = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  /// Border radius for search bar
  static const BorderRadius searchBarRadius = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  /// Border radius for bottom sheet
  static const BorderRadius bottomSheetRadius = BorderRadius.only(
    topLeft: Radius.circular(radiusXl),
    topRight: Radius.circular(radiusXl),
  );

  /// Border radius for detail content overlay
  static const BorderRadius detailOverlayRadius = BorderRadius.only(
    topLeft: Radius.circular(radiusXl),
    topRight: Radius.circular(radiusXl),
  );

  // ==========================================================================
  // COMPONENT SIZES
  // ==========================================================================

  /// App bar height
  static const double appBarHeight = 56;

  /// Bottom navigation height (including safe area)
  static const double bottomNavHeight = 84;

  /// Status bar approximate height
  static const double statusBarHeight = 44;

  /// Search bar height
  static const double searchBarHeight = 48;

  /// Button height - large
  static const double buttonHeightLarge = 52;

  /// Button height - medium
  static const double buttonHeightMedium = 48;

  /// Button height - small
  static const double buttonHeightSmall = 36;

  /// Chip height
  static const double chipHeight = 36;

  /// Input field height
  static const double inputHeight = 48;

  /// Avatar size - small
  static const double avatarSmall = 32;

  /// Avatar size - medium
  static const double avatarMedium = 48;

  /// Avatar size - large
  static const double avatarLarge = 80;

  /// Icon size - small
  static const double iconSmall = 16;

  /// Icon size - medium
  static const double iconMedium = 24;

  /// Icon size - large
  static const double iconLarge = 32;

  /// Touch target minimum (accessibility)
  static const double touchTargetMin = 48;

  /// FAB size
  static const double fabSize = 56;

  /// Listing card image aspect ratio (width:height = 4:3)
  static const double listingImageAspectRatio = 4 / 3;

  /// Gallery image height on detail screen
  static const double galleryHeight = 380;

  // ==========================================================================
  // GRID & LAYOUT
  // ==========================================================================

  /// Listing grid columns (mobile)
  static const int listingGridColumns = 2;

  /// Listing grid gap
  static const double listingGridGap = space4;

  /// Admin queue grid columns (desktop)
  static const int adminQueueColumns = 4;

  /// Max content width (for large screens)
  static const double maxContentWidth = 1200;
}
