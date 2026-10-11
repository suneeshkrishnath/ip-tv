import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';

const initialPlaylistSources = [
  PlaylistSource(
    id: 'malayalam',
    name: 'Malayalam',
    url: 'https://iptv-org.github.io/iptv/languages/mal.m3u',
    isBuiltIn: true,
  ),
  PlaylistSource(
    id: 'all',
    name: 'All channels',
    url: 'https://iptv-org.github.io/iptv/index.m3u',
    isBuiltIn: true,
  ),
];