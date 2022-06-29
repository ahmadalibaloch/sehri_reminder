import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sehri_reminder_app/main.dart';
import 'package:sehri_reminder_app/prayerTimes.dart';

import 'models/Reminder.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

const dataFileName = 'reminders.txt';

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/$dataFileName');
}

Future<List<Reminder>> addUpdatePrayerReminders() async {
  var prayerReminders = await readContent();
  Map<String, dynamic> prayerTimes = await getPrayerTimes();
  for (var prayerName in [
    "fajr",
    "sunrise",
    "dhuhr",
    "asr",
    "maghrib",
    "isha"
  ]) {
    var reminderIndex =
        prayerReminders.indexWhere((Reminder r) => r.name == prayerName);
    if (reminderIndex == -1) {
      Reminder prayerReminder = Reminder(
          id: Reminder.getReminderUniqueId(),
          name: prayerName,
          enabled: true,
          reminderBefores: ["5 min"],
          date: prayerTimes[prayerName]);
      prayerReminder.adjustPastDate();
      prayerReminder.generateAlarmIds();
      prayerReminders.add(prayerReminder);
    } else {
      Reminder prayerReminder = prayerReminders[reminderIndex];
      prayerReminder.date = prayerTimes[prayerName];
      prayerReminder.adjustPastDate();
      prayerReminder.generateAlarmIds();
    }
  }
  await writeContent(prayerReminders);
  return prayerReminders;
}

///
/// This method will an array with reminder, reminderBefore string and the index of the reminder before
///
getAlarmBeforeInfoFromAlarmId(List<Reminder> reminders, int alarmId) {
  for (int i = 0; i < reminders.length; i++) {
    var reminder = reminders[i];
    int? index = reminder.alarmIds.indexOf(alarmId);
    if (index == null) {
      printer.w(
          'index null for alarmIDs ${reminder.alarmIds} alarmId$alarmId reminderId:${reminder.id}');
    }
    if (index != -1) {
      // CONDITION EXACT
      if (reminder.reminderBefores.length == index) {
        // we push an alarmId for exact dateTime or 0 alarmBefore
        // this is that match, handle null for exact time has reached
        return [reminder, null, index];
      }
      return [reminder, reminder.reminderBefores[index].toString(), index];
    }
  }
  return [null, null, null];
}

removeContent() async {
  try {
    final file = await _localFile;
    // Read the file
    return await file.delete();
  } catch (e) {
    logger.e('Remove Content Error', e);
    return null;
  }
}

Future<List<Reminder>> readContent() async {
  try {
    final file = await _localFile;
    // Read the file
    String contents = await file.readAsString();
    // Returning the contents of the file
    var lines = contents.split('\n').where((String l) => l.isNotEmpty);
    var reminders =
        lines.map<Reminder>((line) => Reminder.parse(line)).toList();
    return reminders;
  } catch (e) {
    logger.e('Read Content Error', e);
    return [];
  }
}

Future<File> writeContent(List<Reminder> reminders) async {
  final file = await _localFile;
  // Write the file
  String contents =
      reminders.fold('', (strValue, rem) => '$strValue\n' + rem.toStr());
  try {
    return file.writeAsString(contents);
  } catch (e) {
    logger.e('Write Content Error', e);
    return file;
  }
}
