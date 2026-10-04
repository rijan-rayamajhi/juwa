import 'package:flutter/material.dart';
import '../services/audio_service.dart';

/// Shared tactile feedback that never delays or repeats the action.
class GamePress extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  const GamePress({super.key, required this.onTap, required this.child});

  @override
  State<GamePress> createState() => _GamePressState();
}

class _GamePressState extends State<GamePress> {
  bool _pressed = false;
  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled
            ? () {
                AudioService.instance.play(GameSound.click);
                widget.onTap!();
              }
            : null,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: enabled && _pressed ? .95 : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
