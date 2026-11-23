import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer.dart';
import '../models/customer_draft.dart';
import 'customer_store.dart';

class AppPreferences {
  static const _customersKey = 'cipms.customers.v1';
  static const _customersImportedKey = 'cipms.customers.imported.v1';
  static const _themeKey = 'cipms.theme.v1';
  static const _draftsKey = 'cipms.drafts.v1';
  static const _prefEmailKey = 'cipms.prefs.email.v1';
  static const _prefInAppKey = 'cipms.prefs.inapp.v1';

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
    } catch (error) {
      debugPrint('Could not read the saved theme: $error');
      return ThemeMode.light;
    }
    return stored == ThemeMode.dark.name ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      await _prefs.setString(_themeKey, mode.name);
    } catch (error) {
      debugPrint('Could not persist the theme preference: $error');
    }
  }

  /// Unfinished New Customer forms saved on this device.
  List<CustomerDraft> loadDrafts() {
    final String? raw;
    try {
      raw = _prefs.getString(_draftsKey);
    } catch (_) {
      return const [];
    }
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                CustomerDraft.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveDrafts(List<CustomerDraft> drafts) {
    return _prefs.setString(
      _draftsKey,
      jsonEncode(drafts.map((draft) => draft.toJson()).toList()),
    );
  }

  Future<void> upsertDraft(CustomerDraft draft) async {
    final drafts = [...loadDrafts()]
      ..removeWhere((existing) => existing.id == draft.id)
      ..insert(0, draft);
    await _saveDrafts(drafts);
  }

  Future<void> deleteDraft(String draftId) async {
    final drafts = [...loadDrafts()]..removeWhere((d) => d.id == draftId);
    await _saveDrafts(drafts);
  }

  bool loadEmailNotifications() {
    try {
      return _prefs.getBool(_prefEmailKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> saveEmailNotifications(bool value) =>
      _prefs.setBool(_prefEmailKey, value);

  bool loadInAppNotifications() {
    try {
      return _prefs.getBool(_prefInAppKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> saveInAppNotifications(bool value) =>
      _prefs.setBool(_prefInAppKey, value);

  /// Non-critical informational toggles for future features.
  bool loadFlag(String key, {bool defaultValue = false}) {
    try {
      return _prefs.getBool('cipms.flag.$key') ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  Future<void> saveFlag(String key, bool value) =>
      _prefs.setBool('cipms.flag.$key', value);
}
