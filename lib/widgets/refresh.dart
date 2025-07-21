import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class RefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double height;
  final Color color;
  final Color backgroundColor;
  final double animSpeedFactor;
  final bool showChildOpacityTransition;

  const RefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.height = 70,
    this.color = const Color(0xFFEB5E00),
    this.backgroundColor = Colors.white,
    this.animSpeedFactor = 10.0,
    this.showChildOpacityTransition = false,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidPullToRefresh(
      onRefresh: onRefresh,
      height: height,
      color: color,
      backgroundColor: backgroundColor,
      animSpeedFactor: animSpeedFactor,
      showChildOpacityTransition: showChildOpacityTransition,
      child: child,
    );
  }
}
