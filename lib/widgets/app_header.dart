import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class AppHeader extends StatefulWidget {
  final String title;
  final bool showSearch;
  final String searchPlaceholder;
  final ValueChanged<String>? onSearch;

  const AppHeader({
    super.key,
    required this.title,
    this.showSearch = true,
    this.searchPlaceholder = 'Search...',
    this.onSearch,
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
        vsync: this, duration: const Duration(seconds: 2))..repeat();
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
    final isHome = widget.title == 'FLUX';
    final provider = ThemeProvider.of(context);
    final isDarkMode = provider?.themeMode == ThemeMode.dark ||
        (provider?.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Container(
      decoration: BoxDecoration(
        color: cardColor.withAlpha(242),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Back button if not home
                  if (!isHome)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(13),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withAlpha(25)),
                        ),
                        child: Icon(Icons.chevron_left_rounded,
                            size: 20, color: Colors.grey.shade500),
                      ),
                    ),
                  if (!isHome) const SizedBox(width: 12),

                  // Title
                  if (isHome)
                    ShaderMask(
                      shaderCallback: (b) => kGradient.createShader(b),
                      child: const Text(
                        'FLUX',
                        style: TextStyle(
                          fontSize: 40,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),

                  const Spacer(),

                  // Dark mode toggle (home only)
                  if (isHome)
                    GestureDetector(
                      onTap: () {
                        provider?.setTheme(
                            isDarkMode ? ThemeMode.light : ThemeMode.dark);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(13),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withAlpha(25)),
                        ),
                        child: Icon(
                          isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 16, color: kPrimary,
                        ),
                      ),
                    ),
                  if (isHome) const SizedBox(width: 8),

                  // Settings icon
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withAlpha(25)),
                      ),
                      child: Icon(Icons.settings_rounded,
                          size: 16,
                          color: isDark ? Colors.white : const Color(0xFF111827)),
                    ),
                  ),
                ],
              ),

              if (widget.showSearch) ...[
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, child) => CustomPaint(
                    painter: _GlowBorderPainter(angle: _glowAnim.value, isDark: isDark),
                    child: child,
                  ),
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F1729) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                            style: const TextStyle(fontSize: 11),
                            decoration: InputDecoration(
                              hintText: widget.searchPlaceholder,
                              hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11),
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
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: kPrimary.withAlpha(77), blurRadius: 8),
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
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = SweepGradient(
          startAngle: angle,
          endAngle: angle + 2 * pi,
          colors: const [
            Color(0xFF833AB4), Color(0xFFfd1d1d),
            Color(0xFFfcb045), Color(0xFF833AB4),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_GlowBorderPainter old) => old.angle != angle;
}