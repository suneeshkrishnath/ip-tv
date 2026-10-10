sealed class AppFailure {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.cause});
}

final class PlaylistParsingFailure extends AppFailure {
  const PlaylistParsingFailure(super.message, {super.cause});
}

final class PlaylistValidationFailure extends AppFailure {
  const PlaylistValidationFailure(super.message, {super.cause});
}

final class CacheFailure extends AppFailure {
  const CacheFailure(super.message, {super.cause});
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.cause});
}