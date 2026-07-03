import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content_generation/content_agent_prompt.dart';
import '../content_generation/content_generation_prompt_service.dart';
import '../content_generation/generated_content_validation_result.dart';
import '../content_generation/generated_content_validator.dart';
import '../core/responsive_layout.dart';
import '../widgets/generated_content_validation_card.dart';
import '../widgets/info_panel.dart';

class ContentGeneratorScreen extends StatefulWidget {
  const ContentGeneratorScreen({super.key});

  @override
  State<ContentGeneratorScreen> createState() => _ContentGeneratorScreenState();
}

class _ContentGeneratorScreenState extends State<ContentGeneratorScreen> {
  final TextEditingController _jsonController = TextEditingController();
  late GeneratedContentValidationResult _validationResult;
  bool _approvedByUser = false;

  @override
  void initState() {
    super.initState();
    _validationResult = GeneratedContentValidator.instance.validate('');
    _jsonController.addListener(_validateJson);
  }

  @override
  void dispose() {
    _jsonController
      ..removeListener(_validateJson)
      ..dispose();
    super.dispose();
  }

  void _validateJson() {
    setState(() {
      _approvedByUser = false;
      _validationResult = GeneratedContentValidator.instance.validate(
        _jsonController.text,
      );
    });
  }

  Future<void> _copyWorkflowPrompt() async {
    await Clipboard.setData(
      ClipboardData(
        text: ContentGenerationPromptService.combinedWorkflowPrompt,
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Multi-agent prompt copied.')),
    );
  }

  Future<void> _copyApprovedJson() async {
    final normalizedJson = _validationResult.normalizedJson;
    if (normalizedJson == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: normalizedJson));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Approved app-ready JSON copied for manual save.'),
      ),
    );
  }

  void _approveContent() {
    setState(() {
      _approvedByUser = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Content approved for manual save after code review. Add it to assets/scenarios only after review.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Scenario Lab'),
        actions: [
          IconButton(
            tooltip: 'Copy workflow prompt',
            onPressed: _copyWorkflowPrompt,
            icon: const Icon(Icons.copy_all),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: ListView(
            padding: ResponsiveLayout.pagePadding(context),
            children: [
              Text(
                'Multi-Agent Content Generator',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use these prompts with your AI tool, paste the generated JSON here, validate it, then approve it before manually adding it to the app assets.',
              ),
              const SizedBox(height: 16),
              const InfoPanel(
                title: 'Safety rule',
                body:
                    'Generated content is educational only. Medical, legal, financial, safety-critical, or compliance scenarios must include safe limits and must not diagnose, prescribe, guarantee outcomes, or replace qualified professionals.',
              ),
              const SizedBox(height: 12),
              _PromptTemplateSection(
                prompts: ContentGenerationPromptService.prompts,
              ),
              const SizedBox(height: 12),
              _JsonPasteCard(controller: _jsonController),
              const SizedBox(height: 12),
              GeneratedContentValidationCard(result: _validationResult),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _approvedByUser,
                onChanged: _validationResult.isAppReady
                    ? (value) {
                        if (value == true) {
                          _approveContent();
                        } else {
                          setState(() => _approvedByUser = false);
                        }
                      }
                    : null,
                title: const Text('Human review completed and approved'),
                subtitle: const Text(
                  'Approval is required before generated JSON is saved into assets/scenarios.',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _validationResult.isAppReady && _approvedByUser
                    ? _copyApprovedJson
                    : null,
                icon: const Icon(Icons.file_copy),
                label: const Text('Copy Approved JSON'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _copyWorkflowPrompt,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Copy Multi-Agent Prompt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptTemplateSection extends StatelessWidget {
  final List<ContentAgentPrompt> prompts;

  const _PromptTemplateSection({required this.prompts});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Agent Prompts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            ...prompts.map(
              (prompt) => ExpansionTile(
                leading: const Icon(Icons.smart_toy),
                title: Text(prompt.agentName),
                subtitle: Text(prompt.responsibility),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  SelectableText(prompt.prompt.trim()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JsonPasteCard extends StatelessWidget {
  final TextEditingController controller;

  const _JsonPasteCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generated Scenario JSON',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 10,
              maxLines: 18,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                labelText: 'Paste generated role JSON here',
                helperText:
                    'The validator normalizes scenario → story so generated JSON remains app-loadable.',
              ),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
