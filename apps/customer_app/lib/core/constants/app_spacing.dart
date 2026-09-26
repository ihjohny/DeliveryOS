import 'package:flutter/material.dart';

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Standard EdgeInsets presets
  static const EdgeInsets edgeInsetsZero = EdgeInsets.zero;
  static const EdgeInsets edgeInsetsXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsMd = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeInsetsXl = EdgeInsets.all(xl);
  static const EdgeInsets edgeInsetsXxl = EdgeInsets.all(xxl);

  static const EdgeInsets edgeInsetsHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets edgeInsetsHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets edgeInsetsHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets edgeInsetsHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets edgeInsetsVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets edgeInsetsVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets edgeInsetsVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets edgeInsetsVerticalXl = EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets edgeInsetsVerticalXxl = EdgeInsets.symmetric(vertical: xxl);
}

class AppRadius {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  static const Radius radiusXxs = Radius.circular(xxs);
  static const Radius radiusXs = Radius.circular(xs);
  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusXl = Radius.circular(xl);
  static const Radius radiusXxl = Radius.circular(xxl);
  static const Radius radiusFull = Radius.circular(full);

  static const BorderRadius borderXxs = BorderRadius.all(radiusXxs);
  static const BorderRadius borderXs = BorderRadius.all(radiusXs);
  static const BorderRadius borderSm = BorderRadius.all(radiusSm);
  static const BorderRadius borderMd = BorderRadius.all(radiusMd);
  static const BorderRadius borderLg = BorderRadius.all(radiusLg);
  static const BorderRadius borderXl = BorderRadius.all(radiusXl);
  static const BorderRadius borderXxl = BorderRadius.all(radiusXxl);
  static const BorderRadius borderFull = BorderRadius.all(radiusFull);
}
