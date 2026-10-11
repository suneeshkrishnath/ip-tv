import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

abstract interface class EpgRemoteDataSource {
  Future<String> fetch(String epgUrl);
}

class DioEpgRemoteDataSource implements EpgRemoteDataSource {
  const DioEpgRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<String> fetch(String epgUrl) async {
    final response = await _dio.get<List<int>>(
      epgUrl,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    var bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('Guide response was empty.');
    }
    final isGzip = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
    if (isGzip) bytes = gzip.decode(bytes);
    return utf8.decode(bytes, allowMalformed: true);
  }
}
