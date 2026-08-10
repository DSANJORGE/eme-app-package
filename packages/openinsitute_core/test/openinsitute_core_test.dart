import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:openinsitute_core/models/em_data.dart';
import 'package:openinsitute_core/models/em_user.dart';
import 'package:openinsitute_core/models/task_list.dart';
import 'package:openinsitute_core/openinsitute_core.dart';
import 'package:openinsitute_core/services/em_data_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); //Nasty!
  final oi = OpenI();
  Get.put<OpenI>(oi);
  oi.initialize();
  HttpOverrides.global =
      _MyHttpOverrides(); // Setting a customer override that'll use an unmocked HTTP client

  test('Load Settings', () async {
    Map? settings = await oi.loadAppSettings();
    expect(settings!.isNotEmpty, true);

    // Map<String, dynamic> datatest  = await oi.hiveTest();;
    // expect(datatest.isNotEmpty, true);

    var url = "${settings['dev']?['websocket_url']}";

    expect(url.isNotEmpty, true);
    EmUser? user = await oi.authenticationManager?.login("admin", "admin");
    if (user != null) {
      // var email = user.email;
      expect(true, true);
    }
    // bool? emailed = await oi.emEmailKey("support@openedit.org");
    // expect(emailed, true);

    Map simplesearch = {
      "page": "1",
      "hitsperpage": "20",
      "query": {
        "terms": [
          {"field": "id", "operation": "matches", "value": "*"}
        ]
      }
    };

    List<EmData> listsearch =
        await (await oi.datamanager.getDataModule("purpose"))
            .getRemoteData(simplesearch);
    expect(listsearch.isNotEmpty, true);

    // List<emData> checkcache =
    (await oi.datamanager.getDataModule("purpose")).getAllHits();

    expect(user != null, true);

    List<ToDo>? tasks = await oi.taskManager?.getOpenTasks();
    expect(tasks != null, true);
    if (tasks != null) {
      expect(tasks.isNotEmpty, true);
      ToDo list = tasks.first;
      expect(list.tasks!.isNotEmpty, true);
    }

//    List<Task> tasks = oi.getOpenTasks();
  });

  // test('Server Data Query', () async {
  //
  //   EmUser? user = await oi.login("admin", "admin");
  //   expect(user != null, true);
  //   Map chatsearch = {
  //     "runpath": "/services/some/command",
  //     "channel": "123",
  //     "user":"456"
  //   };
  //   // HitTracker hits = oi.dataManager.execute(chatsearch);
  // //
  //
  //
  // });

  test('Test Websocket Connection', () async {
    EmUser? user = await oi.authenticationManager?.login("admin", "admin");
    expect(user != null, true);

    oi.emSocketManager.connect();
    oi.emSocketManager.sendString("keepalive");
    oi.emSocketManager.sendMessage({"keepalive": "true"});

    await Future.delayed(const Duration(seconds: 20), () {});
  });
  test('Test Module Crud Operations', () async {
    DataModule testmodule = await oi.dataManager!.getDataModule("purpose");
    List<EmData> hits = testmodule.getAllHits();
    expect(hits.isNotEmpty, true);

    Map tosave = {"name": "Test"};

    EmData saved = await testmodule.addData(tosave);
    testmodule.deleteData(saved.id);
  });

  test('Test Project CHat loading', () async {
    EmUser? user = await oi.authenticationManager?.login("admin", "admin");
    expect(user != null, true);

    Map? settings = await oi.loadAppSettings();

    var projects = await oi.projectManager?.getUserProjects(1);
    expect(projects!.isNotEmpty, true);

    var projectid = settings?['dev']?['test_collection_id'];
    var messages = await oi.chatManager?.getProjectChatMessages(projectid, 1);
    expect(messages!.length > 5, true);

    //Create new chat

    //oi.chatManager?.saveMessage()
  });

  // test('Test Loading and Syncing Data', () async {
  //   Searcher searcher = await oi.datamanager.getSearcher("purpose");
  //   List<emData> checkcache = searcher.getAllHits();
  //
  // });
}

//https://timm.preetz.name/articles/http-request-flutter-test

class _MyHttpOverrides extends HttpOverrides {}
