import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/mini_game_answer_model.dart';
import '../models/mini_game_model.dart';
import '../models/mini_game_result_model.dart';
import '../services/mini_game_service.dart';
import '../widgets/info_panel.dart';
import '../widgets/motion_feedback_animation.dart';

class MiniGameScreen extends StatefulWidget {
  final MiniGameModel miniGame;

  const MiniGameScreen({super.key, required this.miniGame});

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  final Set<String> _selectedOptionIds = <String>{};
  final Map<String, String> _pairAnswers = <String, String>{};
  late List<MiniGameOptionModel> _orderedItems;
  bool _showHint = false;

  MiniGameModel get _miniGame => widget.miniGame;

  @override
  void initState() {
    super.initState();
    _orderedItems = List<MiniGameOptionModel>.from(_miniGame.orderItems);
  }

  void _toggleSelected(String optionId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedOptionIds.add(optionId);
      } else {
        _selectedOptionIds.remove(optionId);
      }
    });
  }

  void _selectSingle(String optionId) {
    setState(() {
      _selectedOptionIds
        ..clear()
        ..add(optionId);
    });
  }

  void _updatePairAnswer(String leftId, String? rightId) {
    if (rightId == null) {
      return;
    }

    setState(() {
      _pairAnswers[leftId] = rightId;
    });
  }

  void _moveOrderItem(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _orderedItems.length) {
      return;
    }

    setState(() {
      final item = _orderedItems.removeAt(index);
      _orderedItems.insert(newIndex, item);
    });
  }

  Future<void> _submit() async {
    final answer = MiniGameAnswerModel(
      selectedOptionIds: Set<String>.unmodifiable(_selectedOptionIds),
      pairAnswers: Map<String, String>.unmodifiable(_pairAnswers),
      orderedItemIds: _orderedItems.map((item) => item.id).toList(
            growable: false,
          ),
    );
    final result = MiniGameService.instance.validate(
      miniGame: _miniGame,
      answer: answer,
    );

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          icon: MotionFeedbackAnimation(
            type: result.isSuccess
                ? MotionFeedbackType.success
                : MotionFeedbackType.failure,
            size: 96,
          ),
          title: Text(result.isSuccess ? 'Mini-game cleared!' : 'Chaos result!'),
          content: Text(result.message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue Story'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-game'),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: ListView(
            padding: ResponsiveLayout.pagePadding(context),
            children: [
          Text(
            _miniGame.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(_miniGame.type.label)),
              const Chip(label: Text('Role Challenge')),
            ],
          ),
          const SizedBox(height: 16),
          InfoPanel(title: 'Instructions', body: _miniGame.instructions),
          const SizedBox(height: 12),
          InfoPanel(title: 'Prompt', body: _miniGame.prompt),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showHint = !_showHint),
            icon: const Icon(Icons.lightbulb_outline),
            label: Text(_showHint ? 'Hide Hint' : 'Show Hint'),
          ),
          if (_showHint) ...[
            const SizedBox(height: 12),
            InfoPanel(title: 'Hint', body: _miniGame.hint),
          ],
          const SizedBox(height: 20),
          ..._buildMiniGameBody(context),
          const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle),
                label: const Text('Submit Mini-game'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMiniGameBody(BuildContext context) {
    switch (_miniGame.type) {
      case MiniGameType.codeFix:
        return _buildCodeFix(context);
      case MiniGameType.multipleSelect:
        return _buildMultipleSelect(context);
      case MiniGameType.matchPairs:
        return _buildMatchPairs(context);
      case MiniGameType.arrangeOrder:
        return _buildArrangeOrder(context);
      case MiniGameType.dataCleanup:
        return _buildDataCleanup(context);
      case MiniGameType.decisionMatrix:
        return _buildDecisionMatrix(context);
    }
  }

  List<Widget> _buildCodeFix(BuildContext context) {
    return [
      Text(
        'Choose the best fix:',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 8),
      ..._miniGame.options.map(
        (option) => Card(
          child: RadioListTile<String>(
            value: option.id,
            groupValue: _selectedOptionIds.isEmpty
                ? null
                : _selectedOptionIds.first,
            onChanged: (value) {
              if (value != null) {
                _selectSingle(value);
              }
            },
            title: Text(option.text),
            subtitle:
                option.helperText == null ? null : Text(option.helperText!),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMultipleSelect(BuildContext context) {
    return _buildCheckboxOptions(
      context,
      title: 'Select all correct items:',
      options: _miniGame.options,
    );
  }

  List<Widget> _buildDataCleanup(BuildContext context) {
    return _buildCheckboxOptions(
      context,
      title: 'Select records that need cleanup:',
      options: _miniGame.options,
    );
  }

  List<Widget> _buildDecisionMatrix(BuildContext context) {
    return _buildCheckboxOptions(
      context,
      title: 'Select the best decisions from the matrix:',
      options: _miniGame.options,
    );
  }

  List<Widget> _buildCheckboxOptions(
    BuildContext context, {
    required String title,
    required List<MiniGameOptionModel> options,
  }) {
    return [
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 8),
      ...options.map(
        (option) => Card(
          child: CheckboxListTile(
            value: _selectedOptionIds.contains(option.id),
            onChanged: (value) => _toggleSelected(option.id, value ?? false),
            title: Text(option.text),
            subtitle:
                option.helperText == null ? null : Text(option.helperText!),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMatchPairs(BuildContext context) {
    final rightOptions = _miniGame.pairs
        .map(
          (pair) => DropdownMenuItem<String>(
            value: pair.rightId,
            child: Text(pair.rightText),
          ),
        )
        .toList(growable: false);

    return [
      Text(
        'Match each item correctly:',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 8),
      ..._miniGame.pairs.map(
        (pair) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pair.leftText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _pairAnswers[pair.leftId],
                  decoration: const InputDecoration(
                    labelText: 'Choose matching answer',
                    border: OutlineInputBorder(),
                  ),
                  items: rightOptions,
                  onChanged: (value) => _updatePairAnswer(
                    pair.leftId,
                    value,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildArrangeOrder(BuildContext context) {
    return [
      Text(
        'Arrange the steps in the correct order:',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 8),
      ..._orderedItems.asMap().entries.map(
        (entry) {
          final index = entry.key;
          final item = entry.value;
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(item.text),
              subtitle: item.helperText == null ? null : Text(item.helperText!),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Move up',
                    onPressed: index == 0
                        ? null
                        : () => _moveOrderItem(index, -1),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    tooltip: 'Move down',
                    onPressed: index == _orderedItems.length - 1
                        ? null
                        : () => _moveOrderItem(index, 1),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }
}
