import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Singleton Dio client configured for TMDB API
class ApiClient {
  ApiClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _create();
    return _instance!;
  }

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.tmdbBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        queryParameters: {
          'api_key': ApiConstants.tmdbApiKey,
          'language': 'en-US',
        },
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );

    return dio;
  }
}

// ignore: avoid_print
void debugPrint(String msg) => print('[FreeWatch] $msg');
