import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class DioUtil {
  static late CookieJar _cookieJar;
  static late Dio _dio;
  static Dio get dio => _dio;

  static Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/.cookies/'),
    );
    _dio = Dio(BaseOptions(validateStatus: (status) => true));
    _dio.interceptors.add(CookieManager(_cookieJar));
  }
}
