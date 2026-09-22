import 'package:flutter/services.dart';

import 'deeplink_dispatcher.dart';
import 'dispatch_result.dart';

/// Pushes the URL onto a native->Flutter [EventChannel] so the app's existing
/// deeplink listener receives it exactly like a real incoming link.
class ChannelInjectDispatcher implements DeeplinkDispatcher {
  final String channelName;
  final MethodCodec codec;

  const ChannelInjectDispatcher({
    required this.channelName,
    this.codec = const StandardMethodCodec(),
  });

  @override
  Future<DispatchResult> dispatch(String url) async {
    try {
      ServicesBinding.instance.channelBuffers.push(
        channelName,
        codec.encodeSuccessEnvelope(url),
        (ByteData? reply) {},
      );
      return const DispatchResult.success('Injected');
    } catch (e) {
      return DispatchResult.failure('Inject failed: $e');
    }
  }
}
