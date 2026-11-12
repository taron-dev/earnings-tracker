import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:earnings_tracker/api/unauthorized_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with the given status code, without touching the network.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{}',
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  late int unauthorizedCalls;

  Dio dioAnswering(int statusCode) {
    unauthorizedCalls = 0;
    return Dio()
      ..httpClientAdapter = _StatusAdapter(statusCode)
      ..interceptors.add(
        UnauthorizedInterceptor(onUnauthorized: () => unauthorizedCalls++),
      );
  }

  test('reports 401 and still fails the request', () async {
    final dio = dioAnswering(401);

    await expectLater(
      dio.get<void>('/api/work-logs'),
      throwsA(isA<DioException>()),
    );
    expect(unauthorizedCalls, 1);
  });

  for (final status in [404, 409, 500]) {
    test('ignores $status', () async {
      final dio = dioAnswering(status);

      await expectLater(
        dio.get<void>('/api/work-logs'),
        throwsA(isA<DioException>()),
      );
      expect(unauthorizedCalls, 0);
    });
  }
}
