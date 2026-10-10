import 'package:dio/dio.dart';

abstract interface class PlaylistRemoteDataSource {
  Future<String> fetch(String sourceUrl);
}

class DioPlaylistRemoteDataSource implements PlaylistRemoteDataSource {
  const DioPlaylistRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<String> fetch(String sourceUrl) async {
    final response = await _dio.get<String>(
      sourceUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final content = response.data;
    if (content == null || content.trim().isEmpty) {
      throw const FormatException('Playlist response was empty.');
    }
    return content;
  }
}