import '../model/attribution_data.dart';
import '../model/attribution_method.dart';
import '../model/attribution_status.dart';
import '../model/trackora_platform.dart';
import '../model/trackora_store.dart';

/// Utility class for safely normalizing raw referrer strings, URL queries,
/// and campaign parameters into standardized [AttributionData].
class AttributionNormalizer {
  const AttributionNormalizer._();

  /// Known click ID query parameter names in priority order.
  static const List<String> recognizedClickIdKeys = [
    'gclid', // Google Click ID
    'fbclid', // Facebook / Meta Click ID
    'ttclid', // TikTok Click ID
    'msclkid', // Microsoft Bing Click ID
    'twclid', // Twitter / X Click ID
    'wbraid', // Google Web to App iOS
    'gbraid', // Google App to App iOS
    'dclid', // Google Display Click ID
    'click_id', // Generic click ID
    'clickid',
    'cid',
  ];

  /// Safely parses a query string or URL into key-value parameter pairs.
  ///
  /// Handles:
  /// - Full URLs (`https://example.com/page?utm_source=test`)
  /// - Query-only strings (`?utm_source=test&utm_medium=cpc`)
  /// - Raw parameter strings (`utm_source=test&utm_medium=cpc`)
  /// - Safely decodes `+` and `%xx` percent encoding without double-decoding
  /// - Resilient to malformed percent escapes (e.g. `%` or `%2` or `%zz`)
  static Map<String, String> parseQueryString(String? raw) {
    if (raw == null) return const {};

    var input = raw.trim();
    if (input.isEmpty) return const {};

    // If it's a full URL or starts with ?, isolate the query part
    final queryQuestionIndex = input.indexOf('?');
    if (queryQuestionIndex != -1) {
      input = input.substring(queryQuestionIndex + 1);
    }

    // Strip any fragment / hash (#)
    final hashIndex = input.indexOf('#');
    if (hashIndex != -1) {
      input = input.substring(0, hashIndex);
    }

    if (input.isEmpty) return const {};

    final result = <String, String>{};
    final pairs = input.split('&');

    for (final pair in pairs) {
      if (pair.isEmpty) continue;
      final eqIndex = pair.indexOf('=');
      String rawKey;
      String rawValue;
      if (eqIndex == -1) {
        rawKey = pair;
        rawValue = '';
      } else {
        rawKey = pair.substring(0, eqIndex);
        rawValue = pair.substring(eqIndex + 1);
      }

      final key = safeUrlDecode(rawKey).trim();
      final value = safeUrlDecode(rawValue).trim();

      if (key.isNotEmpty && value.isNotEmpty) {
        // Deterministic precedence: preserve the first non-empty value
        result.putIfAbsent(key, () => value);
      }
    }

    return result;
  }

  /// Decodes URL percent-encoding safely without throwing on malformed inputs
  /// and avoiding double-decoding.
  static String safeUrlDecode(String input) {
    if (input.isEmpty) return input;

    // Replace '+' with space for application/x-www-form-urlencoded
    final withSpaces = input.replaceAll('+', ' ');

    // Fast path: if there are no '%' characters, no percent decoding needed
    if (!withSpaces.contains('%')) {
      return withSpaces;
    }

    try {
      return Uri.decodeComponent(withSpaces);
    } catch (_) {
      // Fallback: decode character by character to preserve partially malformed strings
      return _lenientDecode(withSpaces);
    }
  }

