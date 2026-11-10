/// Returns [name], or else the first of at(2), at(3), ... that is not [taken], as the Finder names copies.
String firstFree(
  String name,
  bool Function(String) taken,
  String Function(int n) at,
) {
  for (var n = 2; taken(name); n++) {
    name = at(n);
  }
  return name;
}
