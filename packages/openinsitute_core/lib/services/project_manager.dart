import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:openinsitute_core/models/em_data.dart';
import 'package:openinsitute_core/openinsitute_core.dart';

class ProjectManager {
  OpenI get oi {
    return Get.find();
  }

  Future<List> getUserProjects(int page) async {
    Map params = {"page": "$page", "hitsperpage": "200"};

    var box = await getBox("oicache");
    var results = box.get("viewprojects"); //Some cache system
    if (results == null) {
      results = <EmData>[]; //Make one list that is cached
      box.put("viewprojects", results);
    }

    final Map? responded = await oi.postEntermedia(
      oi.app!["mediadb"] +
          '/services/module/librarycollection/viewprojects.json',
      params,
    );

    List<EmData> messages = responded!["results"]!
        .map<EmData>((json) => EmData.fromJson(json))
        .toList();
    box.put("pages", responded["response"]["pages"]);
    results.clear();
    results.addAll(messages);
    box.put("viewprojects", results);
    return Future.value(results);
  }
}

Future<Box> getBox(String inType) async {
  if (!Hive.isBoxOpen(inType)) {
    return Hive.openBox(inType);
  } else {
    return Hive.box(inType);
  }
}
