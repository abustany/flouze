import 'package:flutter/material.dart';

class SyncIndicator extends StatefulWidget {
  SyncIndicator({Key key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => SyncIndicatorState();
}

class SyncIndicatorState extends State<SyncIndicator> with TickerProviderStateMixin {
  AnimationController animationController;
  Animation animation;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
        vsync: this
    );
    final CurvedAnimation curve = CurvedAnimation(
      parent: animationController,
      curve: Curves.linear
    );

    animation = Tween(begin: 1.0, end: 0.0).animate(curve);
    animationController.repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    RotationTransition(
      child: Icon(Icons.sync),
      turns: animation,
    );

}