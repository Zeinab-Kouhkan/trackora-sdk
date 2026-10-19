// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation that reads browser URL.
Uri? getCurrentWebUri() {
  try {
    final href = html.window.location.href;
    return Uri.tryParse(href);
  } catch (_) {
    return null;
  }
}
