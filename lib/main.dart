import 'dart:core';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sehrireminder/models/ReminderAlarm.dart';
import 'package:sehrireminder/reminderStorage.dart';
import 'package:sehrireminder/textToSpeech.dart';
import 'package:sehrireminder/models/Reminder.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:intl/intl.dart';

import 'alarmForm.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sehri Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Sehri Reminder'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Reminder> reminders = new List<Reminder>();

  @override
  void initState() {
    super.initState();
    removeContent();
    //loadReminders();
    setPrayerReminders();
    //AndroidAlarmManager.initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void loadReminders() async {
    var reminders = await readContent();
    setState(() {
      this.reminders.addAll(reminders);
    });
  }

  void setPrayerReminders() async {
    var reminders = await addUpdatePrayerReminders();
    setState(() {
      this.reminders = reminders;
    });
  }

  void setReminderEnabled(index, value) {
    setState(() {
      this.reminders[index].enabled = value;
    });
    writeContent(this.reminders);
  }

  void btnAddReminderClick(Reminder reminderInput, {index = -1}) async {
    Reminder reminder = await showDialog(
        context: context,
        child: new AlertDialog(
          title: new Text("Add Reminder"),
          content: new AddReminderForm(reminder: reminderInput),
        ));
    if (reminder == null) {
      // dialog dismissed
      return;
    }
    reminder.generateAlarmIds();
    setState(() {
      if (index == -1) {
        this.reminders.add(reminder);
      } else {
        this.reminders[index] = reminder;
      }
    });
    writeContent(this.reminders);
    reminder.getReminderAlarms().forEach((reminderAlarm) {
      setOneShotAlarm(reminderAlarm);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: reminders.length,
            itemBuilder: (BuildContext context, int index) {
              var reminder = reminders[index];
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 0),
                onLongPress: () => {confirmDelete(index)},
                onTap: () => btnAddReminderClick(reminder, index: index),
                leading: Checkbox(
                  value: reminder.enabled,
                  onChanged: (value) => {
                    setReminderEnabled(index, value),
                  },
                ),
                title: Text(
                    '${reminder.name} ${DateFormat("hh:mm MMM dd").format(reminder.date)}'),
                subtitle: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: reminder.reminderBefores
                          .map((rb) => Chip(label: Text(rb)))
                          .toList(),
                    )),
              );
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => btnAddReminderClick(new Reminder(
            id: Reminder.getReminderUniqueId(),
            name: 'h',
            enabled: true,
            date: DateTime.now().add(new Duration(minutes: 1)),
            reminderBefores: [])),
        tooltip: 'Add Reminder',
        child: Icon(Icons.add),
      ),
    );
  }

  confirmDelete(int index) async {
    var result = await showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Confirmation'),
        content: new Text('Do you want to remove this reminder?'),
        actions: <Widget>[
          new FlatButton(
            onPressed: () => Navigator.pop(context, false),
            child: new Text('No'),
          ),
          new FlatButton(
            onPressed: () => Navigator.pop(context, true),
            child: new Text('Yes'),
          ),
        ],
      ),
    );
    if (result) {
      setState(() {
        this.reminders.removeAt(index);
      });
      writeContent(this.reminders);
    }
  }
}

void alarmHit(alarmId) async {
  var reminders = await readContent();
  var reminderBeforeInfo = getAlarmBeforeInfoFromAlarmId(reminders, alarmId);
  Reminder theReminder = reminderBeforeInfo[0];
  String reminderBeforeStr = reminderBeforeInfo[1];
  int reminderBeforeIndex = reminderBeforeInfo[2];

  DateTime reminderBeforeDateTime =
      theReminder.getReminderBeforeTime(reminderBeforeIndex);

  // TODO: the current reminder may be need to be updated for correct new time,
  // TODO: for example location might have changed for sunset new time
  // set alarm for next occurrence,
  setOneShotAlarm(
      theReminder.getReminderAlarmByReminderBeforeIndex(reminderBeforeIndex));
  // if reminder time has passed (within one minute)
  if (reminderBeforeDateTime.millisecondsSinceEpoch + 60000 <
      DateTime.now().millisecondsSinceEpoch) {
    // ignore current occurrence firing of notification
    return;
  }

  // speak reminder and show notification
  TextToSpeech tts = new TextToSpeech();
  var reminderName = theReminder.name;
  var text = '';
  if (reminderBeforeStr == null) {
    text = 'It is time for $reminderName';
  } else {
    reminderBeforeStr = reminderBeforeStr.replaceAll('min', 'minutes');
    text = '$reminderBeforeStr remaining from $reminderName';
  }
  tts.speak(text);
  showNotification(reminderName, text);
}

void showNotification(title, body) async {
  final localNotifications = FlutterLocalNotificationsPlugin()
    ..initialize(
      InitializationSettings(
        AndroidInitializationSettings('ic_launcher'),
        null,
      ),
    );

  await localNotifications.show(
    Random().nextInt(999999999),
    title,
    body,
    NotificationDetails(
      AndroidNotificationDetails(
        'sehri_reminder',
        'sehri_reminder',
        'sehri reminder with pre event alarms',
      ),
      null,
    ),
  );
}

void setOneShotAlarm(ReminderAlarm reminderAlarm) {
  if (reminderAlarm.datetime.millisecondsSinceEpoch <
      DateTime.now().millisecondsSinceEpoch) {
    print('Alarm reminder occurred with past time ${reminderAlarm.alarmId}');
    return;
  }
  AndroidAlarmManager.oneShotAt(
    reminderAlarm.datetime,
    reminderAlarm.alarmId,
    alarmHit,
    allowWhileIdle: true,
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
  );
}
