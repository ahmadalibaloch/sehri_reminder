import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:sehri_reminder_app/main.dart';

import 'models/Reminder.dart';

// Create a Form widget.
class AddReminderForm extends StatefulWidget {
  final Reminder reminder;

  const AddReminderForm({required this.reminder});

  @override
  AddReminderFormState createState() {
    return AddReminderFormState();
  }
}

class AddReminderFormState extends State<AddReminderForm> {
  bool autoValidate = true;
  bool readOnly = false;
  final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();
  final ValueChanged _onChanged = (val) => printer.i(val,'form state');

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          FormBuilder(
            // context,
            key: _fbKey,
            autovalidateMode: AutovalidateMode.disabled,
            initialValue: widget.reminder.toMap(),
            // readOnly: readOnly,
            child: Column(
              children: <Widget>[
                FormBuilderFilterChip(
                  name: 'reminderBefores',
                  // attribute: 'reminderBefores',
                  decoration: const InputDecoration(
                    labelText: 'Select times to remind before',
                  ),
                  options: const [
                    FormBuilderChipOption(value: '5 min', child: Text('5 Min')),
                    FormBuilderChipOption(
                        value: '10 min', child: Text('10 Min')),
                    FormBuilderChipOption(
                        value: '15 min', child: Text('15 Min')),
                    FormBuilderChipOption(
                        value: '30 min', child: Text('30 Min')),
                    FormBuilderChipOption(
                        value: '45 min', child: Text('45 Min')),
                    FormBuilderChipOption(
                        value: '1 hour', child: Text('1 Hour')),
                  ],
                ),
                FormBuilderDateTimePicker(
                  name: "date",
                  onChanged: _onChanged,
                  inputType: InputType.both,
                  decoration: const InputDecoration(
                    labelText: "Time",
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    (val) {
                      if ((val?.millisecondsSinceEpoch ?? 0) <
                          DateTime.now().millisecondsSinceEpoch) {
                        return 'Time can\'t be in past';
                      }
                      return null;
                    }
                  ]),
                  initialTime: const TimeOfDay(hour: 8, minute: 0),
                  // initialValue: DateTime.now(),
                  // readonly: true,
                ),
                FormBuilderTextField(
                  name: "name",
                  decoration: const InputDecoration(
                    labelText: "Reminder name",
                  ),
                  onChanged: _onChanged,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.max(70),
                  ]),
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
                  child: const Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    if (_fbKey.currentState?.saveAndValidate() ?? false) {
                      var addReminderForm = context.widget as AddReminderForm;
                      Map<String, dynamic> reminderMap = {};
                      reminderMap.addAll(addReminderForm.reminder.toMap());
                      reminderMap.addAll(_fbKey.currentState!.value);
                      Navigator.pop(context, Reminder.parse(reminderMap));
                    } else {
                      printer.w("validation failed");
                      printer.i(_fbKey.currentState?.value);
                    }
                  },
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(
                child: MaterialButton(
                  color: Theme.of(context).accentColor,
                  child: const Text(
                    "Reset",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    _fbKey.currentState?.reset();
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
