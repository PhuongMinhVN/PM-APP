import 'package:flutter/material.dart';

import 'platform_image_stub.dart'
    if (dart.library.io) 'platform_image_mobile.dart'
    if (dart.library.js_interop) 'platform_image_web.dart';

class UniversalImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const UniversalImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }

    return platformImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
    );
  }
}
