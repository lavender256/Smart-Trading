import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < 768;
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 768 && MediaQuery.sizeOf(context).width < 1200;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= 1200;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  // Layout breakpoints
  static double chartWidth(BuildContext context) {
    final w = width(context);
    if (w >= 1200) return w * 0.65;
    if (w >= 768) return w * 0.55;
    return w;
  }

  static double sidePanelWidth(BuildContext context) {
    final w = width(context);
    if (w >= 1200) return w * 0.35;
    if (w >= 768) return w * 0.45;
    return w; // Full width stacked on mobile
  }

  static double toolbarHeight(BuildContext context) {
    if (isMobile(context)) return 40;
    return 48;
  }

  static double fontSize(BuildContext context, {double? base}) {
    final w = width(context);
    if (w >= 1200) return (base ?? 12);
    if (w >= 768) return ((base ?? 12) * 0.9);
    return ((base ?? 12) * 0.8);
  }

  static EdgeInsets padding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(8);
    if (isTablet(context)) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }

  static double domWidth(BuildContext context) {
    final w = width(context);
    if (w >= 1200) return 220;
    if (w >= 768) return 180;
    return w * 0.4;
  }

  static double cvdHeight(BuildContext context) {
    if (isMobile(context)) return 40;
    if (isTablet(context)) return 50;
    return 60;
  }

  static double watchlistWidth(BuildContext context) {
    if (isDesktop(context)) return 180;
    return 140;
  }
}
