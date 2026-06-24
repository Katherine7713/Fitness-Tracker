import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onSwipeUp;

  const WelcomeScreen({super.key, required this.onSwipeUp});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 16).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
      widget.onSwipeUp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/wallpaper.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: GestureDetector(
        onVerticalDragEnd: _onVerticalDragEnd,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Text(
                  'Desliza hacia arriba',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const Text(
                  'Fitness track.',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: child,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up,
                        size: 40,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Desliza',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
