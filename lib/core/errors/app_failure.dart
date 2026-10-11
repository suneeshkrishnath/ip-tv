import 'package:dio/dio.dart';

sealed class AppFailure {
  const AppFailure(this.message, {required this.code, this.cause});

  final String message;

  /// Short identifier users can quote when reporting a problem.
  final String code;
  final Object? cause;

  String get userMessage => '$message (Error code: $code)';
}

/// Plain-language reason and code for a failed HTTP request.
({String reason, String code}) describeDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return (
        reason: 'the server took too long to respond. Please try again.',
        code: 'NET-TIMEOUT',
      );
    case DioExceptionType.connectionError:
      return (
        reason: 'no internet connection or the server is unreachable.',
        code: 'NET-OFFLINE',
      );
    case DioExceptionType.badCertificate:
      return (
        reason: 'a secure connection could not be established.',
        code: 'NET-TLS',
      );
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode ?? 0;
      final reason = switch (status) {
        404 => 'it was not found. It may have moved or been removed.',
        401 || 403 => 'access was denied by the server.',
        >= 500 => 'the server has a problem. Try again later.',
        _ => 'the server sent an unexpected response.',
      };
      return (reason: reason, code: 'NET-HTTP-$status');
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return (reason: 'a network error occurred.', code: 'NET-UNKNOWN');
  }
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(
    super.message, {
    super.cause,
    String code = 'NET-UNKNOWN',
  }) : super(code: code);

  factory NetworkFailure.fromDio(String subject, DioException error) {
    final info = describeDioError(error);
    return NetworkFailure(
      '$subject: ${info.reason}',
      cause: error,
      code: info.code,
    );
  }
}

final class PlaylistParsingFailure extends AppFailure {
  const PlaylistParsingFailure(super.message, {super.cause})
    : super(code: 'PLS-PARSE');
}

final class PlaylistValidationFailure extends AppFailure {
  const PlaylistValidationFailure(super.message, {super.cause})
    : super(code: 'PLS-VALID');
}

final class CacheFailure extends AppFailure {
  const CacheFailure(super.message, {super.cause}) : super(code: 'CACHE-001');
}

final class EpgFailure extends AppFailure {
  const EpgFailure(super.message, {super.cause, String code = 'EPG-001'})
    : super(code: code);

  factory EpgFailure.fromDio(DioException error) {
    final info = describeDioError(error);
    return EpgFailure(
      'Unable to download the TV guide: ${info.reason}',
      cause: error,
      code: 'EPG-${info.code}',
    );
  }
}

final class PlaybackFailure extends AppFailure {
  const PlaybackFailure(super.message, {super.cause})
    : super(code: 'PLAY-001');
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.cause}) : super(code: 'UNK-001');
}
