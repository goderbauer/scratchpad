import 'package:ephemeral/ephemeral.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const HttpEphemeralApp());
}

class HttpEphemeralApp extends StatelessWidget {
  const HttpEphemeralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ephemeral Widget Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HttpEphemeralScreen(),
    );
  }
}

class HttpEphemeralScreen extends StatefulWidget {
  const HttpEphemeralScreen({super.key});

  @override
  State<HttpEphemeralScreen> createState() => _HttpEphemeralScreenState();
}

class _HttpEphemeralScreenState extends State<HttpEphemeralScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: 'http://localhost:8000/counter.js',
  );

  String? _loadedUrl;
  Key _ephemeralKey = UniqueKey();
  Uri? _currentFetchUri;

  void _loadUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;

    final baseUri = Uri.parse(trimmed);
    setState(() {
      _loadedUrl = trimmed;
      _currentFetchUri = _buildFreshUri(baseUri);
      _ephemeralKey = UniqueKey();
    });
  }

  void _forceRefresh() {
    if (_loadedUrl == null) return;
    final baseUri = Uri.parse(_loadedUrl!);
    setState(() {
      _currentFetchUri = _buildFreshUri(baseUri);
      _ephemeralKey = UniqueKey();
    });
  }

  Uri _buildFreshUri(Uri baseUri) {
    final query = Map<String, String>.from(baseUri.queryParameters);
    query['_t'] = DateTime.now().millisecondsSinceEpoch.toString();
    return baseUri.replace(queryParameters: query);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ephemeral Widget Demo'),
        actions: [
          if (_loadedUrl != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Force Reload from Server',
              onPressed: _forceRefresh,
            ),
        ],
      ),
      body: _loadedUrl == null
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            hintText: 'http://localhost:8000/counter.js',
                            labelText: 'JS File URL',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          keyboardType: TextInputType.url,
                          onSubmitted: (value) => _loadUrl(value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _loadUrl(_urlController.text),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Load'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Enter a JS bundle URL above and tap Load.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            )
          : Ephemeral.network(
              key: _ephemeralKey,
              url: _currentFetchUri!,
            ),
    );
  }
}
