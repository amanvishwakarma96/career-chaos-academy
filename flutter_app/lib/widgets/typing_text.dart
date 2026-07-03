import 'dart:async';

import 'package:flutter/material.dart';

import '../services/animation_service.dart';

class TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration characterDelay;
  final bool animate;

  const TypingText({
    super.key,
    required this.text,
    this.style,
    this.characterDelay = const Duration(milliseconds: 14),
    this.animate = true,
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  Timer? _timer;
  int _visibleCharacters = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant TypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.animate != widget.animate) {
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer?.cancel();

    if (!widget.animate ||
        AnimationService.instance.isReducedMotion ||
        widget.text.isEmpty) {
      setState(() {
        _visibleCharacters = widget.text.length;
      });
      return;
    }

    setState(() {
      _visibleCharacters = 0;
    });

    _timer = Timer.periodic(widget.characterDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_visibleCharacters >= widget.text.length) {
        timer.cancel();
        return;
      }

      setState(() {
        _visibleCharacters += 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AnimationService.instance.reducedMotion,
      builder: (context, reducedMotion, _) {
        final safeCount = reducedMotion
            ? widget.text.length
            : _visibleCharacters.clamp(0, widget.text.length);
        return Text(
          widget.text.substring(0, safeCount),
          style: widget.style,
        );
      },
    );
  }
}
