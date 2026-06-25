import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'mock_api_interceptor.dart';

late final CookieJar globalCookieJar;

Future<void> initCookieJar() async {
  if (!kIsWeb) {
    final appDocDir = await getApplicationDocumentsDirectory();
    globalCookieJar = PersistCookieJar(
      storage: FileStorage('${appDocDir.path}/.cookies/'),
    );
  } else {
    globalCookieJar = CookieJar();
  }
}

final cookieJarProvider = Provider<CookieJar>((ref) => globalCookieJar);

/// Provider holding the current API Base URL reactively.
final baseUrlProvider = StateProvider<String>((ref) {
  return AppConfig.baseUrl;
});

/// Constructs and configures the app-wide [Dio] instance.
///
/// Attaches a [CookieManager] (native only) so the server's `httpOnly` refresh
/// cookie is stored and replayed automatically. On every request the current
/// [authProvider] access token is injected as a `Bearer` header.
/// A 401 response triggers a silent `/auth/refresh` call; on success the
/// original request is retried with the new token. On failure,
/// [AuthNotifier.logout] is called to clear state.
final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  if (!kIsWeb) {
    final cookieJar = ref.watch(cookieJarProvider);
    dio.interceptors.add(CookieManager(cookieJar));
  }

  if (AppConfig.isDemoMode) {
    dio.interceptors.add(MockApiInterceptor());
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authProvider).accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/refresh')) {
          // Attempt to refresh token
          try {
            final response = await dio.post('/api/auth/refresh');
            final newToken = response.data['access_token'];

            if (newToken != null) {
              ref.read(authProvider.notifier).setToken(newToken);

              // Retry the original request
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newToken';

              final retryResponse = await dio.fetch(options);
              return handler.resolve(retryResponse);
            }
          } catch (e) {
            // Refresh failed, logout
            ref.read(authProvider.notifier).logout();
          }
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
});

/// Thin wrapper around [Dio] that exposes typed [get], [post], and [delete]
/// helpers used by every repository in the app.
///
/// Configured via [dioProvider], which attaches the cookie jar, the `Bearer`
/// token interceptor, and the automatic 401 → refresh → retry logic.
class ApiClient {
  final Dio _dio;
  ApiClient(this._dio);

  /// Sends a POST request to [path] with optional JSON [data].
  /// Returns the decoded response body cast to [T].
  Future<T> post<T>(String path, {dynamic data}) async {
    final response = await _dio.post<T>(path, data: data);
    return response.data as T;
  }

  /// Sends a GET request to [path] with optional [queryParameters].
  /// Returns the decoded response body cast to [T].
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get<T>(path, queryParameters: queryParameters);
    return response.data as T;
  }

  /// Sends a PUT request to [path] with optional JSON [data].
  /// Returns the decoded response body cast to [T].
  Future<T> put<T>(String path, {dynamic data}) async {
    final response = await _dio.put<T>(path, data: data);
    return response.data as T;
  }

  /// Sends a DELETE request to [path].
  /// Returns the decoded response body cast to [T].
  Future<T> delete<T>(String path) async {
    final response = await _dio.delete<T>(path);
    return response.data as T;
  }
}

/// Provider that exposes [ApiClient]. Depends on [dioProvider].
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
