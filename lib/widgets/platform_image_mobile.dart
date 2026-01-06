import 'package:flutter/material.dart';

Widget platformImage({required String imageUrl, BoxFit? fit, double? width, double? height}) {
  return Image.network(
    imageUrl,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (context, error, stackTrace) => Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    ),
  );
}
