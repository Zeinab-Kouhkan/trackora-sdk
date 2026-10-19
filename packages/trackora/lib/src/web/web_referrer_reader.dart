import 'web_referrer_reader_stub.dart'
    if (dart.library.html) 'web_referrer_reader_web.dart' as impl;

/// Safely retrieves the current browser [Uri] when running on Flutter Web,
/// or returns `null` on non-web platforms.
Uri? readCurrentWebUri() => impl.getCurrentWebUri();
