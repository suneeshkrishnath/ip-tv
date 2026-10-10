import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';

void main() {
  const channels = [
    Channel(
      id: 'news',
      name: 'World News',
      streamUrl: 'https://example.test/news.m3u8',
      category: 'News',
    ),
    Channel(
      id: 'sports',
      name: 'World Sports',
      streamUrl: 'https://example.test/sports.m3u8',
      category: 'Sports',
    ),
  ];

  test('filters case-insensitively by channel and category', () {
    expect(
      filterChannels(channels, query: 'WORLD').map((channel) => channel.id),
      ['news', 'sports'],
    );
    expect(
      filterChannels(channels, query: '', category: 'News')
          .map((channel) => channel.id),
      ['news'],
    );
    expect(
      filterChannels(channels, query: 'sports', category: 'News'),
      isEmpty,
    );
  });
}