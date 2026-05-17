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
  bool _searching = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _glowAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(_glowController);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kCardDark : kCardLight;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16)],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!_searching) ...[
                    ShaderMask(
                      shaderCallback: (b) => kGradient.createShader(b),
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                  if (_searching)
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        onChanged: widget.onSearch,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: widget.searchPlaceholder,
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  if (widget.showSearch)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _searching = !_searching;
                          if (!_searching) {
                            _ctrl.clear();
                            widget.onSearch?.call('');
                          }
                        });
                      },
                      icon: Icon(
                        _searching ? Icons.close : Icons.search_rounded,
                        color: _searching ? kPrimary : Colors.grey,
                      ),
                    ),
                  ...?widget.actions,
                ],
              ),
              if (widget.showSearch) ...[
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _GlowBorderPainter(
                        angle: _glowAnimation.value,
                        isDark: isDark,
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    height: 42,
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
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onSearch?.call(_ctrl.text),
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: kGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
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

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlowBorderPainter old) => old.angle != angle;
}