import 'package:deeplink_tools/deeplink_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The channel this example app "listens" on, exactly like a real app whose
/// native side forwards incoming links over an EventChannel.
const kDeeplinkChannel = 'com.example.deeplink_tools/deeplinks';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'deeplink_tools example',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      builder:
          (context, child) => DeeplinkTesterOverlay(
            config: DeeplinkTesterConfig(
              enabled: !kReleaseMode,
              eventChannelName: kDeeplinkChannel,
              icon: const Icon(Icons.link),
              initialEnvId: 'dev',
              bundledProfileAsset: 'assets/deeplink_profiles.json',
              envs: const [
                DeeplinkEnv(id: 'dev', label: 'DEV'),
                DeeplinkEnv(id: 'prod', label: 'PROD'),
              ],
            ),
            child: child!,
          ),
      home: const ReceivedLinksPage(),
    );
  }
}

/// Shows every link the app "received" on the channel.
class ReceivedLinksPage extends StatefulWidget {
  const ReceivedLinksPage({super.key});

  @override
  State<ReceivedLinksPage> createState() => _ReceivedLinksPageState();
}

class _ReceivedLinksPageState extends State<ReceivedLinksPage> {
  final _received = <String>[];

  @override
  void initState() {
    super.initState();
    const EventChannel(kDeeplinkChannel).receiveBroadcastStream().listen(
      (link) => setState(() => _received.insert(0, '$link')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Received deeplinks')),
      body:
          _received.isEmpty
              ? const Center(
                child: Text('Tap the floating button and send a deeplink.'),
              )
              : ListView.builder(
                itemCount: _received.length,
                itemBuilder:
                    (_, i) => ListTile(
                      leading: const Icon(Icons.call_received),
                      title: Text(_received[i]),
                    ),
              ),
    );
  }
}
