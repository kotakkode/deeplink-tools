import 'controller/deeplink_tester_controller.dart';

/// Global access to the active controller, for programmatic sends
/// (integration tests, VM-service drivers).
class DeeplinkTesterRegistry {
  DeeplinkTesterRegistry._();

  static DeeplinkTesterController? _controller;

  static DeeplinkTesterController? get maybeInstance => _controller;

  static DeeplinkTesterController get instance {
    final c = _controller;
    if (c == null) {
      throw StateError('DeeplinkTesterOverlay is not mounted');
    }
    return c;
  }

  static void attach(DeeplinkTesterController controller) {
    _controller = controller;
  }

  static void detach(DeeplinkTesterController controller) {
    if (identical(_controller, controller)) _controller = null;
  }
}
