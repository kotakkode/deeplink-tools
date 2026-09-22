import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';
import '../core/deeplink_button_geometry.dart';
import 'deeplink_button_icon.dart';
import 'deeplink_pulse_ring.dart';

/// Draggable circular button. Snaps to the nearest edge on release.
///
/// Idle: dimmed and at rest. Active (panel open, dragging, or just sent):
/// brighter, scaled up with a spring, and ringed by a repeating pulse.
class DeeplinkFloatingButton extends StatefulWidget {
  final DeeplinkTesterController controller;

  const DeeplinkFloatingButton({super.key, required this.controller});

  @override
  State<DeeplinkFloatingButton> createState() => _DeeplinkFloatingButtonState();
}

class _DeeplinkFloatingButtonState extends State<DeeplinkFloatingButton>
    with SingleTickerProviderStateMixin {
  static const _stateDuration = Duration(milliseconds: 260);

  Offset? _dragOffset;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  DeeplinkTesterController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncPulse);
    _syncPulse();
  }

  @override
  void didUpdateWidget(DeeplinkFloatingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncPulse);
      widget.controller.addListener(_syncPulse);
      _syncPulse();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncPulse);
    _pulse.dispose();
    super.dispose();
  }

  /// Run the pulse only while the controller reports an active state.
  void _syncPulse() {
    final shouldPulse =
        _controller.isActive && _controller.config.pulseWhenActive;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _controller.config;
    final scheme = Theme.of(context).colorScheme;
    final buttonColor = scheme.primary;
    final iconColor = scheme.onPrimary;
    final padding = MediaQuery.paddingOf(context);
    final isActive = _controller.isActive;
    return Positioned.fill(
      child: Padding(
        padding: padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final geometry = DeeplinkButtonGeometry(
              area: constraints.biggest,
              buttonSize: config.buttonSize,
            );
            final offset =
                _dragOffset ?? geometry.offsetFor(_controller.buttonPosition);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration:
                      _dragOffset == null
                          ? const Duration(milliseconds: 200)
                          : Duration.zero,
                  curve: Curves.easeOut,
                  left: offset.dx,
                  top: offset.dy,
                  width: config.buttonSize,
                  height: config.buttonSize,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _controller.togglePanel,
                    onLongPress: _controller.resendLast,
                    onPanStart: (_) => _onDragStart(offset),
                    onPanUpdate: (d) => _onDragUpdate(d, geometry),
                    onPanEnd: (_) => _onDragEnd(geometry),
                    onPanCancel: () => _onDragEnd(geometry),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        if (isActive && config.pulseWhenActive)
                          DeeplinkPulseRing(
                            progress: _pulse,
                            size: config.buttonSize,
                            color: buttonColor,
                          ),
                        AnimatedScale(
                          duration: _stateDuration,
                          curve:
                              isActive
                                  ? Curves.easeOutBack
                                  : Curves.easeInCubic,
                          scale: isActive ? config.activeScale : 1.0,
                          child: AnimatedOpacity(
                            duration: _stateDuration,
                            opacity: _controller.buttonOpacity,
                            child: AnimatedPhysicalModel(
                              duration: _stateDuration,
                              shape: BoxShape.circle,
                              elevation: isActive ? 8 : 3,
                              color: buttonColor,
                              shadowColor: buttonColor,
                              child: SizedBox(
                                width: config.buttonSize,
                                height: config.buttonSize,
                                child: Center(
                                  child: DeeplinkButtonIcon(
                                    presetKey: _controller.iconPreset,
                                    fallback: config.icon,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onDragStart(Offset current) {
    setState(() => _dragOffset = current);
    _controller.setDragging(true);
  }

  void _onDragUpdate(DragUpdateDetails details, DeeplinkButtonGeometry g) {
    final base = _dragOffset;
    if (base == null) return;
    setState(() => _dragOffset = g.clamp(base + details.delta));
  }

  void _onDragEnd(DeeplinkButtonGeometry g) {
    final released = _dragOffset;
    if (released == null) return;
    setState(() => _dragOffset = null);
    _controller.setButtonPosition(g.snap(released));
    _controller.setDragging(false);
  }
}
