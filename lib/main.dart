import 'dart:math';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sehri_reminder_app/reminderStorage.dart';
import 'package:sehri_reminder_app/textToSpeech.dart';
import 'package:intl/intl.dart';

import 'alarmForm.dart';
import 'models/Reminder.dart';
import 'models/ReminderAlarm.dart';
import 'package:logger/logger.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

var printer = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sehri Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Sehri Reminder Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Reminder> reminders = <Reminder>[];

  @override
  void initState() {
    super.initState();
    // removeContent();
    loadReminders();


    setPrayerReminders();

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
      reminders[index].enabled = value;
    });
    writeContent(reminders);
  }

  void btnAddReminderClick(Reminder reminderInput, {index = -1}) async {
    Reminder reminder = await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Add Reminder"),
        content: AddReminderForm(reminder: reminderInput),
      ),
    );
    if (reminder == null) {
      // dialog dismissed
      return;
    }
    reminder.generateAlarmIds();
    setState(() {
      if (index == -1) {
        reminders.add(reminder);
      } else {
        reminders[index] = reminder;
      }
    });
    writeContent(reminders);
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
        onPressed: () => btnAddReminderClick(Reminder(
            id: Reminder.getReminderUniqueId(),
            name: 'h',
            enabled: true,
            date: DateTime.now().add(const Duration(minutes: 1)),
            reminderBefores: [])),
        tooltip: 'Add Reminder',
        child: const Icon(Icons.add),
      ),
    );
  }

  confirmDelete(int index) async {
    var result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Do you want to remove this reminder?'),
        actions: <Widget>[
          FlatButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FlatButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (result) {
      setState(() {
        reminders.removeAt(index);
      });
      writeContent(reminders);
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
  TextToSpeech tts = TextToSpeech();
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
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =  AndroidInitializationSettings('ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);


  // final localNotifications = FlutterLocalNotificationsPlugin()
  //   ..initialize(
  //     const InitializationSettings(
  //       android: AndroidInitializationSettings('ic_launcher'),
  //     ),
  //   );

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'sehri_reminder',
        'sehri_reminder',
        // 'sehri reminder with pre event alarms'
      ),
    ),
  );
}

void setOneShotAlarm(ReminderAlarm reminderAlarm) {
  if (reminderAlarm.datetime.millisecondsSinceEpoch <
      DateTime.now().millisecondsSinceEpoch) {
    printer.w('Alarm reminder occurred with past time ${reminderAlarm.alarmId}');
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
