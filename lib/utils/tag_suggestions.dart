/// Collects unique tags from [sources] for one-tap suggestions.
///
/// Tags are deduplicated case-insensitively, ordered by how often they occur
/// (most used first), then alphabetically. The spelling of the first
/// occurrence is kept.
List<String> collectTagSuggestions(Iterable<Iterable<String>> sources) {
  final counts = <String, int>{};
  final spellings = <String, String>{};
  for (final tags in sources) {
    for (final raw in tags) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
      spellings.putIfAbsent(key, () => name);
    }
  }
  final keys = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return [for (final key in keys) spellings[key]!];
}
