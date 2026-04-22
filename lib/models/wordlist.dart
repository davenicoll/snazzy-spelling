class Wordlist {
  final int? id;
  final String name;
  final DateTime createdAt;
  final bool requireFullFlashcardView;
  List<String> words;

  Wordlist({
    this.id,
    required this.name,
    required this.createdAt,
    this.requireFullFlashcardView = false,
    this.words = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'require_full_flashcard_view': requireFullFlashcardView ? 1 : 0,
    };
  }

  factory Wordlist.fromMap(Map<String, dynamic> map, {List<String>? words}) {
    return Wordlist(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      requireFullFlashcardView:
          (map['require_full_flashcard_view'] as int? ?? 0) == 1,
      words: words ?? [],
    );
  }

  Wordlist copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    bool? requireFullFlashcardView,
    List<String>? words,
  }) {
    return Wordlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      requireFullFlashcardView:
          requireFullFlashcardView ?? this.requireFullFlashcardView,
      words: words ?? this.words,
    );
  }

  /// Returns true if the Test action should be gated (disabled) given the
  /// wordlist's admin option and the set of words already viewed as flashcards.
  /// Pure/derivable so it can be unit-tested without the DB or UI.
  bool isTestGated(Set<String> viewedWords) {
    if (!requireFullFlashcardView) return false;
    if (words.isEmpty) return false;
    for (final w in words) {
      if (!viewedWords.contains(w)) return true;
    }
    return false;
  }
}
