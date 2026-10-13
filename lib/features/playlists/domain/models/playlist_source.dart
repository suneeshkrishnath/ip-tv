class PlaylistSource {
  const PlaylistSource({
    required this.id,
    required this.name,
    required this.url,
    this.epgUrl,
    this.isBuiltIn = false,
  });

  factory PlaylistSource.fromJson(Map<String, dynamic> json) => PlaylistSource(
    id: json['id'] as String,
    name: json['name'] as String,
    url: json['url'] as String,
    epgUrl: json['epgUrl'] as String?,
  );

  final String id;
  final String name;
  final String url;

  /// Optional XMLTV guide URL for this playlist.
  final String? epgUrl;

  /// Built-in sources cannot be edited or deleted.
  final bool isBuiltIn;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    if (epgUrl != null) 'epgUrl': epgUrl,
  };

  @override
  bool operator ==(Object other) =>
      other is PlaylistSource &&
      other.id == id &&
      other.name == name &&
      other.url == url &&
      other.epgUrl == epgUrl;

  @override
  int get hashCode => Object.hash(id, name, url, epgUrl);
}