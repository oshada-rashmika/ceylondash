import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPreferencesService {
  static const String _recentSearchesKey = 'recent_searches';
  static const String _frequentShopsKey = 'frequent_shops';

  static final SearchPreferencesService _instance =
      SearchPreferencesService._internal();

  factory SearchPreferencesService() {
    return _instance;
  }

  SearchPreferencesService._internal();

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList(_recentSearchesKey) ?? [];
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > 5) {
      searches = searches.sublist(0, 5);
    }

    await prefs.setStringList(_recentSearchesKey, searches);
  }

  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }

  Future<List<String>> getFrequentShopIds() async {
    final prefs = await SharedPreferences.getInstance();
    final String? shopsJson = prefs.getString(_frequentShopsKey);

    if (shopsJson == null) return [];

    try {
      final Map<String, dynamic> decoded = json.decode(shopsJson);
      final Map<String, int> shopCounts = decoded.map(
        (key, value) => MapEntry(key, value as int),
      );
      final sortedEntries = shopCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedEntries.map((e) => e.key).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> incrementShopVisit(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? shopsJson = prefs.getString(_frequentShopsKey);

    Map<String, int> shopCounts = {};
    if (shopsJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(shopsJson);
        shopCounts = decoded.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        // Ignore JSON parse errors
      }
    }

    shopCounts[shopId] = (shopCounts[shopId] ?? 0) + 1;

    await prefs.setString(_frequentShopsKey, json.encode(shopCounts));
  }
}