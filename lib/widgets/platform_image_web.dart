import 'dart:ui_web' as ui; // For recent Flutter versions
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web; // For recent Flutter versions

// Unique ID counter
int _viewIdCounter = 0;

Widget platformImage({required String imageUrl, BoxFit? fit, double? width, double? height}) {
  final String viewType = 'img-view-${_viewIdCounter++}';

  // Register the view factory
  // Note: ignore: undefined_prefixed_name is needed sometimes if the analyzer gets confused, 
  // but with dart:ui_web it should be fine.
  ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final element = web.HTMLImageElement();
    element.src = imageUrl;
    element.style.width = '100%';
    element.style.height = '100%';
    
    // Map BoxFit to object-fit
    String objectFit = 'contain'; // Default
    if (fit == BoxFit.cover) objectFit = 'cover';
    if (fit == BoxFit.fill) objectFit = 'fill';
    if (fit == BoxFit.contain) objectFit = 'contain';
    if (fit == BoxFit.fitWidth) objectFit = 'cover'; // Approximation
    if (fit == BoxFit.fitHeight) objectFit = 'cover'; // Approximation
    if (fit == BoxFit.none) objectFit = 'none';
    if (fit == BoxFit.scaleDown) objectFit = 'scale-down';

    element.style.objectFit = objectFit;
    return element;
  });

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
