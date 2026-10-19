import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackora/trackora.dart';
import 'package:trackora_cafebazaar/trackora_cafebazaar.dart';
import 'package:trackora_google_play/trackora_google_play.dart';
import 'package:trackora_myket/trackora_myket.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Trackora with the store adapters enabled for this build.
  // In your production app, install only the store adapters you distribute through!
  await Trackora.initialize(
    adapters: [
      GooglePlayStoreAdapter(),
      CafeBazaarStoreAdapter(),
      MyketStoreAdapter(),
    ],
    config: const TrackoraConfig(
      debugLogging: true,
      enableCache: true,
    ),
  );

  runApp(const TrackoraExampleApp());
}

class TrackoraExampleApp extends StatelessWidget {
  const TrackoraExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackora SDK Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AttributionDashboardPage(),
    );
  }
}

class AttributionDashboardPage extends StatefulWidget {
  const AttributionDashboardPage({super.key});

  @override
  State<AttributionDashboardPage> createState() =>
      _AttributionDashboardPageState();
}

class _AttributionDashboardPageState extends State<AttributionDashboardPage> {
  AttributionData? _attribution;
  bool _isLoading = false;
  String? _errorMessage;
  String? _backendSendStatus;

  final TextEditingController _urlController = TextEditingController(
    text:
        'https://example.com/promo?utm_source=instagram&utm_medium=story&utm_campaign=black_friday&gclid=gclid_sample_987',
  );

  @override
  void initState() {
    super.initState();
    _fetchAttribution();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttribution({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _backendSendStatus = null;
    });

    try {
      final result = await Trackora.instance.getAttribution(
        forceRefresh: forceRefresh,
      );
      setState(() {
        _attribution = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _parseTestUrl() {
    final text = _urlController.text.trim();
    final uri = Uri.tryParse(text);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL format')),
      );
      return;
    }

    final parsed = Trackora.instance.parseUrl(
      uri,
      method: AttributionMethod.universalLink,
    );

    setState(() {
      _attribution = parsed;
      _backendSendStatus = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Campaign URL parsed successfully!')),
    );
  }

  /// Example of how customers can send attribution data to their own private backend.
  /// Trackora never sends attribution data automatically to any server.
  Future<void> _sendToCustomerBackend() async {
    if (_attribution == null) return;

    setState(() {
      _backendSendStatus = 'Preparing payload for customer backend...';
    });

    // In a real application, you would use http.post to your own API endpoint:
    // final response = await http.post(
    //   Uri.parse('https://api.yourcompany.com/v1/attributions'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(_attribution!.toJson()),
    // );
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _backendSendStatus =
          'Successfully forwarded ${_attribution!.status.name} '
          'attribution payload to customer backend (simulated).';
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackora = Trackora.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackora Attribution SDK'),
        actions: [
          IconButton(
            tooltip: 'Refresh Attribution',
            icon: const Icon(Icons.refresh),
            onPressed:
                _isLoading ? null : () => _fetchAttribution(forceRefresh: true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnvironmentCard(trackora),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) _buildErrorBanner(_errorMessage!),
                  if (_attribution != null)
                    _buildAttributionCard(_attribution!),
                  const SizedBox(height: 16),
                  _buildUrlTesterCard(),
                  const SizedBox(height: 16),
                  if (_attribution != null)
                    _buildBackendIntegrationCard(_attribution!),
                  const SizedBox(height: 16),
                  if (_attribution != null) _buildJsonViewCard(_attribution!),
                ],
              ),
            ),
    );
  }

  Widget _buildEnvironmentCard(Trackora trackora) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Runtime Environment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Current Platform: ${trackora.currentPlatform.name}'),
            const SizedBox(height: 4),
            Text(
              'Configured Store Adapters: '
              '${trackora.registeredAdapters.map((a) => a.store.identifier).join(', ')}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Text(
        'Error: $message',
        style: TextStyle(color: Colors.red.shade900),
      ),
    );
  }

  Widget _buildAttributionCard(AttributionData data) {
    Color statusColor;
    switch (data.status) {
      case AttributionStatus.available:
        statusColor = Colors.green;
        break;
      case AttributionStatus.notAvailable:
        statusColor = Colors.orange;
        break;
      case AttributionStatus.unsupported:
        statusColor = Colors.grey;
        break;
      case AttributionStatus.pending:
        statusColor = Colors.blue;
        break;
      case AttributionStatus.failed:
        statusColor = Colors.red;
        break;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Attribution Result',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    data.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildFieldRow('Origin Store', data.store.identifier),
            _buildFieldRow(
                'Attribution Method', data.attributionMethod.identifier),
            _buildFieldRow('Campaign Source (utm_source)', data.source),
            _buildFieldRow('Medium (utm_medium)', data.medium),
            _buildFieldRow('Campaign Name (utm_campaign)', data.campaign),
            _buildFieldRow('Campaign ID (utm_id)', data.campaignId),
            _buildFieldRow('Ad Group / Term (utm_term)', data.adGroup),
            _buildFieldRow('Creative / Content (utm_content)', data.creative),
            _buildFieldRow('Click Identifier (clickId)', data.clickId),
            _buildFieldRow('Raw Referrer String', data.rawReferrer),
            _buildFieldRow('Landing URL', data.landingUrl),
            _buildFieldRow(
                'Resolved Timestamp', data.timestamp?.toIso8601String()),
            if (data.metadata.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Metadata:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(data.metadata),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '(none)',
              style: TextStyle(
                fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                color: value != null ? Colors.black87 : Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlTesterCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Campaign URL & Deep Link Simulator',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test how Trackora parses incoming Universal Links or campaign parameters:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Campaign URL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Parse Campaign URL'),
              onPressed: _parseTestUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendIntegrationCard(AttributionData data) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Backend Integration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Trackora does not transmit your attribution data anywhere. '
              'You can optionally forward the normalized JSON to your own API backend:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Forward to Your Own Backend (Simulated)'),
              onPressed: _sendToCustomerBackend,
            ),
            if (_backendSendStatus != null) ...[
              const SizedBox(height: 8),
              Text(
                _backendSendStatus!,
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJsonViewCard(AttributionData data) {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data.toJson());

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Normalized JSON Payload',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy JSON',
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('JSON copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                jsonStr,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
