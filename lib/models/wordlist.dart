class Wordlist {
  final int? id;
  final String name;
  final DateTime createdAt;
  List<String> words;

  Wordlist({
    this.id,
    required this.name,
    required this.createdAt,
    this.words = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Wordlist.fromMap(Map<String, dynamic> map, {List<String>? words}) {
    return Wordlist(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      words: words ?? [],
    );
  }

  Wordlist copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    List<String>? words,
  }) {
    return Wordlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      words: words ?? this.words,
    );
  }
}
