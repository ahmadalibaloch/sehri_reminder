import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sehrireminder/models/Reminder.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  print(directory.path);
  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/reminders.txt');
}

getReminderFromAlarmId(List<Reminder> reminders, int alarmId) {
  for (int i = 0; i < reminders.length; i++) {
    var reminder = reminders[i];
    int index = reminder.alarmIds?.indexOf(alarmId);
    if (index == null) {
      print(
          'indexx null for alarmIDs ${reminder.alarmIds} alarmId$alarmId reminderId:${reminder.id}');
    }
    if (index != null && index != -1) {
      if (reminder.reminderBefores.length == index) {
        // we push an alarmId for exact dateTime or 0 alarmBefore
        // this is that match, handle null for exact time has reached
        return [reminder, null];
      }
      return [reminder, reminder.reminderBefores[index]];
    }
  }
  return [null, null];
}

removeContent() async {
  try {
    final file = await _localFile;
    // Read the file
    return await file.delete();
  } catch (e) {
    // If encountering an error, return
    return null;
  }
}

Future<List<Reminder>> readContent() async {
  try {
    final file = await _localFile;
    // Read the file
    String contents = await file.readAsString();
    // Returning the contents of the file
    var lines = contents.split('\n').where((String l) => l.length > 0);
    var reminders =
        lines.map<Reminder>((line) => Reminder.parse(line)).toList();
    return reminders;
  } catch (e) {
    // If encountering an error, return
    return [];
  }
}

Future<File> writeContent(List<Reminder> reminders) async {
  final file = await _localFile;
  // Write the file
  String contents =
      reminders.fold('', (strValue, rem) => strValue + '\n' + rem.toStr());
  return file.writeAsString(contents);
}
