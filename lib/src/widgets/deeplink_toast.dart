import 'package:flutter/material.dart';

/// Lightweight bottom toast that needs no Scaffold.
class DeeplinkToast extends StatelessWidget {
  final String? message;

  const DeeplinkToast({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final text = message ?? '';
    return Positioned(
      left: 24,
      right: 24,
      bottom: 32 + MediaQuery.paddingOf(context).bottom,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: message == null ? 0 : 1,
          child: Center(
            child: Material(
              color: Theme.of(context).colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
