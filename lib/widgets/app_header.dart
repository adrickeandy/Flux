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

class _AppHeaderState extends State<AppHeader> {
  final _ctrl = TextEditingController();
  bool _searching = false;

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
                      icon: Icon(_searching ? Icons.close : Icons.search_rounded,
                          color: _searching ? kPrimary : Colors.grey),
                    ),
                  ...?widget.actions,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}