import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';


class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  List<String> _selectedDays = [];
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  final List<String> _weekDays = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"];
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeTimezone();
    _loadSettings();
    _initializeNotifications();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }


  void _initializeTimezone() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      _selectedDays = prefs.getStringList('selectedDays') ?? [];
      int hour = prefs.getInt('hour') ?? 8;
      int minute = prefs.getInt('minute') ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setStringList('selectedDays', _selectedDays);
    await prefs.setInt('hour', _selectedTime.hour);
    await prefs.setInt('minute', _selectedTime.minute);

    if (_notificationsEnabled) {
      _scheduleNotifications();
    } else {
      _cancelNotifications();
    }
  }


  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/habbiton_icon2');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
      },
    );
  }

  Future<void> _scheduleNotifications() async {
    await _cancelNotifications();

    for (String day in _selectedDays) {
      int dayIndex = _weekDays.indexOf(day) + 1;
      tz.TZDateTime scheduledTime = _nextInstanceOfSelectedTime(dayIndex);

      try {
        await _notificationsPlugin.zonedSchedule(
          dayIndex,
          'Habbiton',
          'Schön fleißig gewesen? 😊',
          scheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_notify',
              'Daily Notifications',
              channelDescription: 'Erinnerung für tägliche Aufgaben',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );

      } catch (e) {
      }
    }
  }




  Future<void> _cancelNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfSelectedTime(int weekday) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }



  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(cancelText: "Abbruch",helpText: "Uhrzeit auswählen",
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Einstellungen")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text("Benachrichtigungen aktivieren"),
              value: _notificationsEnabled,
              onChanged: (value) {
                _requestPermissions();
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Text("Wochentage auswählen:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 10,
              children: _weekDays.map((day) {
                return ChoiceChip(
                  label: Text(day),
                  selected: _selectedDays.contains(day),
                  onSelected: _notificationsEnabled
                      ? (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text("Uhrzeit auswählen: ${_selectedTime.format(context)}"),
              trailing: Icon(Icons.access_time),
              enabled: _notificationsEnabled,
              onTap: () => _notificationsEnabled ? _pickTime(context) : null,
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _requestPermissions();
                  await _saveSettings();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Benachrichtigung erstellt"),duration: Duration(milliseconds: 2000),));
                },
                child: Text("Änderungen übernehmen"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
