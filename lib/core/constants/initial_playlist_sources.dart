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
  PlaylistSource(
    id: 'tamil',
    name: 'Tamil',
    url: 'https://iptv-org.github.io/iptv/languages/tam.m3u',
    isBuiltIn: true,
  ),
  PlaylistSource(
    id: 'kannada',
    name: 'Kannada',
    url: 'https://iptv-org.github.io/iptv/languages/kan.m3u',
    isBuiltIn: true,
  ),
  PlaylistSource(
    id: 'telugu',
    name: 'Telugu',
    url: 'https://iptv-org.github.io/iptv/languages/tel.m3u',
    isBuiltIn: true,
  ),
  PlaylistSource(
    id: 'hindi',
    name: 'Hindi',
    url: 'https://iptv-org.github.io/iptv/languages/hin.m3u',
    isBuiltIn: true,
  ),
  PlaylistSource(
    id: 'english',
    name: 'English',
    url: 'https://iptv-org.github.io/iptv/languages/eng.m3u',
    isBuiltIn: true,
  ),
  PlaylistSource(
    id: 'sports',
    name: 'Sports',
    url: 'https://iptv-org.github.io/iptv/categories/sports.m3u',
    isBuiltIn: true,
  ),
];