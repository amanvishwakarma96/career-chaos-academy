import 'package:flutter/material.dart';

import '../services/audio_service.dart';

class AudioSettingTile extends StatelessWidget {
  const AudioSettingTile({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        AudioService.instance.muted,
        AudioService.instance.musicVolume,
        AudioService.instance.sfxVolume,
        AudioService.instance.voiceVolume,
      ]),
      builder: (context, _) {
        final muted = AudioService.instance.muted.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile.adaptive(
              value: muted,
              onChanged: AudioService.instance.setMuted,
              secondary: Icon(muted ? Icons.volume_off : Icons.volume_up),
              title: const Text('Mute Audio'),
              subtitle: const Text(
                'Stops background music, voice placeholders, and sound effects without affecting gameplay.',
              ),
            ),
            _VolumeSlider(
              label: 'Music Volume',
              icon: Icons.music_note,
              value: AudioService.instance.musicVolume.value,
              enabled: !muted,
              onChanged: AudioService.instance.setMusicVolume,
            ),
            _VolumeSlider(
              label: 'Sound Effects Volume',
              icon: Icons.graphic_eq,
              value: AudioService.instance.sfxVolume.value,
              enabled: !muted,
              onChanged: AudioService.instance.setSfxVolume,
            ),
            _VolumeSlider(
              label: 'Future Voice Volume',
              icon: Icons.record_voice_over,
              value: AudioService.instance.voiceVolume.value,
              enabled: !muted,
              onChanged: AudioService.instance.setVoiceVolume,
            ),
          ],
        );
      },
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Slider(
        value: value.clamp(0.0, 1.0).toDouble(),
        onChanged: enabled ? onChanged : null,
      ),
      trailing: Text('${(value * 100).round()}%'),
    );
  }
}
