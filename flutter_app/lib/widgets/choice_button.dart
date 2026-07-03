import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/choice_model.dart';
import '../services/animation_service.dart';

class ChoiceButton extends StatefulWidget {
  final ChoiceModel choice;
  final VoidCallback onPressed;
  final int? choiceNumber;

  const ChoiceButton({
    super.key,
    required this.choice,
    required this.onPressed,
    this.choiceNumber,
  });

  @override
  State<ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<ChoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AnimationService.instance.isReducedMotion
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 360),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() => _isPressed = value);
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  Color _accentColor(BuildContext context) {
    final score = widget.choice.scoreImpact;
    if (score.chaos >= 3 || score.ethics < 0) {
      return const Color(0xFFFF6B6B);
    }
    if (score.discipline > 0 || score.ethics > 0 || score.skill >= 3) {
      return const Color(0xFF66E3A4);
    }
    return Theme.of(context).colorScheme.tertiary;
  }

  IconData get _choiceIcon {
    final score = widget.choice.scoreImpact;
    if (score.chaos >= 3 || score.ethics < 0) {
      return Icons.warning_amber_rounded;
    }
    if (score.discipline > 0 || score.ethics > 0) {
      return Icons.shield_outlined;
    }
    if (score.skill >= 3) {
      return Icons.psychology_outlined;
    }
    return Icons.bolt;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _accentColor(context);
    final reducedMotion = AnimationService.instance.isReducedMotion;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        final progress = reducedMotion
            ? 1.0
            : Curves.easeOutCubic.transform(_entranceController.value);
        return FadeTransition(
          opacity: AlwaysStoppedAnimation<double>(progress),
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 18),
            child: child,
          ),
        );
      },
      child: AnimatedScale(
        scale: reducedMotion ? 1 : (_isPressed ? 0.975 : 1),
        duration: AnimationService.instance.duration(
          const Duration(milliseconds: 110),
        ),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: AnimationService.instance.duration(
            const Duration(milliseconds: 180),
          ),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: _isPressed
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: accent.withOpacity(0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 9),
                    ),
                  ],
          ),
          child: Material(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.92),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: _handleTap,
              onHighlightChanged: _setPressed,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _isPressed
                        ? accent.withOpacity(0.92)
                        : accent.withOpacity(0.42),
                    width: _isPressed ? 2 : 1.25,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      accent.withOpacity(_isPressed ? 0.18 : 0.10),
                      colorScheme.surfaceContainerHighest.withOpacity(0.90),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: accent.withOpacity(0.16),
                        border: Border.all(color: accent.withOpacity(0.38)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(_choiceIcon, color: accent, size: 23),
                          if (widget.choiceNumber != null)
                            Positioned(
                              right: 4,
                              bottom: 2,
                              child: Text(
                                '${widget.choiceNumber}',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.choice.text,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(0.12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
