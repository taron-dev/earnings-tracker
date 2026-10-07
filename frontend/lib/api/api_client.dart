import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// HTTP client for our Spring backend; attaches the current Supabase access token to every request.
final Dio apiClient = Dio(BaseOptions(baseUrl: Config.apiBaseUrl))
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
