import 'package:flutter/foundation.dart';
import '../models/wordlist.dart';
import '../repositories/settings_repository.dart';
import '../repositories/wordlist_repository.dart';

enum SortField { alphabetical, createdAt }
enum SortDirection { ascending, descending }

/// Settings key used to persist the main-list "Hide completed" preference.
/// Shared with tests so the storage key is asserted, not hard-coded.
const String kHideCompletedSettingKey = 'wordlist:hideCompleted';

class WordlistProvider extends ChangeNotifier {
  final WordlistRepository _repo;
  final SettingsRepository _settings;
  List<Wordlist> _wordlists = [];
  SortField _sortField = SortField.createdAt;
  SortDirection _sortDirection = SortDirection.descending;
  bool _hideCompleted = true;

  /// Cache of viewed-word sets keyed by wordlist id. Screens read from this
  /// and listen for changes so the "test" button can unlock without reload.
  final Map<int, Set<String>> _viewedWords = {};

  WordlistProvider({
    WordlistRepository? repository,
    SettingsRepository? settingsRepository,
  })  : _repo = repository ?? WordlistRepository(),
        _settings = settingsRepository ?? SettingsRepository();

  List<Wordlist> get wordlists =>
      filterAndSortWordlists(_wordlists, _sortField, _sortDirection,
          hideCompleted: _hideCompleted);
  SortField get sortField => _sortField;
  SortDirection get sortDirection => _sortDirection;
  bool get hideCompleted => _hideCompleted;

  /// True when at least one wordlist exists in the backing store, regardless
  /// of whether the current filter hides all of them. Used by the main
  /// screen to decide between the empty-state and the list UI — we don't
  /// want the "No wordlists yet" placeholder to flash just because the user
  /// has hidden completed ones.
  bool get hasWordlists => _wordlists.isNotEmpty;

  void toggleSort(SortField field) {
    if (_sortField == field) {
      _sortDirection = _sortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
    } else {
      _sortField = field;
      _sortDirection = SortDirection.ascending;
    }
    notifyListeners();
  }

  Future<void> setHideCompleted(bool value) async {
    if (_hideCompleted == value) return;
    _hideCompleted = value;
    notifyListeners();
    await _settings.setSetting(
      kHideCompletedSettingKey,
      value.toString(),
    );
  }

  Future<void> load() async {
    _wordlists = await _repo.getAll();
    final stored = await _settings.getSetting(kHideCompletedSettingKey);
    // Default to hiding completed when nothing has been stored yet.
    _hideCompleted = stored == null ? true : stored != 'false';
    notifyListeners();
  }

  Future<Wordlist> create(String name, List<String> words) async {
    final wordlist = await _repo.create(name, words);
    _wordlists.add(wordlist);
    notifyListeners();
    return wordlist;
  }

  Future<void> update(int id, String name, List<String> words) async {
    await _repo.update(id, name, words);
    await load();
  }

  Future<void> setCompleted(int id, bool isCompleted) async {
    await _repo.setCompleted(id, isCompleted);
    final index = _wordlists.indexWhere((w) => w.id == id);
    if (index != -1) {
      _wordlists[index] = _wordlists[index].copyWith(isCompleted: isCompleted);
    }
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    _wordlists.removeWhere((w) => w.id == id);
    _viewedWords.remove(id);
    notifyListeners();
  }

  Future<Wordlist?> getById(int id) async {
    return await _repo.getById(id);
  }

  /// Returns the cached set of viewed words for a wordlist, or an empty set
  /// if nothing has been loaded yet. Callers that need the up-to-date value
  /// should call [loadViewedWords] first.
  Set<String> viewedWords(int wordlistId) =>
      _viewedWords[wordlistId] ?? const <String>{};

  Future<Set<String>> loadViewedWords(int wordlistId) async {
    final viewed = await _repo.getViewedWords(wordlistId);
    _viewedWords[wordlistId] = viewed;
    notifyListeners();
    return viewed;
  }

  Future<void> recordFlashcardView(int wordlistId, String word) async {
    final existing = _viewedWords[wordlistId] ?? <String>{};
    if (existing.contains(word)) {
      // Already recorded — no state change, no DB churn.
      return;
    }
    await _repo.recordView(wordlistId, word);
    existing.add(word);
    _viewedWords[wordlistId] = existing;
    notifyListeners();
  }
}

/// Pure function: apply the hide-completed filter then sort. Exposed for
/// direct unit testing without needing a provider or a database.
List<Wordlist> filterAndSortWordlists(
  List<Wordlist> source,
  SortField field,
  SortDirection direction, {
  required bool hideCompleted,
}) {
  final filtered = hideCompleted
      ? source.where((w) => !w.isCompleted).toList()
      : List<Wordlist>.from(source);
  filtered.sort((a, b) {
    final int comparison;
    if (field == SortField.alphabetical) {
      comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    } else {
      comparison = a.createdAt.compareTo(b.createdAt);
    }
    return direction == SortDirection.ascending ? comparison : -comparison;
  });
  return filtered;
}
