import 'package:flutter/material.dart';

import '../models/voice_profile_model.dart';
import '../services/device_user_service.dart';
import '../services/voice_conversation_service.dart';

class VoiceSettingsScreen extends StatefulWidget {
  final bool interviewPrototype;

  const VoiceSettingsScreen({super.key, this.interviewPrototype = false});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  final TextEditingController _messageController = TextEditingController();
  late Future<void> _loadFuture;
  VoiceProfileCatalogModel? _catalog;
  VoiceSettingsModel _settings = const VoiceSettingsModel();
  VoiceProfileModel? _selectedProfile;
  final List<CharacterChatTurnModel> _turns = <CharacterChatTurnModel>[];
  String _userId = 'local-user';
  String _message = '';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    final catalog = await VoiceConversationService.instance.loadProfiles();
    final settings = await VoiceConversationService.instance.loadSettings(userId);
    final profile = _profileFor(settings, catalog) ?? (catalog.profiles.isNotEmpty ? catalog.profiles.first : null);
    final turns = await VoiceConversationService.instance.loadLocalTurns(userId);
    if (!mounted) return;
    setState(() {
      _userId = userId;
      _catalog = catalog;
      _settings = profile == null ? settings : settings.copyWith(selectedVoiceProfileId: profile.id);
      _selectedProfile = profile;
      _turns
        ..clear()
        ..addAll(turns);
    });
  }

  VoiceProfileModel? _profileFor(VoiceSettingsModel settings, VoiceProfileCatalogModel catalog) {
    for (final profile in catalog.profiles) {
      if (profile.id == settings.selectedVoiceProfileId) return profile;
    }
    return null;
  }

  Future<void> _saveSettings(VoiceSettingsModel settings) async {
    setState(() {
      _settings = settings;
      _message = '';
      _isBusy = true;
    });
    try {
      final saved = await VoiceConversationService.instance.saveSettings(_userId, settings);
      if (!mounted) return;
      setState(() {
        _settings = saved;
        _isBusy = false;
        _message = 'Voice preference saved. Subtitles remain always visible.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isBusy = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final profile = _selectedProfile;
    if (profile == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      setState(() => _message = 'Type a message first. Speech input is a placeholder, so text fallback is active.');
      return;
    }
    setState(() {
      _isBusy = true;
      _message = '';
    });
    try {
      final response = await VoiceConversationService.instance.sendCharacterMessage(
        userId: _userId,
        settings: _settings,
        profile: profile,
        message: text,
        roleId: widget.interviewPrototype ? profile.roleId : profile.roleId,
        scenarioId: widget.interviewPrototype ? 'interview_voice_prototype' : 'voice_character_prototype',
        scenarioTitle: widget.interviewPrototype ? 'Interview voice practice prototype' : 'Character conversation prototype',
      );
      await VoiceConversationService.instance.synthesizePlaceholder(
        text: response.turn.replyText,
        settings: _settings,
      );
      if (!mounted) return;
      setState(() {
        _turns.insert(0, response.turn);
        _messageController.clear();
        _message = response.turn.safety.blocked
            ? 'Unsafe advice blocked. Text fallback/subtitles are still available.'
            : 'Character replied within scenario context. ${response.languageLabel} subtitles shown.';
        _isBusy = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.interviewPrototype ? 'Interview Voice Prototype' : 'Voice & Character Chat')),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || _catalog == null) {
              return const Center(child: Text('Unable to load voice profiles.'));
            }
            final catalog = _catalog!;
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    _HeaderCard(interviewPrototype: widget.interviewPrototype),
                    const SizedBox(height: 12),
                    _SubtitlePolicyCard(catalog: catalog),
                    const SizedBox(height: 12),
                    _SettingsCard(
                      catalog: catalog,
                      settings: _settings,
                      selectedProfile: _selectedProfile,
                      onProfileChanged: (profile) {
                        setState(() => _selectedProfile = profile);
                        _saveSettings(_settings.copyWith(selectedVoiceProfileId: profile.id));
                      },
                      onVoiceEnabledChanged: (value) => _saveSettings(_settings.copyWith(voiceEnabled: value)),
                      onLanguageChanged: (value) => _saveSettings(_settings.copyWith(languageMode: value)),
                      onVolumeChanged: (value) => _saveSettings(_settings.copyWith(voiceVolume: value)),
                    ),
                    const SizedBox(height: 12),
                    _ChatComposerCard(
                      controller: _messageController,
                      selectedProfile: _selectedProfile,
                      settings: _settings,
                      onSend: _isBusy ? null : _sendMessage,
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(_message),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _ConversationList(turns: _turns),
                  ],
                ),
                if (_isBusy)
                  Container(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.42),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final bool interviewPrototype;

  const _HeaderCard({required this.interviewPrototype});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            interviewPrototype ? 'Prototype Interview Voice Mode' : 'AI Voice & Character Conversation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            interviewPrototype
                ? 'Practice interview answers with text fallback, always-visible subtitles, and scenario-bound mentor replies.'
                : 'Voice is future-ready but optional. The app uses subtitle-first dialogue, placeholder TTS/STT hooks, safe character replies, and English/Hinglish/Hindi modes.',
          ),
        ],
      ),
    );
  }
}

