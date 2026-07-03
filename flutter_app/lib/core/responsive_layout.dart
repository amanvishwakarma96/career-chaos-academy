import 'dart:math' as math;

import 'package:flutter/material.dart';

class ResponsiveLayout {
  ResponsiveLayout._();

  static const double tabletBreakpoint = 700;
  static const double desktopBreakpoint = 1100;
  static const double maxContentWidth = 980;

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tabletBreakpoint;
  }

  static int roleGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) {
      return 4;
    }
    if (width >= tabletBreakpoint) {
      return 3;
    }
    return 2;
  }

  static double roleCardAspectRatio(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) {
      return 1.1;
    }
    if (width >= tabletBreakpoint) {
      return 1.0;
    }
    return 0.92;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = math.min(28.0, math.max(16.0, width * 0.045));
    return EdgeInsets.fromLTRB(horizontal, 20, horizontal, 28);
  }
}

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveLayout.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
