import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:sehrireminder/models/Reminder.dart';
import 'package:sehrireminder/models/reminderStorage.dart';

// Create a Form widget.
class AddReminderForm extends StatefulWidget {
  final Reminder reminder;

  AddReminderForm({this.reminder});

  @override
  AddReminderFormState createState() {
    return AddReminderFormState();
  }
}

class AddReminderFormState extends State<AddReminderForm> {
  var data;
  bool autoValidate = true;
  bool readOnly = false;
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  ValueChanged _onChanged = (val) => print(val);

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          FormBuilder(
            // context,
            key: _fbKey,
            autovalidate: false,
            initialValue: widget.reminder.toMap(),
            readOnly: readOnly,
            child: Column(
              children: <Widget>[
                FormBuilderFilterChip(
                  attribute: 'reminderBefores',
                  decoration: InputDecoration(
                    labelText: 'Select times to remind before',
                  ),
                  options: [
                    FormBuilderFieldOption(
                        value: '5 min', child: Text('5 Min')),
                    FormBuilderFieldOption(
                        value: '10 min', child: Text('10 Min')),
                    FormBuilderFieldOption(
                        value: '15 min', child: Text('15 Min')),
                    FormBuilderFieldOption(
                        value: '30 min', child: Text('30 Min')),
                    FormBuilderFieldOption(
                        value: '45 min', child: Text('45 Min')),
                    FormBuilderFieldOption(
                        value: '1 hour', child: Text('1 Hour')),
                  ],
                ),
                FormBuilderDateTimePicker(
                  attribute: "date",
                  onChanged: _onChanged,
                  inputType: InputType.both,
                  decoration: InputDecoration(
                    labelText: "Time",
                  ),
                  validator: (val) => null,
                  validators: [
                    FormBuilderValidators.required(),
                  ],
                  initialTime: TimeOfDay(hour: 8, minute: 0),
                  // initialValue: DateTime.now(),
                  // readonly: true,
                ),
                FormBuilderTextField(
                  attribute: "name",
                  decoration: InputDecoration(
                    labelText: "Reminder name",
                  ),
                  onChanged: _onChanged,
                  validators: [
                    FormBuilderValidators.required(),
                    FormBuilderValidators.max(70),
                  ],
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: MaterialButton(
                  color: Theme.of(context).accentColor,
                  child: Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    if (_fbKey.currentState.saveAndValidate()) {
                      Navigator.pop(
                          context, Reminder.parse(_fbKey.currentState.value));
                    } else {
                      print(_fbKey.currentState.value);
                      print("validation failed");
                    }
                  },
                ),
              ),
              SizedBox(
                width: 20,
              ),
              Expanded(
                child: MaterialButton(
                  color: Theme.of(context).accentColor,
                  child: Text(
                    "Reset",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    _fbKey.currentState.reset();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
