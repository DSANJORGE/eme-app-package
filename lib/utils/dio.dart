import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

class DioUtil {
  static late CookieJar _cookieJar;
  static late Dio _dio;
  static Dio get dio => _dio;

  static Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
  }

  static Future<void> init() async {
    _dio = Dio(BaseOptions(validateStatus: (status) => true));

    if (kIsWeb) {
      _cookieJar = CookieJar();
      // Browsers handle cookies automatically; 
      // we initialize an in-memory CookieJar to avoid null errors.
    } else {
      final dir = await getApplicationSupportDirectory();
      _cookieJar = PersistCookieJar(
        storage: FileStorage('${dir.path}/.cookies/'),
      );
      _dio.interceptors.add(CookieManager(_cookieJar));
    }
  }
}
