import 'package:career_chaos_academy/games/bug_hunt_room_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 36E Bug Hunt engagement rescue', () {
    test('runtime incident mix keeps three blockers and two decoys', () {
      final game = BugHuntRoomGame(seed: 101);

      expect(game.definition.targets, hasLength(5));
      expect(
        game.definition.targets.where((target) => target.isCorrect),
        hasLength(3),
      );
      expect(
        game.definition.targets.where((target) => !target.isCorrect),
        hasLength(2),
      );
    });

    test('different seeds can produce different incident runs', () {
      final first = BugHuntRoomGame(seed: 101).definition.targets
          .map((target) => target.id)
          .toList();
      final second = BugHuntRoomGame(seed: 202).definition.targets
          .map((target) => target.id)
          .toList();

      expect(first, isNot(equals(second)));
    });

    test('wrong call increases pressure and accelerates incident clock', () async {
      final game = BugHuntRoomGame(seed: 101);
      await game.onLoad();
      final wrongIndex = game.definition.targets.indexWhere(
        (target) => !target.isCorrect,
      );
      final wrong = game.definition.targets[wrongIndex];
      final pressureBefore = game.incidentPressure;

      game.toggleTarget(wrong.id);
      game.onTargetTapped(
        target: wrong,
        index: wrongIndex,
        tapPosition: Offset.zero,
        isAdding: true,
      );
      game.update(1);

      expect(game.mistakeCount, 1);
      expect(game.incidentPressure, greaterThan(pressureBefore));
      expect(game.remainingSeconds.value, lessThanOrEqualTo(41));
    });

    test('fast correct combo gives temporary clock relief', () async {
      final game = BugHuntRoomGame(seed: 101);
      await game.onLoad();
      final correctEntries = game.definition.targets
          .asMap()
          .entries
          .where((entry) => entry.value.isCorrect)
          .take(2)
          .toList();

      for (final entry in correctEntries) {
        game.toggleTarget(entry.value.id);
        game.onTargetTapped(
          target: entry.value,
          index: entry.key,
          tapPosition: Offset.zero,
          isAdding: true,
        );
      }
      game.update(1);

      expect(game.comboCount.value, 2);
      expect(game.remainingSeconds.value, 45);
    });
  });
}
