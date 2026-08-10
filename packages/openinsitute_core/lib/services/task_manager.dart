import 'dart:convert';

import 'package:openinsitute_core/Helper/request_type.dart';
import 'package:openinsitute_core/models/task_list.dart';
import 'package:openinsitute_core/openinsitute_core.dart';
import 'package:get/get.dart';

class TaskManager {
  OpenI get oi {
    return Get.find();
  }

  Future<List<ToDo>> getOpenTasks() async {
    final responsestring = await oi.getEmResponse(
        oi.app!["mediadb"] + '/services/users/tasks/mytasks.json',
        {"goaltrackerstaff": "admin"},
        RequestType.post);
    Map<String, dynamic> results = json.decode(responsestring);
    return results["tickets"].map<ToDo>((json) => ToDo.fromJson(json)).toList();
  }
}
