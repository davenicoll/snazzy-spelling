class Wordlist {
  final int? id;
  final String name;
  final DateTime createdAt;
  final bool isCompleted;
  List<String> words;

  Wordlist({
    this.id,
    required this.name,
    required this.createdAt,
    this.isCompleted = false,
    this.words = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory Wordlist.fromMap(Map<String, dynamic> map, {List<String>? words}) {
    return Wordlist(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      words: words ?? [],
    );
  }

  Wordlist copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    bool? isCompleted,
    List<String>? words,
  }) {
    return Wordlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      words: words ?? this.words,
    );
  }

  /// Returns true if the Test action should be gated (disabled) given the
  /// global "require all flashcards viewed" setting and the set of words
  /// already viewed as flashcards. Pure/derivable so it can be unit-tested
  /// without the DB or UI.
  bool isTestGated({
    required bool requireFullFlashcardView,
    required Set<String> viewedWords,
  }) {
    if (!requireFullFlashcardView) return false;
    if (words.isEmpty) return false;
    for (final w in words) {
      if (!viewedWords.contains(w)) return true;
    }
    return false;
  }
}
