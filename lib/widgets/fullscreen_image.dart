import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullscreenImageViewer extends StatelessWidget {
  final String url;
  final String name;

  const FullscreenImageViewer({super.key, required this.url, required this.name});

  static void show(BuildContext context, String url, String name) {
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => FullscreenImageViewer(url: url, name: name),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(name, style: const TextStyle(fontSize: 13)),
      ),
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(url),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        heroAttributes: PhotoViewHeroAttributes(tag: url),
      ),
    );
  }
}