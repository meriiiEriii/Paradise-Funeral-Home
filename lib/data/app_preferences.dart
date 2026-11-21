import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer.dart';
import 'customer_store.dart';

class AppPreferences {
  static const _customersKey = 'cipms.customers.v1';
  static const _customersImportedKey = 'cipms.customers.imported.v1';
  static const _themeKey = 'cipms.theme.v1';

  final SharedPreferences _prefs;

  AppPreferences._(this._prefs);

  static Future<AppPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences._(prefs);
  }

  void loadStore(CustomerStore store) {
    final String? raw;
    try {
      raw = _prefs.getString(_customersKey);
    } catch (_) {
      return;
    }
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) store.loadFromJson(decoded);
    } catch (_) {
      return;
    }
  }

  Future<void> saveStore(CustomerStore store) {
    return _prefs.setString(_customersKey, jsonEncode(store.toJson()));
  }

  List<Customer> loadLocalCustomers() {
    final String? raw;
    try {
      raw = _prefs.getString(_customersKey);
    } catch (_) {
      return const [];
    }
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => Customer.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  bool get customersImported {
    try {
      return _prefs.getBool(_customersImportedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> markCustomersImported() {
    return _prefs.setBool(_customersImportedKey, true);
  }

  ThemeMode loadThemeMode() {
    final String? stored;
    try {
      stored = _prefs.getString(_themeKey);
    } catch (_) {
      return ThemeMode.light;
    }
    return stored == ThemeMode.dark.name ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> saveThemeMode(ThemeMode mode) {
    return _prefs.setString(_themeKey, mode.name);
  }
}
