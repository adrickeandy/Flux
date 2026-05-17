import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) context.go(user != null ? '/home' : '/login');
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter(isDark)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      gradient: kGradient,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(color: kPrimary.withOpacity(0.5),
                            blurRadius: 40, offset: const Offset(0, 12)),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 56),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (b) => kGradient.createShader(b),
                  child: const Text('FLUX',
                    style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900,
                        color: Colors.white, fontStyle: FontStyle.italic, letterSpacing: -2)),
                ),
                const SizedBox(height: 8),
                Text('MESSAGING REIMAGINED',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                      letterSpacing: 4, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Column(
              children: [
                Text('from', style: TextStyle(fontSize: 8, color: Colors.grey.shade500,
                    fontWeight: FontWeight.w700, letterSpacing: 2)),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (b) => kGradient.createShader(b),
                  child: const Text('Flux Studio',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final bool dark;
  _GridPainter(this.dark);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (dark ? Colors.white : Colors.black).withOpacity(0.04)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}