class _SubtitlePolicyCard extends StatelessWidget {
  final VoiceProfileCatalogModel catalog;

  const _SubtitlePolicyCard({required this.catalog});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subtitle-first architecture', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Subtitles always show: ${catalog.subtitleFirst ? 'enabled' : 'disabled'}'),
            Text('TTS provider: ${catalog.textToSpeech.provider} (${catalog.textToSpeech.status})'),
            Text('STT provider: ${catalog.speechToText.provider} (${catalog.speechToText.status})'),
            const SizedBox(height: 8),
            Text(catalog.conversationSafety.notice),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final VoiceProfileCatalogModel catalog;
  final VoiceSettingsModel settings;
  final VoiceProfileModel? selectedProfile;
  final ValueChanged<VoiceProfileModel> onProfileChanged;
  final ValueChanged<bool> onVoiceEnabledChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<double> onVolumeChanged;

  const _SettingsCard({
    required this.catalog,
    required this.settings,
    required this.selectedProfile,
    required this.onProfileChanged,
    required this.onVoiceEnabledChanged,
    required this.onLanguageChanged,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable voice playback'),
              subtitle: const Text('Prototype uses placeholder TTS. Text fallback remains active if voice fails.'),
              value: settings.voiceEnabled,
              onChanged: onVoiceEnabledChanged,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Subtitles always visible'),
              subtitle: const Text('Locked on for accessibility and voice failure fallback.'),
              value: settings.subtitlesAlwaysOn,
              onChanged: null,
            ),
            DropdownButtonFormField<String>(
              value: selectedProfile?.id,
              decoration: const InputDecoration(labelText: 'Character voice profile'),
              items: [
                for (final profile in catalog.profiles)
                  DropdownMenuItem<String>(
                    value: profile.id,
                    child: Text(profile.displayName),
                  ),
              ],
              onChanged: (value) {
                final match = catalog.profiles.where((item) => item.id == value).toList(growable: false);
                if (match.isNotEmpty) onProfileChanged(match.first);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: settings.languageMode,
              decoration: const InputDecoration(labelText: 'Language mode'),
              items: const [
                DropdownMenuItem(value: 'english', child: Text('English')),
                DropdownMenuItem(value: 'hinglish', child: Text('Hinglish')),
                DropdownMenuItem(value: 'hindi', child: Text('Hindi')),
              ],
              onChanged: (value) {
                if (value != null) onLanguageChanged(value);
              },
            ),
            const SizedBox(height: 12),
            Text('Voice volume ${(settings.voiceVolume * 100).round()}%'),
            Slider(
              value: settings.voiceVolume,
              onChanged: onVolumeChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatComposerCard extends StatelessWidget {
  final TextEditingController controller;
  final VoiceProfileModel? selectedProfile;
  final VoiceSettingsModel settings;
  final VoidCallback? onSend;

  const _ChatComposerCard({
    required this.controller,
    required this.selectedProfile,
    required this.settings,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scenario-bound character chat', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Selected: ${selectedProfile?.displayName ?? 'No profile'} • ${_languageLabel(settings.languageMode)}'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Type your dialogue or interview answer',
                hintText: 'Example: I want to fix this quickly, can I skip testing?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.mic),
                  label: const Text('STT placeholder'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onSend,
                  icon: const Icon(Icons.chat),
                  label: const Text('Ask Character'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  final List<CharacterChatTurnModel> turns;

  const _ConversationList({required this.turns});

  @override
  Widget build(BuildContext context) {
    if (turns.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No character replies yet. Send a message to test subtitle-first fallback.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Conversation preview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        for (final turn in turns.take(8))
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(turn.characterName)),
                      Chip(label: Text(_languageLabel(turn.languageMode))),
                      Chip(label: Text(turn.safety.blocked ? 'Blocked' : 'Safe')),
                      const Chip(label: Text('Subtitles on')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('You: ${turn.inputText}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(turn.subtitles.isEmpty ? turn.replyText : turn.subtitles.first),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(turn.memoryBoundary.notice, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _languageLabel(String value) {
  if (value == 'hindi') return 'Hindi';
  if (value == 'hinglish') return 'Hinglish';
  return 'English';
}
