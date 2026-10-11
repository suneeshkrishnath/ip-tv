class PlaylistSource {
  const PlaylistSource({
    required this.id,
    required this.name,
    required this.url,
    this.isBuiltIn = false,
  });

  factory PlaylistSource.fromJson(Map<String, dynamic> json) => PlaylistSource(
    id: json['id'] as String,
    name: json['name'] as String,
    url: json['url'] as String,
  );

  final String id;
  final String name;
  final String url;

  /// Built-in sources cannot be edited or deleted.
  final bool isBuiltIn;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'url': url};

  @override
  bool operator ==(Object other) =>
      other is PlaylistSource &&
      other.id == id &&
      other.name == name &&
      other.url == url;

  @override
  int get hashCode => Object.hash(id, name, url);
}