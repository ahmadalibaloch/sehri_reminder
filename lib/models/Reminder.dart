import 'dart:convert';
import 'dart:core';

import 'package:sehrireminder/models/ReminderAlarm.dart';

class Reminder {
  String id;
  String name;
  bool enabled;
  List<String> reminderBefores;

  /// we keep generated AlarmIds mapping to skip decryption of alarm 32 bit int from long uniqueId to get back alarmBefore and reminderId
  List<int> alarmIds;
  DateTime date;

  Reminder({this.id, this.name, this.enabled, this.reminderBefores, this.date});

  List<ReminderAlarm> getReminderAlarms() {
    List<ReminderAlarm> reminderAlarms = [];
    for (int i = 0; i < reminderBefores.length; i++) {
      reminderAlarms.add(getReminderAlarmByReminderBeforeIndex(i));
    }
    // add alarm for exact time
    reminderAlarms
        .add(new ReminderAlarm(datetime: date, alarmId: alarmIds.last));
    return reminderAlarms;
  }

  void generateAlarmIds() {
    alarmIds = [];
    this.reminderBefores.forEach((String reminderBefore) {
      var reminderBeforeCode = getReminderBeforeCodes(reminderBefore);
      int idNum =
          int.parse('${reminderBeforeCode[0]}${reminderBeforeCode[1]}$id');
      alarmIds.add(getShortAlarmId(idNum));
    });
    // push an alarmId for exact time match
    alarmIds.add(getShortAlarmId(int.parse(id)));
  }

  DateTime getReminderBeforeTime(int index) {
    if (index == reminderBefores.length) {
      // return exact date
      return this.date;
    }
    return this.date.add(getDurationFromReminderBeforeCode(
        getReminderBeforeCodes(reminderBefores[index])));
  }

  ReminderAlarm getReminderAlarmByReminderBeforeIndex(int index){
    return new ReminderAlarm(datetime: getReminderBeforeTime(index), alarmId: alarmIds[index]);
  }

  Reminder.parse(var strOrMap) {
    Map<String, dynamic> reminderMap =
        strOrMap is String ? jsonDecode(strOrMap) : strOrMap;
    id = reminderMap['id'] ?? '';
    name = reminderMap['name'];
    enabled = reminderMap['enabled'] is String
        ? reminderMap['enabled'] == "true" || reminderMap['enabled'] == ""
        : reminderMap['enabled'];
    date = reminderMap['date'] is DateTime
        ? reminderMap['date']
        : DateTime.parse(reminderMap['date']);
    if (reminderMap['reminderBefores'] is String) {
      reminderMap['reminderBefores'] =
          jsonDecode(reminderMap['reminderBefores']);
    }
    reminderBefores = new List<String>.from(reminderMap['reminderBefores']);
    var alarmIdsDynamic = reminderMap['alarmIds'];
    if (alarmIdsDynamic is String) {
      alarmIdsDynamic = jsonDecode(alarmIdsDynamic);
    }
    if (alarmIdsDynamic != null) {
      alarmIds = new List<int>.from(alarmIdsDynamic);
    } else {
      alarmIds = [];
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
        'reminderBefores': jsonEncode(reminderBefores),
        'alarmIds': jsonEncode(alarmIds),
        'date': date.toIso8601String(),
      };

  toStr() {
    String reminder = jsonEncode(this.toJson());
    return reminder;
  }

  toMap() {
    Map<String, dynamic> reminder = {
      'id': id ?? '',
      'name': name ?? '',
      'enabled': enabled ?? '',
      'reminderBefores': reminderBefores ?? [],
      // 'alarmIds': alarmIds ?? [], not needed in usages
      'date': date ?? DateTime.now(),
    };
    return reminder;
  }

  static getShortAlarmId(int alarmId) {
    if (alarmId.bitLength >= 32) {
      return (alarmId - (alarmId % 9999999)) ~/ 9999999;
    } else {
      return alarmId;
    }
  }

  static String getReminderUniqueId() {
    var d = DateTime.now();
    return '${d.second}${d.minute}${d.hour}${d.day}${d.month}${d.year.toString().substring(2, 4)}';
  }

  static List<int> getReminderBeforeCodes(String reminderBefore) {
    var prefix = int.parse(reminderBefore.split(' ')[0]);
    var postfix = reminderBefore.split(' ')[1];
    switch (postfix) {
      case 'min':
        return [prefix, 2];
      case 'hour':
        return [prefix, 3];
      default:
        return [0, 0];
    }
  }

  static getDurationFromReminderBeforeCode(List<int> reminderBeforeCode) {
    var prefix = reminderBeforeCode[0];
    var postfix = reminderBeforeCode[1];
    if (postfix == 2) {
      return new Duration(minutes: -prefix);
    } else if (postfix == 3) {
      return new Duration(hours: -prefix);
    }
  }
}

// {id: 123, name: 123, reminder_befores: [1 hour], date: 2020-05-03 08:00:00.000}
