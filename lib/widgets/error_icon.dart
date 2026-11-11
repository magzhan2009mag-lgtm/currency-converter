import 'package:flutter/material.dart';

import '../data/rates_exception.dart';

/// [RatesException] is sealed, so adding a new kind of error without an
/// icon here is a compile error, not a silent gap.
IconData iconFor(RatesException error) => switch (error) {
  NoConnectionException() => Icons.wifi_off_rounded,
  RequestTimeoutException() => Icons.hourglass_bottom_rounded,
  ServerException() => Icons.cloud_off_rounded,
  BadResponseException() => Icons.report_gmailerrorred_rounded,
};
