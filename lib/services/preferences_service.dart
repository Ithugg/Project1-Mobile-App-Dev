import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user preferences via SharedPreferences.
/// Extends ChangeNotifier so the app rebuilds when settings change.
class PreferencesService extends ChangeNotifier {
  SharedPreferences? _prefs;

  // Keys
  static const _keyDarkMode = 'dark_mode';
  static const _keyUseKg = 'use_kg';
  static const _keyUserName = 'user_name';
  static const _keyFitnessGoal = 'fitness_goal';
  static const _keyWeeklyTarget = 'weekly_target';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Dark mode
  bool get isDarkMode => _prefs?.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool(_keyDarkMode, value);
    notifyListeners();
  }

  // Weight unit (kg vs lbs)
  bool get useKg => _prefs?.getBool(_keyUseKg) ?? true;
  Future<void> setUseKg(bool value) async {
    await _prefs?.setBool(_keyUseKg, value);
    notifyListeners();
  }

  // User name
  String get userName => _prefs?.getString(_keyUserName) ?? 'Fitness Quester';
  Future<void> setUserName(String value) async {
    await _prefs?.setString(_keyUserName, value);
    notifyListeners();
  }

  // Fitness goal
  String get fitnessGoal => _prefs?.getString(_keyFitnessGoal) ?? 'Stay active and healthy';
  Future<void> setFitnessGoal(String value) async {
    await _prefs?.setString(_keyFitnessGoal, value);
    notifyListeners();
  }

  // Weekly workout target
  int get weeklyTarget => _prefs?.getInt(_keyWeeklyTarget) ?? 4;
  Future<void> setWeeklyTarget(int value) async {
    await _prefs?.setInt(_keyWeeklyTarget, value);
    notifyListeners();
  }
}
