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

  Future<void> delete(int id) async {
    await _repo.delete(id);
    _wordlists.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  Future<Wordlist?> getById(int id) async {
    return await _repo.getById(id);
  }
}