  static String _lenientDecode(String input) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < input.length) {
      final ch = input[i];
      if (ch == '%' && i + 2 < input.length) {
        final hex = input.substring(i + 1, i + 3);
        final code = int.tryParse(hex, radix: 16);
        if (code != null) {
          buffer.writeCharCode(code);
          i += 3;
          continue;
        }
      }
      buffer.write(ch);
      i++;
    }
    return buffer.toString();
  }

  /// Normalizes a raw referrer string from an app store into [AttributionData].
  static AttributionData fromReferrerString({
    required String? rawReferrer,
    required TrackoraPlatform platform,
    required TrackoraStore store,
    AttributionMethod method = AttributionMethod.storeReferrer,
    Map<String, dynamic> metadata = const {},
    DateTime? timestamp,
  }) {
    final trimmedRaw = rawReferrer?.trim();
    if (trimmedRaw == null || trimmedRaw.isEmpty) {
      return AttributionData.notAvailable(
        platform: platform,
        store: store,
        method: method,
        message: 'No install referrer data provided by store',
      );
    }

    final params = parseQueryString(trimmedRaw);

    // If query string didn't yield structured params, check if rawReferrer itself
    // is a single token or non-key-value referrer
    if (params.isEmpty && trimmedRaw.isNotEmpty) {
      return AttributionData(
        platform: platform,
        store: store,
        rawReferrer: trimmedRaw,
        attributionMethod: method,
        timestamp: timestamp ?? DateTime.now().toUtc(),
        status: AttributionStatus.available,
        metadata: {
          ...metadata,
          'unstructured_referrer': trimmedRaw,
        },
      );
    }

    return _buildAttributionData(
      params: params,
      platform: platform,
      store: store,
      method: method,
      rawReferrer: trimmedRaw,
      landingUrl: null,
      timestamp: timestamp,
      extraMetadata: metadata,
    );
  }

  /// Normalizes a [Uri] (deep link or web browser URL) into [AttributionData].
  static AttributionData fromUri(
    Uri uri, {
    required TrackoraPlatform platform,
    TrackoraStore store = TrackoraStore.unknown,
    AttributionMethod method = AttributionMethod.universalLink,
    Map<String, dynamic> metadata = const {},
    DateTime? timestamp,
  }) {
    // Collect query parameters safely from URI
    final params = <String, String>{};
    for (final entry in uri.queryParameters.entries) {
      final k = entry.key.trim();
      final v = entry.value.trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        params[k] = v;
      }
    }

    if (params.isEmpty) {
      return AttributionData(
        platform: platform,
        store: store,
        landingUrl: uri.toString(),
        attributionMethod: method,
        timestamp: timestamp ?? DateTime.now().toUtc(),
        status: AttributionStatus.notAvailable,
        metadata: {
          ...metadata,
          'message': 'No campaign query parameters found in URL',
        },
      );
    }

    return _buildAttributionData(
      params: params,
      platform: platform,
      store: store,
      method: method,
      rawReferrer: uri.query.isNotEmpty ? uri.query : null,
      landingUrl: uri.toString(),
      timestamp: timestamp,
      extraMetadata: metadata,
    );
  }

  static AttributionData _buildAttributionData({
    required Map<String, String> params,
    required TrackoraPlatform platform,
    required TrackoraStore store,
    required AttributionMethod method,
    required String? rawReferrer,
    required String? landingUrl,
    required DateTime? timestamp,
    required Map<String, dynamic> extraMetadata,
  }) {
    // 1. UTM parameters
    final source = _findParam(params, ['utm_source', 'source']);
    final medium = _findParam(params, ['utm_medium', 'medium']);
    final campaign = _findParam(params, ['utm_campaign', 'campaign']);
    final campaignId =
        _findParam(params, ['utm_id', 'campaign_id', 'campaignid']);
    final adGroup = _findParam(params, ['utm_term', 'adgroup', 'term']);
    final creative = _findParam(params, ['utm_content', 'creative', 'content']);

    // 2. Click IDs: collect all found click IDs in metadata and select the primary one
    final foundClickIds = <String, String>{};
    String? primaryClickId;

    for (final key in recognizedClickIdKeys) {
      final value = _findParam(params, [key]);
      if (value != null && value.isNotEmpty) {
        foundClickIds[key] = value;
        primaryClickId ??= value;
      }
    }

    final mergedMetadata = <String, dynamic>{
      ...extraMetadata,
      if (foundClickIds.isNotEmpty) 'click_ids': foundClickIds,
    };

    // Determine status: if at least one meaningful field exists
    final hasAttribution = source != null ||
        campaign != null ||
        primaryClickId != null ||
        medium != null ||
        campaignId != null;

    final status = hasAttribution
        ? AttributionStatus.available
        : AttributionStatus.notAvailable;

    return AttributionData(
      platform: platform,
      store: store,
      source: source,
      medium: medium,
      campaign: campaign,
      campaignId: campaignId,
      adGroup: adGroup,
      creative: creative,
      clickId: primaryClickId,
      rawReferrer: rawReferrer,
      landingUrl: landingUrl,
      attributionMethod: method,
      timestamp: timestamp ?? DateTime.now().toUtc(),
      status: status,
      metadata: mergedMetadata,
    );
  }

  static String? _findParam(Map<String, String> params, List<String> aliases) {
    for (final alias in aliases) {
      for (final entry in params.entries) {
        if (entry.key.toLowerCase() == alias.toLowerCase()) {
          final val = entry.value.trim();
          if (val.isNotEmpty) return val;
        }
      }
    }
    return null;
  }
}
