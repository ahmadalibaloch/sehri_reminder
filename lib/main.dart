import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sehrireminder/TextToSpeech.dart';
import 'package:sehrireminder/models/Reminder.dart';
import 'package:sehrireminder/models/reminderStorage.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';

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
      title: 'Flutter Demo',
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

final String portName = "sehriPort";

void alarmHit(id) async {
  var reminders = await readContent();
  var returnValue = getReminderFromAlarmId(reminders, id);
  var reminderName = returnValue[0].name;
  var alarmBefore = returnValue[1];
  alarmBefore = alarmBefore.toString().replaceAll('min', 'minutes');
  TextToSpeech tts = new TextToSpeech();
  var text = '$alarmBefore remaining from $reminderName';
  if (alarmBefore == 'null') {
    text = 'It is time for $reminderName';
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
        'channel_id',
        'channel_name',
        'channel_description',
      ),
      null,
    ),
  );
}

class _MyHomePageState extends State<MyHomePage> {
  List<Reminder> reminders = new List<Reminder>();

  @override
  void initState() {
    super.initState();
    //removeContent();
    loadReminders();
    AndroidAlarmManager.initialize();
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
      AndroidAlarmManager.oneShotAt(
        reminderAlarm.datetime,
        reminderAlarm.alarmId,
        alarmHit,
        allowWhileIdle: true,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
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
                title: Text(reminder.name),
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
        content: new Text('Do you want to remove this item?'),
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
