import 'package:flutter/material.dart';
import 'package:Habbiton/screens/main_screen.dart';

void main() {
  runApp(HabitTrackerApp());
}



class HabitTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Habit Tracker',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        brightness: Brightness.light, //Light Theme
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.dark, //Dark Theme
      ),
      themeMode: ThemeMode.system,
      home: HabitTrackerScreen(),
    );
  }
}

