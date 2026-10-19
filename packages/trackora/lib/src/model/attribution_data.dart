import 'attribution_method.dart';
import 'attribution_status.dart';
import 'trackora_platform.dart';
import 'trackora_store.dart';

/// Normalized attribution data resolved from an install referrer, deep link,
/// or web URL.
class AttributionData {
  /// The operating platform where attribution was captured.
  final TrackoraPlatform platform;

  /// The store or origin source where the installation or visit originated.
  final TrackoraStore store;

  /// The campaign source (e.g., `google`, `facebook`, `cafebazaar`, `newsletter`).
  final String? source;

  /// The advertising medium (e.g., `cpc`, `banner`, `email`, `social`).
  final String? medium;

  /// The campaign name (e.g., `spring_promotion_2026`).
  final String? campaign;

  /// Unique identifier of the campaign (e.g., from `utm_id`).
  final String? campaignId;

  /// Ad group or keyword term (e.g., from `utm_term`).
  final String? adGroup;

  /// Ad creative or content description (e.g., from `utm_content`).
  final String? creative;

  /// Click identifier (e.g., `gclid`, `fbclid`, `ttclid`, `msclkid`).
  final String? clickId;

  /// The raw, unparsed referrer string exactly as received from the store or URL.
  final String? rawReferrer;

  /// The landing page or deep-link URL if attribution was initiated via a URL.
  final String? landingUrl;

  /// The mechanism through which attribution was acquired.
  final AttributionMethod attributionMethod;

  /// The timestamp when attribution was recorded or resolved.
  final DateTime? timestamp;

  /// The resolution status of this attribution record.
  final AttributionStatus status;

  /// Additional store-specific or contextual parameters (e.g. click timestamp,
  /// install begin timestamp, instant app flag, error message).
  final Map<String, dynamic> metadata;

  const AttributionData({
    required this.platform,
    required this.store,
    this.source,
    this.medium,
    this.campaign,
    this.campaignId,
    this.adGroup,
    this.creative,
    this.clickId,
    this.rawReferrer,
    this.landingUrl,
    this.attributionMethod = AttributionMethod.unknown,
    this.timestamp,
    required this.status,
    this.metadata = const <String, dynamic>{},
  });

  /// Factory for when attribution is unsupported on the current platform/store.
  factory AttributionData.unsupported({
    required TrackoraPlatform platform,
    TrackoraStore store = TrackoraStore.unknown,
    String? message,
  }) {
    return AttributionData(
      platform: platform,
      store: store,
      status: AttributionStatus.unsupported,
      attributionMethod: AttributionMethod.unknown,
      metadata: message != null ? {'message': message} : const {},
    );
  }

  /// Factory for when an attribution check completed but no referrer was found.
  factory AttributionData.notAvailable({
    required TrackoraPlatform platform,
    required TrackoraStore store,
    AttributionMethod method = AttributionMethod.storeReferrer,
    String? message,
  }) {
    return AttributionData(
      platform: platform,
      store: store,
      status: AttributionStatus.notAvailable,
      attributionMethod: method,
      metadata: message != null ? {'message': message} : const {},
    );
  }

  /// Factory for when an attribution check failed with an error.
  factory AttributionData.failed({
    required TrackoraPlatform platform,
    required TrackoraStore store,
    required String error,
    AttributionMethod method = AttributionMethod.unknown,
    Map<String, dynamic>? extraMetadata,
  }) {
    final meta = <String, dynamic>{'error': error};
    if (extraMetadata != null) {
      meta.addAll(extraMetadata);
    }
    return AttributionData(
      platform: platform,
      store: store,
      status: AttributionStatus.failed,
      attributionMethod: method,
      metadata: meta,
    );
  }

