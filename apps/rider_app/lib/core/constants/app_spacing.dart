import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Preset Insets
  static const EdgeInsets edgeInsetsXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsMd = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeInsetsXl = EdgeInsets.all(xl);
  static const EdgeInsets edgeInsetsXxl = EdgeInsets.all(xxl);
  static const EdgeInsets edgeInsetsXxxl = EdgeInsets.all(xxxl);
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double full = 999.0;

  // Preset Radius
  static const Radius radiusXs = Radius.circular(xs);
  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusFull = Radius.circular(full);

  // Preset BorderRadius
  static const BorderRadius roundedXs = BorderRadius.all(radiusXs);
  static const BorderRadius roundedSm = BorderRadius.all(radiusSm);
  static const BorderRadius roundedMd = BorderRadius.all(radiusMd);
  static const BorderRadius roundedLg = BorderRadius.all(radiusLg);
  static const BorderRadius roundedFull = BorderRadius.all(radiusFull);
}
