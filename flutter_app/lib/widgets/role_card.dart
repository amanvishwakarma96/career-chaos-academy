import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/role_icon_mapper.dart';
import '../models/role_scenario_model.dart';
import '../services/animation_service.dart';

class RoleCard extends StatefulWidget {
  final RoleScenarioModel roleScenario;
  final double progressPercent;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.roleScenario,
    required this.progressPercent,
    required this.onTap,
  });

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() => _isPressed = value);
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  Color get _accent {
    const palette = <Color>[
      Color(0xFFFF4D8D),
      Color(0xFF6C8CFF),
      Color(0xFF56E0C4),
      Color(0xFFFFB84D),
      Color(0xFFC77DFF),
      Color(0xFF70D6FF),
      Color(0xFFFF6B6B),
      Color(0xFF9BE564),
    ];
    final index = widget.roleScenario.role.id.hashCode.abs() % palette.length;
    return palette[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentLabel = (widget.progressPercent * 100).round();
    final icon = RoleIconMapper.fromKey(widget.roleScenario.role.iconKey);
    final accent = _accent;
    final reducedMotion = AnimationService.instance.isReducedMotion;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reducedMotion ? 1 : 0.94, end: 1),
      duration: AnimationService.instance.duration(
        const Duration(milliseconds: 420),
      ),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedScale(
        scale: reducedMotion ? 1 : (_isPressed ? 0.965 : 1),
        duration: AnimationService.instance.duration(
          const Duration(milliseconds: 110),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: _isPressed
                ? const <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: accent.withOpacity(0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _handleTap,
              onHighlightChanged: _setPressed,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: accent.withOpacity(_isPressed ? 0.82 : 0.40),
                    width: _isPressed ? 2 : 1.2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color.lerp(const Color(0xFF171326), accent, 0.26)!,
                      const Color(0xFF111426),
                      const Color(0xFF090B14),
                    ],
                    stops: const <double>[0, 0.58, 1],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      right: -20,
                      top: 22,
                      child: Icon(
                        icon,
                        size: 104,
                        color: accent.withOpacity(0.08),
                      ),
                    ),
                    Positioned(
                      left: -34,
                      bottom: -44,
                      child: Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(0.08),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.12),
                              blurRadius: 36,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Hero(
                                tag: 'role-icon-${widget.roleScenario.role.id}',
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: accent.withOpacity(0.18),
                                    border: Border.all(
                                      color: accent.withOpacity(0.48),
                                    ),
                                  ),
                                  child: Icon(icon, color: accent, size: 27),
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: widget.progressPercent,
                                      strokeWidth: 4,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.10),
                                      color: accent,
                                    ),
                                    Center(
                                      child: Text(
                                        '$percentLabel%',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'CAREER SIMULATION',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.roleScenario.role.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.roleScenario.totalChapters} missions',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white60,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 5,
                                    value: widget.progressPercent,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.10),
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.play_arrow_rounded,
                                color: accent,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
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
