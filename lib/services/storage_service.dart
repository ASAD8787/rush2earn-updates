import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _stepsKey = 'rush2earn_total_steps';
  static const _dailyStepsKey = 'rush2earn_daily_steps';
  static const _claimedStepsKey = 'rush2earn_claimed_steps';

  Future<int> loadTotalSteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_stepsKey) ?? 0;
  }

  Future<void> saveTotalSteps(int totalSteps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepsKey, totalSteps);
  }

  Future<Map<String, int>> loadDailySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailyStepsKey);
    if (raw == null || raw.isEmpty) {
      return <String, int>{};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return <String, int>{};
    }

    final result = <String, int>{};
    decoded.forEach((key, value) {
      if (value is num) {
        result[key] = value.toInt();
      }
    });
    return result;
  }

  Future<void> saveDailySteps(Map<String, int> dailySteps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyStepsKey, jsonEncode(dailySteps));
  }

  Future<int> loadClaimedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_claimedStepsKey) ?? 0;
  }

  Future<void> saveClaimedSteps(int claimedSteps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claimedStepsKey, claimedSteps);
  }
}
