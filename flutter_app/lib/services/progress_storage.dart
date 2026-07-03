import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress_snapshot_model.dart';

abstract class ProgressStorage {
  Future<ProgressSnapshotModel> loadProgress();
  Future<void> saveProgress(ProgressSnapshotModel progressSnapshot);
  Future<void> clearProgress();
}

class SharedPreferencesProgressStorage implements ProgressStorage {
  static const String _storageKey = 'career_chaos_progress_v1';

  @override
  Future<ProgressSnapshotModel> loadProgress() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedProgress = preferences.getString(_storageKey);

      if (savedProgress == null || savedProgress.trim().isEmpty) {
        return const ProgressSnapshotModel();
      }

      final decoded = jsonDecode(savedProgress);
      if (decoded is! Map<String, dynamic>) {
        await preferences.remove(_storageKey);
        return const ProgressSnapshotModel();
      }

      return ProgressSnapshotModel.fromJson(decoded);
    } catch (_) {
      return const ProgressSnapshotModel();
    }
  }

  @override
  Future<void> saveProgress(ProgressSnapshotModel progressSnapshot) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(progressSnapshot));
  }

  @override
  Future<void> clearProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}

class InMemoryProgressStorage implements ProgressStorage {
  ProgressSnapshotModel _cache = const ProgressSnapshotModel();

  @override
  Future<ProgressSnapshotModel> loadProgress() async {
    return _cache;
  }

  @override
  Future<void> saveProgress(ProgressSnapshotModel progressSnapshot) async {
    _cache = progressSnapshot;
  }

  @override
  Future<void> clearProgress() async {
    _cache = const ProgressSnapshotModel();
  }
}
