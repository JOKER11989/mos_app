import 'package:flutter/material.dart';
import 'package:liquid_pull_refresh/liquid_pull_refresh.dart';

class GlobalRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const GlobalRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidPullRefresh(
      onRefresh: onRefresh,
      color: Colors.blueAccent,
      height: 140, // Increased height
      backgroundColor: Colors.white,
      animSpeedFactor: 2,
      showChildOpacityTransition: false,
      loaderWidget: Center(
        child: SizedBox(
          width: 180, // Increased width
          height: 110, // Increased height
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.gavel,
                  color: Colors.blueAccent,
                  size: 50, // Larger icon
                ),
                const SizedBox(height: 10),
                const Text(
                  "مزادي",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 24, // Larger font
                  ),
                  textAlign: TextAlign.center,
                  softWrap: false,
                ),
              ],
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
