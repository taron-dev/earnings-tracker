import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A canned backend answer.
typedef FakeResponse = ({int status, Object? body});

/// Stands in for the network in API tests: records each request and answers with [respond].
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.respond);

  final FakeResponse Function(RequestOptions request) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final response = respond(options);
    return ResponseBody.fromString(
      response.body == null ? '' : jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A [Dio] that never leaves the process.
Dio fakeDio(FakeHttpAdapter adapter) => Dio()..httpClientAdapter = adapter;
