import 'package:flutter/foundation.dart';
import '../models/wordlist.dart';
import '../repositories/wordlist_repository.dart';

enum SortField { alphabetical, createdAt }
enum SortDirection { ascending, descending }

class WordlistProvider extends ChangeNotifier {
  final WordlistRepository _repo = WordlistRepository();
  List<Wordlist> _wordlists = [];
  SortField _sortField = SortField.createdAt;
  SortDirection _sortDirection = SortDirection.descending;

  /// Cache of viewed-word sets keyed by wordlist id. Screens read from this
  /// and listen for changes so the "test" button can unlock without reload.
  final Map<int, Set<String>> _viewedWords = {};

  List<Wordlist> get wordlists => _sortedWordlists();
  SortField get sortField => _sortField;
  SortDirection get sortDirection => _sortDirection;
  bool get hasWordlists => _wordlists.isNotEmpty;

  List<Wordlist> _sortedWordlists() {
    final sorted = List<Wordlist>.from(_wordlists);
    sorted.sort((a, b) {
      int comparison;
      if (_sortField == SortField.alphabetical) {
        comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else {
        comparison = a.createdAt.compareTo(b.createdAt);
      }
      return _sortDirection == SortDirection.ascending
          ? comparison
          : -comparison;
    });
    return sorted;
  }

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

  Future<void> load() async {
    _wordlists = await _repo.getAll();
    notifyListeners();
  }

  Future<Wordlist> create(
    String name,
    List<String> words, {
    bool requireFullFlashcardView = false,
  }) async {
    final wordlist = await _repo.create(
      name,
      words,
      requireFullFlashcardView: requireFullFlashcardView,
    );
    _wordlists.add(wordlist);
    notifyListeners();
    return wordlist;
  }

  Future<void> update(
    int id,
    String name,
    List<String> words, {
    bool requireFullFlashcardView = false,
  }) async {
    await _repo.update(
      id,
      name,
      words,
      requireFullFlashcardView: requireFullFlashcardView,
    );
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
