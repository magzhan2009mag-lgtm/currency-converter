/// Why fresh rates could not be loaded.
///
/// The class is sealed, so a `switch` over it must handle every case; the UI
/// relies on that to pick an icon. [message] is shown to the user as is.
sealed class RatesException implements Exception {
  const RatesException();

  String get message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The request never got an answer: no network, DNS failure, airplane mode,
/// a Wi-Fi login page, or (on the web) a request the browser blocked.
final class NoConnectionException extends RatesException {
  const NoConnectionException([this.cause]);

  /// The original low-level error, kept for logs.
  final Object? cause;

  @override
  String get message => 'Нет подключения к интернету';

  @override
  String toString() => 'NoConnectionException: $cause';
}

/// The connection is there but the server is too slow.
final class RequestTimeoutException extends RatesException {
  const RequestTimeoutException(this.timeout);

  final Duration timeout;

  @override
  String get message => 'Сервер не ответил за ${timeout.inSeconds} с';
}

/// The server answered with an HTTP error status.
final class ServerException extends RatesException {
  const ServerException(this.statusCode);

  final int statusCode;

  @override
  String get message => switch (statusCode) {
    429 => 'Слишком много запросов, попробуйте позже',
    >= 500 => 'Сервер курсов временно недоступен ($statusCode)',
    _ => 'Сервер курсов вернул ошибку $statusCode',
  };
}

/// The server answered 200, but the body is not usable rates.
final class BadResponseException extends RatesException {
  const BadResponseException(this.details);

  /// What exactly was wrong, for logs.
  final String details;

  @override
  String get message => 'Сервер прислал некорректные данные';

  @override
  String toString() => 'BadResponseException: $details';
}
