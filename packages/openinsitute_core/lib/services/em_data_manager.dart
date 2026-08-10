import 'dart:convert';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:openinsitute_core/Helper/request_type.dart';
import 'package:openinsitute_core/models/em_data.dart';
import 'package:openinsitute_core/openinsitute_core.dart';

OpenI get oi {
  return Get.find();
}

class DataManager {
  bool initalized = false;
  Map<String, DataModule> searchers = {};

  DataManager();

  Future<DataModule> getDataModule(String inSearchType) async {
    DataModule? searcher = searchers[inSearchType];
    if (searcher == null) {
      searcher = await DataModule.createDataModule(inSearchType);
      searchers[inSearchType] = searcher;
    }
    //https://stackoverflow.com/questions/53886304/understanding-factory-constructor-code-example-dart do this?
    return searcher;
  }
}

class DataModule {
  //https://stackoverflow.com/questions/54549235/dart-await-on-constructor

  late String searchtype;
  late Box box;
  bool cache = true;

  DataModule._();

  static Future<DataModule> createDataModule(String inSearchType) async {
    var searcher = DataModule._();
    searcher.searchtype = inSearchType;
    searcher.box = await searcher.getBox(inSearchType);
    return searcher;
  }

  DataModule(this.searchtype);

  Future<Box> getBox(String inType) async {
    if (!Hive.isBoxOpen(inType)) {
      return await Hive.openBox(inType);
    } else {
      return Hive.box(inType);
    }
  }

  Future<EmData?> loadData(String id) async {
    if (id.isNotEmpty) {
      Map<String, dynamic> props = box.get(id);
      return EmData.fromJson(props);
    } else {
      // Map simplesearch = {
      //   "page": "1",
      //   "hitsperpage": "20",
      //   "query": {
      //     "terms": [
      //       {"field": "id", "operation": "matches", "value": "*"}
      //     ]
      //   }
      // };
    }
    return null;
  }

  List<EmData> getAllHits() {
    List<EmData> list = [];
    // List list = List.generate(box.keys.length, ,{"growable":true});
    for (var element in box.keys) {
      EmData newdata =
          EmData.fromJson(box.get(element) as Map<String, dynamic>);
      list.add(newdata);
    }
    return list;
  }

  Future<bool> syncData(bool full, int page) async {
    if (full) {
      await box.clear();

      Map simplesearch = {
        "page": "$page",
        "hitsperpage": "20",
        "query": {
          "terms": [
            {"field": "id", "operation": "matches", "value": "*"}
          ]
        }
      };

      List<EmData> tosave = await getRemoteData(simplesearch);
      for (var element in tosave) {
        box.put(element.id, element.properties);
      }
      //check if there are more pages of hits and run next search
    } else {
      // DateTime lastsync = box.get("lastsync");
      // Map aftersearch = {
      //   "page": "1",
      //   "hitsperpage": "20",
      //   "query": {
      //     "terms": [
      //       {"field": "id", "operation": "matches", "value": "*"},
      //       {
      //         "field": "emrecordstatus.recordmodificationdate",
      //         "operation": "after",
      //         "value": lastsync.toIso8601String()
      //       }
      //     ]
      //   }
      // };

      // List<emData> tosave =
      await getRemoteData({"emrecorddate???? neeed to chec": "*"});
    }
    box.put("lastsync", DateTime.now());
    return true;
  }

  Future<List<EmData>> getRemoteData(
    Map inQuery,
  ) async {
    final responsestring = await oi.getEmResponse(
        oi.app!["mediadb"] + '/services/module/$searchtype/search',
        inQuery,
        RequestType.get);
    List<EmData> results = parseData(responsestring);

    for (var element in results) {
      box.put(element.id, element.properties);
    }
    return results;
    //return compute(parseData, responsestring);  Figure this out, it keeps everything responsive
  }

  Future<List<EmData>> updateData(String id, Map inQurey) async {
    final responsestring = await oi.getEmResponse(
        oi.app!["mediadb"] + '/services/module/$searchtype/data/$id',
        inQurey,
        RequestType.put);
    List<EmData> results = parseData(responsestring);
    for (var element in results) {
      box.put(element.id, element.properties);
    }
    return results;
  }

  Future<EmData> deleteData(String? id) async {
    final responsestring = await oi.getEmResponse(
        oi.app!["mediadb"] + '/services/module/$searchtype/data/$id',
        {},
        RequestType.delete);
    EmData results = parseDataSingle(responsestring);

    box.delete(results.id);
    return results;
  }

  Future<EmData> addData(Map inQuery) async {
    final responsestring = await oi.getEmResponse(
        oi.app!["mediadb"] + '/services/module/$searchtype/create',
        inQuery,
        RequestType.post);
    EmData results = parseDataSingle(responsestring);

    box.put(results.id, results.properties);
    return results;
  }

  Future<EmData> saveData(String id) async {
    final responsestring = await oi.getEmResponse(
        oi.app!["mediadb"] + '/services/module/$searchtype/data/$id',
        {},
        RequestType.get);
    EmData results = parseDataSingle(responsestring);
    box.put(results.id, results.properties);
    return results;
  }

  List<EmData> parseData(String responseBody) {
    final Map<String, dynamic> parsed = json.decode(responseBody);
    List<EmData> results =
        parsed["results"].map<EmData>((json) => EmData.fromJson(json)).toList();
    return results;
  }

  EmData parseDataSingle(String responseBody) {
    final Map<String, dynamic> parsed = json.decode(responseBody);
    EmData results = EmData.fromJson(parsed);
    return results;
  }

  Stream<EmData> updates() async* {
    Stream<dynamic> stream = oi.emSocketManager.stream;
    await for (final data in stream) {
      json.decode(data);
    }
  }
}
