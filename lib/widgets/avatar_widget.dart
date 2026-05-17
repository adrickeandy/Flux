import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/helpers.dart';
import '../theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  final bool isOnline;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.url,
    required this.name,
    this.size = 44,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: kPrimary.withOpacity(0.15),
            backgroundImage: url != null && url!.isNotEmpty
                ? CachedNetworkImageProvider(url!)
                : null,
            child: (url == null || url!.isEmpty)
                ? Text(
                    initials(name),
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.27,
                height: size * 0.27,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}