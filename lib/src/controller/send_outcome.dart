/// What happened when the tester tried to send a deeplink.
class SendOutcome {
  final bool sent;
  final String message;
  final String url;

  const SendOutcome._({
    required this.sent,
    required this.message,
    required this.url,
  });

  const SendOutcome.success(String message, String url)
    : this._(sent: true, message: message, url: url);

  const SendOutcome.failure(String message, {String url = ''})
    : this._(sent: false, message: message, url: url);

  @override
  String toString() => 'SendOutcome(sent: $sent, message: $message, url: $url)';
}
