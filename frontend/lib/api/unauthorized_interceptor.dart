import 'package:dio/dio.dart';

/// Calls [onUnauthorized] when the backend answers 401, then lets the error through so the
/// caller still sees the request fail.
///
/// `supabase_flutter` refreshes tokens on its own, so 401 means the session is truly gone.
class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor({required this.onUnauthorized});

  final void Function() onUnauthorized;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized();
    }
    handler.next(err);
  }
}