  /// Factory for when an attribution check is pending.
  factory AttributionData.pending({
    required TrackoraPlatform platform,
    required TrackoraStore store,
  }) {
    return AttributionData(
      platform: platform,
      store: store,
      status: AttributionStatus.pending,
      attributionMethod: AttributionMethod.unknown,
    );
  }

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'platform': platform.toJson(),
      'store': store.toJson(),
      if (source != null) 'source': source,
      if (medium != null) 'medium': medium,
      if (campaign != null) 'campaign': campaign,
      if (campaignId != null) 'campaignId': campaignId,
      if (adGroup != null) 'adGroup': adGroup,
      if (creative != null) 'creative': creative,
      if (clickId != null) 'clickId': clickId,
      if (rawReferrer != null) 'rawReferrer': rawReferrer,
      if (landingUrl != null) 'landingUrl': landingUrl,
      'attributionMethod': attributionMethod.toJson(),
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      'status': status.toJson(),
      'metadata': metadata,
    };
  }

  /// Deserializes from a JSON map with robust handling of missing/invalid types.
  factory AttributionData.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTimestamp;
    final rawTs = json['timestamp'];
    if (rawTs is String) {
      parsedTimestamp = DateTime.tryParse(rawTs);
    } else if (rawTs is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTs);
    }

    Map<String, dynamic> parsedMetadata = const {};
    if (json['metadata'] is Map) {
      parsedMetadata = Map<String, dynamic>.from(json['metadata'] as Map);
    }

    return AttributionData(
      platform: TrackoraPlatform.fromJson(json['platform']?.toString() ?? ''),
      store: TrackoraStore.fromJson(json['store']?.toString() ?? ''),
      source: json['source']?.toString(),
      medium: json['medium']?.toString(),
      campaign: json['campaign']?.toString(),
      campaignId: json['campaignId']?.toString(),
      adGroup: json['adGroup']?.toString(),
      creative: json['creative']?.toString(),
      clickId: json['clickId']?.toString(),
      rawReferrer: json['rawReferrer']?.toString(),
      landingUrl: json['landingUrl']?.toString(),
      attributionMethod: AttributionMethod.fromJson(
        json['attributionMethod']?.toString() ?? '',
      ),
      timestamp: parsedTimestamp,
      status: AttributionStatus.fromJson(json['status']?.toString() ?? ''),
      metadata: parsedMetadata,
    );
  }

  /// Creates a copy of this object with the given fields replaced.
  AttributionData copyWith({
    TrackoraPlatform? platform,
    TrackoraStore? store,
    String? source,
    String? medium,
    String? campaign,
    String? campaignId,
    String? adGroup,
    String? creative,
    String? clickId,
    String? rawReferrer,
    String? landingUrl,
    AttributionMethod? attributionMethod,
    DateTime? timestamp,
    AttributionStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return AttributionData(
      platform: platform ?? this.platform,
      store: store ?? this.store,
      source: source ?? this.source,
      medium: medium ?? this.medium,
      campaign: campaign ?? this.campaign,
      campaignId: campaignId ?? this.campaignId,
      adGroup: adGroup ?? this.adGroup,
      creative: creative ?? this.creative,
      clickId: clickId ?? this.clickId,
      rawReferrer: rawReferrer ?? this.rawReferrer,
      landingUrl: landingUrl ?? this.landingUrl,
      attributionMethod: attributionMethod ?? this.attributionMethod,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttributionData &&
        other.platform == platform &&
        other.store == store &&
        other.source == source &&
        other.medium == medium &&
        other.campaign == campaign &&
        other.campaignId == campaignId &&
        other.adGroup == adGroup &&
        other.creative == creative &&
        other.clickId == clickId &&
        other.rawReferrer == rawReferrer &&
        other.landingUrl == landingUrl &&
        other.attributionMethod == attributionMethod &&
        other.timestamp == timestamp &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(
        platform,
        store,
        source,
        medium,
        campaign,
        campaignId,
        adGroup,
        creative,
        clickId,
        rawReferrer,
        landingUrl,
        attributionMethod,
        timestamp,
        status,
      );

  @override
  String toString() {
    return 'AttributionData('
        'platform: $platform, '
        'store: $store, '
        'source: $source, '
        'medium: $medium, '
        'campaign: $campaign, '
        'campaignId: $campaignId, '
        'clickId: $clickId, '
        'status: $status, '
        'method: $attributionMethod'
        ')';
  }
}
