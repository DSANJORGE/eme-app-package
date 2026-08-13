library openinsitute_core;

import 'dart:async' show Future, TimeoutException;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:openinsitute_core/Helper/custom_exception.dart';
import 'package:openinsitute_core/Helper/request_type.dart';
import 'package:openinsitute_core/services/hive_manager.dart';
import 'package:openinsitute_core/services/oi_chat_manager.dart';

class OpenI {
  late final Map _settings;
  OiChatManager? chatManager;

  Future<void> initialize({required String appSettingsPath}) async {
    String json = await rootBundle.loadString(appSettingsPath);
    _settings = jsonDecode(json);

    await HiveManager.instance.init();
    Get.put<OpenI>(this, permanent: true);
    chatManager = OiChatManager();
    Get.put<OiChatManager>(chatManager!, permanent: true);
  }

  Map get app {
    String appmode = _settings["devmode"];
    if ("dev" == appmode) {
      return _settings["dev"];
    } else {
      return _settings["prod"];
    }
  }

  Map get settings {
    return _settings;
  }

  String handleTokenKey(String token) {
    return token;
  }

  //Generic post method to entermedias server
  Future<Map?> postEntermedia(String url, dynamic jsonBody,
      {String customError = "An Error Occured"}) async {
    //Set headers
    Map<String, String> headers = <String, String>{};
    headers.addAll({"X-tokentype": "entermedia"});
    headers.addAll({"Content-type": "application/json"});

    //make API post
    final response = await httpRequest(
      requestUrl: url,
      body: json.encode(jsonBody),
      headers: headers,
      requestType: RequestType.post,
      customError: customError,
    );
    if (response != null && response.statusCode == 200) {
      final String responseString = response.body;
      debugPrint("Success user info is: $responseString");
      return json.decode(responseString);
    } else {
      return null;
    }
  }

  //Generic post method to entermedias server
  Future<String> getEmResponse(
      String url, dynamic jsonBody, RequestType requestType,
      {String customError = "An Error Occured"}) async {
    //Set headers
    Map<String, String> headers = <String, String>{};
    headers.addAll({"X-tokentype": "entermedia"});
    headers.addAll({"Content-type": "application/json"});

    final response = await httpRequest(
      requestUrl: url,
      body: json.encode(jsonBody),
      headers: headers,
      requestType: requestType,
      customError: customError,
    );
    if (response != null && response.statusCode == 200) {
      final String responseString = response.body;
      debugPrint("Success user info is: $responseString");
      return responseString;
    } else {
      return "{}";
    }
  }

  Future<http.Response?> httpRequest({
    required String requestUrl,
    required dynamic body,
    required Map<String, String> headers,
    required RequestType requestType,
    String customError = "Some Error",
  }) async {
    String url = requestUrl;
    debugPrint(url);
    http.Response response;
    try {
      http.Response? responseJson;
      if (requestType == RequestType.put) {
        responseJson = await http.put(
          Uri.parse(url),
          body: body,
          headers: headers,
        );
      } else if (requestType == RequestType.post) {
        responseJson = await http.post(
          Uri.parse(url),
          body: body,
          headers: headers,
        );
      } else if (requestType == RequestType.get) {
        responseJson = await http.get(
          Uri.parse(url),
          headers: headers,
        );
      } else if (requestType == RequestType.delete) {
        responseJson = await http.delete(
          Uri.parse(url),
          headers: headers,
          body: body,
        );
      }
      debugPrint('${responseJson!.statusCode}');
      response = await handleException(responseJson);
      return response;
    } on BadRequestException catch (_) {
      // showErrorFlushbar( "Bad request! Please try again later.");
    } on UnauthorisedException catch (_) {
      //showErrorFlushbar( "Unauthorized user. Please try again.");
    } on TimeoutException catch (_) {
      //showErrorFlushbar(context, "Request timed out. Please try again!");
    } on SocketException catch (_) {
      // showErrorFlushbar(context, "Unable to connect to server. Please try again!");
    } on HttpException catch (_) {
      // showErrorFlushbar(
      //  context, customError != null ? customError : "Error occurred while communication with server. Please try again after some time.");
    }
    return null;
  }

  dynamic handleException(http.Response response) {
    debugPrint("Response code: ${response.statusCode}");
    switch (response.statusCode) {
      case 200:
        final http.Response responseJson = response;
        return responseJson;
      case 201:
        final http.Response responseJson = response;
        return responseJson;
      case 302:
        break;
      case 400:
        throw BadRequestException(response.body.toString());
      case 403:
        throw UnauthorisedException(response.body.toString());
      case 408:
        throw TimeoutException(response.body.toString());
      case 500:
        throw HttpException(response.body.toString());
      default:
        // throw FetchDataException('Error occurred while Communication with Server with StatusCode : ${response.statusCode}');
        break;
    }
  }

  // void registerBinaries() {
  //     final dartToolDir = path.join(Directory.current.path, '.dart_tool');
  //     try {
  //       Isar.initializeLibraries(
  //         libraries: {
  //           'windows': path.join(dartToolDir, 'libisar_windows_x64.dll'),
  //           'macos': path.join(dartToolDir, 'libisar_macos_x64.dylib'),
  //           'linux': path.join(dartToolDir, 'libisar_linux_x64.so'),
  //         },
  //       );
  //     } catch (e) {
  //       // ignore. maybe this is an instrumentation test
  //     }
  //
  // }

  // Future<List<Contact>> testIstarSave() async {
  //   registerBinaries();
  //   final dir = await getApplicationSupportDirectory();
  //
  //   final isar = await Isar.open(
  //     schemas: [ContactSchema],
  //     directory: dir.path,
  //   );
  //
  //   final contact = Contact()
  //     ..name = "My first contact";
  //
  //   await isar.writeTxn((isar) async {
  //     contact.id = await isar.contacts.put(contact) ;
  //   });
  //
  //   final allContacts = await isar.contacts.where().findAll();
  //   debugPrint(allContacts);
  //   return allContacts;
  //
  // }
}
