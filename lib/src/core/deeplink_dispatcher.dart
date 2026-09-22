import 'dispatch_result.dart';

/// Delivers a resolved deeplink URL to the app.
abstract class DeeplinkDispatcher {
  Future<DispatchResult> dispatch(String url);
}
