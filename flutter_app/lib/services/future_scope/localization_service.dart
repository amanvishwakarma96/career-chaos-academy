import 'dart:convert';

import 'package:flutter/services.dart';

class LocalizationTextService {
  LocalizationTextService._();

  static final LocalizationTextService instance = LocalizationTextService._();

  Map<String, String> _strings = const <String, String>{};

  Future<void> load({String locale = 'en'}) async {
    try {
      final raw = await rootBundle.loadString('assets/i18n/$locale.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _strings = decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (_) {
      _strings = const <String, String>{};
    }
  }

  String t(String key, {String fallback = ''}) {
    if (key.trim().isEmpty) return fallback;
    return _strings[key] ?? fallback;
  }
}
