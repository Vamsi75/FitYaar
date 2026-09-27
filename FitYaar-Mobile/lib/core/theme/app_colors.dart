import 'package:flutter/material.dart';

/// Shared accent + surface tokens for the dark HUD.
///
/// Semantics: **green = live/occupancy**, **orange = primary CTAs & workouts**,
/// **gold-orange = personal records**. Keep these meanings consistent across
/// screens so colour alone communicates state.
class AppColors {
  AppColors._();

  // Occupancy / live (green → amber → red by how busy).
  static const live = Color(0xFF37E29A); // not busy / live
  static const busyMid = Color(0xFFF5A623); // getting busy
  static const busyHigh = Color(0xFFFF5A5F); // packed

  /// Personal-record accent (celebratory gold-orange).
  static const pr = Color(0xFFFFB020);

  /// Neutral slate fill for badges/avatars that shouldn't glow.
  static const slate = Color(0xFF2A2E3D);

  // Glass surface alphas (kept here so cards/buttons stay in sync).
  static const glassBorder = 0.08;
  static const glassFill = 0.06;
}
