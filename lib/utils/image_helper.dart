import 'package:flutter/foundation.dart';

class ImageHelper {
  /// Cleans up and standardizes URLs (e.g. converting Google Drive/Dropbox links).
  /// Safe to use when saving to the database.
  static String sanitizeUrl(String url) {
    String effectiveUrl = url.trim();

    // Google Drive
    // Pattern: https://drive.google.com/file/d/VIDEO_ID/view... or https://drive.google.com/open?id=VIDEO_ID
    // We want: https://drive.google.com/uc?export=view&id=VIDEO_ID
    if (effectiveUrl.contains('drive.google.com')) {
       String? id;
       final idRegex = RegExp(r'[-\w]{25,}');
       final match = idRegex.firstMatch(effectiveUrl);
       if (match != null) {
         id = match.group(0);
       }
       
       if (id != null) {
         return 'https://drive.google.com/uc?export=view&id=$id';
       }
    }

    // Dropbox
    // Pattern: https://www.dropbox.com/.../image.jpg?dl=0
    // We want: raw=1
    if (effectiveUrl.contains('dropbox.com')) {
      if (effectiveUrl.contains('?dl=0')) {
        return effectiveUrl.replaceAll('?dl=0', '?raw=1');
      }
      if (!effectiveUrl.contains('?raw=1')) {
         return '$effectiveUrl?raw=1';
      }
    }

    return effectiveUrl;
  }

  // getDisplayUrl removed because UniversalImage handles Web rendering natively using HTML views.
}
