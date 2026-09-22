import 'deeplink_dispatcher.dart';
import 'dispatch_result.dart';

/// Hands the URL to a Dart callback supplied by the host app.
class CallbackDispatcher implements DeeplinkDispatcher {
  final Future<void> Function(String url) callback;

  const CallbackDispatcher(this.callback);

  @override
  Future<DispatchResult> dispatch(String url) async {
    try {
      await callback(url);
      return const DispatchResult.success('Delivered to app callback');
    } catch (e) {
      return DispatchResult.failure('Callback failed: $e');
    }
  }
}
