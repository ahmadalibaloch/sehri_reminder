import 'dart:convert';
import 'dart:core';

import 'ReminderAlarm.dart';

class Reminder {
  String id;
  String name;
  bool enabled;
  List<String> reminderBefores;

  /// we keep generated AlarmIds mapping to skip decryption of alarm 32 bit int from long uniqueId to get back alarmBefore and reminderId
  late List<int> alarmIds;
  DateTime date;

  Reminder(
      {required this.id,
      required this.name,
      required this.enabled,
      required this.reminderBefores,
      required this.date});

  List<ReminderAlarm> getReminderAlarms() {
    List<ReminderAlarm> reminderAlarms = [];
    for (int i = 0; i < reminderBefores.length; i++) {
      reminderAlarms.add(getReminderAlarmByReminderBeforeIndex(i));
    }
    // add alarm for exact time, remember the last alarmId refers to sharp or exact target time
    reminderAlarms.add(ReminderAlarm(datetime: date, alarmId: alarmIds.last));
    return reminderAlarms;
  }

  /// if date is in past, set it to tomorrow
  DateTime adjustPastDate(){
    if(date.millisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch){
      var d = date;
      // set date to tomorrow
      date = DateTime(d.year,d.month,d.day,d.hour,d.minute,d.second).add(const Duration(days: 1));
    }
    return date;
  }

  void generateAlarmIds() {
    alarmIds = [];
    for (var reminderBefore in reminderBefores) {
      var reminderBeforeCode = getReminderBeforeCodes(reminderBefore);
      int idNum =
          int.parse('${reminderBeforeCode[0]}${reminderBeforeCode[1]}$id');
      alarmIds.add(getShortAlarmId(idNum));
    }
    // keeping last alarmID as the target time of alarm
    // like 5 PM alarm with alarm befores will have multiple alarm ids for before times and this ID for 5 PM sharp
    alarmIds.add(getShortAlarmId(int.parse(id)));
  }

  DateTime getReminderBeforeTime(int index) {
    if (index == reminderBefores.length) {
      // last alarmId is the exact match alarm
      // return exact date
      return date;
    }
    return date.add(getDurationFromReminderBeforeCode(
        getReminderBeforeCodes(reminderBefores[index])));
  }

  ReminderAlarm getReminderAlarmByReminderBeforeIndex(int index) {
    return ReminderAlarm(
        datetime: getReminderBeforeTime(index), alarmId: alarmIds[index]);
  }

  factory Reminder.parse(var strOrMap) {
    Map<String, dynamic> reminderMap =
        strOrMap is String ? jsonDecode(strOrMap) : strOrMap;
    var reminder = Reminder(
      id: reminderMap['id'] ?? '',
      name: reminderMap['name'],
      enabled: reminderMap['enabled'] is String
          ? reminderMap['enabled'] == "true" || reminderMap['enabled'] == ""
          : reminderMap['enabled'],
      date: reminderMap['date'] is DateTime
          ? reminderMap['date']
          : DateTime.parse(reminderMap['date']),
      reminderBefores: [],
    );
    if (reminderMap['reminderBefores'] is String) {
      reminderMap['reminderBefores'] =
          jsonDecode(reminderMap['reminderBefores']);
    }
    reminder.reminderBefores =
        List<String>.from(reminderMap['reminderBefores']);
    var alarmIdsDynamic = reminderMap['alarmIds'];
    if (alarmIdsDynamic is String) {
      alarmIdsDynamic = jsonDecode(alarmIdsDynamic);
    }
    reminder.alarmIds = [];
    if (alarmIdsDynamic != null) {
      reminder.alarmIds = List<int>.from(alarmIdsDynamic);
    }
    return reminder;
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
    String reminder = jsonEncode(toJson());
    return reminder;
  }

  toMap() {
    Map<String, dynamic> reminder = {
      'id': id,
      'name': name,
      'enabled': enabled,
      'reminderBefores': reminderBefores,
      // 'alarmIds': alarmIds ?? [], not needed in usages
      'date': date,
    };
    return reminder;
  }

  static getShortAlarmId(int alarmId) {
    // long ids were may be not accepted by android os?
    if (alarmId.bitLength >= 32) {
      return (alarmId - (alarmId % 9999999)) ~/ 9999999;
    } else {
      return alarmId;
    }
  }

  static String getReminderUniqueId() {
    // be careful to keep id same for an alarm to override it when re-registering it to OS alarms, otherwise multiple alarms
    // will raise for a single reminder
    var d = DateTime.now();
    return '${d.second}${d.minute}${d.hour}${d.day}${d.month}${d.year.toString().substring(2, 4)}';
  }

  static const minuteCode = 2;
  static const hourCode = 3;

  /// a time format is given number code like '5 min' equal '5 2' and '1 hour' equals '1 3'
  /// 2 is for minute and 3 is for hour see @minuteCode and @hourCode static constants
  static List<int> getReminderBeforeCodes(String reminderBefore) {
    var prefix = int.parse(reminderBefore.split(' ')[0]);
    var postfix = reminderBefore.split(' ')[1];
    switch (postfix) {
      case 'min':
        return [prefix, minuteCode];
      case 'hour':
        return [prefix, hourCode];
      default:
        return [0, 0];
    }
  }

  /// reminder before coded format is 'value<space>unit code' for example '5 min' was translated to '5 2', and '1 hour' to '1 3'
  /// in code generation, so this method will create Duration from that code
  static getDurationFromReminderBeforeCode(List<int> reminderBeforeCode) {
    var prefix = reminderBeforeCode[0]; // the value part like 5 in '5 min'
    var postfix = reminderBeforeCode[1];// the unit part like 'hour' in '1 hour'
    if (postfix == minuteCode) {
      return Duration(minutes: -prefix);
    } else if (postfix == hourCode) {
      return Duration(hours: -prefix);
    }
  }
}

// {id: 123, name: 123, reminder_befores: [1 hour], date: 2020-05-03 08:00:00.000}
