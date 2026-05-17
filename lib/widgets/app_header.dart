import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatefulWidget {
  final String title;
  final bool showSearch;
  final String searchPlaceholder;
  final ValueChanged<String>? onSearch;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.showSearch = true,
    this.searchPlaceholder = 'Search...',
    this.onSearch,
    this.actions,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _glowAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_glowCtrl);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kCardDark : kCardLight;
    final isFlux = widget.title == 'FLUX';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isFlux)
                    ShaderMask(
                      shaderCallback: (b) => kGradient.createShader(b),
                      child: Text(
                        'FLUX',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                    )
                  else
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                  const Spacer(),
                  ...?widget.actions,
                ],
              ),
              if (widget.showSearch) ...[
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, child) => CustomPaint(
                    painter: _GlowBorderPainter(angle: _glowAnim.value, isDark: isDark),
                    child: child,
                  ),
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F1729) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search_rounded, size: 16, color: kPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            onChanged: widget.onSearch,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: widget.searchPlaceholder,
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                              fillColor: Colors.transparent,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onSearch?.call(_ctrl.text),
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              gradient: kGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 8),
                              ],
                            ),
                            child: const Icon(Icons.arrow_forward_rounded,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  final double angle;
  final bool isDark;
  _GlowBorderPainter({required this.angle, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    final gradient = SweepGradient(
      startAngle: angle,
      endAngle: angle + 2 * pi,
      colors: const [
        Color(0xFF833AB4),
        Color(0xFFfd1d1d),
        Color(0xFFfcb045),
        Color(0xFF833AB4),
      ],
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_GlowBorderPainter old) => old.angle != angle;
}