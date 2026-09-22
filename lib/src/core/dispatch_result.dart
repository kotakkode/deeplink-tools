/// Outcome of a dispatcher call.
class DispatchResult {
  final bool ok;
  final String message;

  const DispatchResult({required this.ok, required this.message});

  const DispatchResult.success(String message)
    : this(ok: true, message: message);

  const DispatchResult.failure(String message)
    : this(ok: false, message: message);

  @override
  String toString() => 'DispatchResult(ok: $ok, message: $message)';
}
