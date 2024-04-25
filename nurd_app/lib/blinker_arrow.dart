import 'package:flutter/material.dart';

enum BlinkerDirection { left, right }

class BlinkerArrow extends StatefulWidget {
  final bool blink;
  final BlinkerDirection direction;

  const BlinkerArrow({super.key, required this.blink, required this.direction});

  @override
  State<BlinkerArrow> createState() => _BlinkerArrowState();
}

class _BlinkerArrowState extends State<BlinkerArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeInOutCirc));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: widget.blink ? _opacityAnimation.value : 0.0,
          child: RotatedBox(
            quarterTurns: widget.direction == BlinkerDirection.left ? 2 : 0,
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 64,
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }
}
