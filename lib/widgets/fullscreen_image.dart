import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullscreenImageViewer extends StatelessWidget {
  final String? url;
  final String name;

  const FullscreenImageViewer({super.key, this.url, required this.name});

  static void show(BuildContext context, String? url, String name) {
    if (url == null || url.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => FullscreenImageViewer(url: url, name: name),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Stack(
        children: [
          Center(
            child: url != null
                ? InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: url!,
                      fit: BoxFit.contain,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Positioned(
            top: 48, right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}