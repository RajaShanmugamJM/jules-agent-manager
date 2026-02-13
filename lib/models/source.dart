class Source {
  final String
  name; // The resource name (e.g., projects/foo/locations/bar/sources/baz)
  final String displayName;
  final String url; // GitHub repo URL

  Source({required this.name, required this.displayName, required this.url});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      name: json['name'] as String,
      displayName: json['displayName'] as String? ?? json['name'] as String,
      url: json['url'] as String? ?? '',
    );
  }
}
