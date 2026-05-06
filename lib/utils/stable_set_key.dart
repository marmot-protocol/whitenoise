String stableStringSetKey(Set<String> values) {
  final sorted = values.toList()..sort();
  return sorted.join('|');
}
