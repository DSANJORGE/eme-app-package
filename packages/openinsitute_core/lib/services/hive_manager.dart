
import 'package:hive_flutter/hive_flutter.dart';

class HiveManager {
  static const assets = "assets";
  static const hivechatrooms = "chatrooms";

  HiveManager._();

  static HiveManager instance = HiveManager._();

  Future<void> init() async {
   await Hive.initFlutter();
  }

  Future<Box> openHiveBox(String boxString) async {
     return await Hive.openBox(boxString);
  }

  Future<Box> setBox(String boxString) async {
    if (Hive.isBoxOpen(boxString)){
    return Hive.box(boxString);
    } 
    return await openHiveBox(boxString);
  }
  
  Future<void> saveData(String id, dynamic data, String boxString) async {
    Box box;
    box = await setBox(boxString);
    box.put(id, data); 
  }

  Future<dynamic> getData(String id,String boxString) async {
    Box box;
    box = await setBox(boxString);
    return box.get(id); 
  }

  Future<bool> isExist(String id,String boxString) async {
    Box box;
    box = await setBox(boxString);
    return box.containsKey(id); 
  }

  Future<void> clear(String boxString) async {
    Box box;
    box = await setBox(boxString);
    box.clear();
  }

  Future<List<Map<String, dynamic>>> getAllHits(String boxString) async {
    Box box;
    box = await setBox(boxString);
    List<Map<String, dynamic>> list = [];
     for (var element in box.keys) {
      if(element != "lastsync" && element != "total") {
          Map<String, dynamic> newdata = (Map<String, dynamic>.from(box.get(element)));
       list.add(newdata);
      }
     }
    return list;
  }
}