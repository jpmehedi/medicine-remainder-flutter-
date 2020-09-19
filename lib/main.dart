import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  runApp(MyApp());
  await AndroidAlarmManager.initialize();

  print("AndroidAlarmManager initialized!");
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(title: 'Alarm App'),
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
  int _counter = 0;
  bool switch_value = false;
  final String _kNotificationsPrefs = "allowNotifications";
  TimeOfDay _time = TimeOfDay.now();
  TimeOfDay picked;

  DateTime _dateTime = DateTime.now();
  Timer _timer;

  var alarmId = 0;

  bool play = true;
  int flag = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getAllowsNotifications();
    _updateTime();
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      // Update once per minute. If you want to update every second, use the
      // following code.
//      _timer = Timer(
//        Duration(minutes: 1) -
//            Duration(seconds: _dateTime.second) -
//            Duration(milliseconds: _dateTime.millisecond),
//        _updateTime,
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
      // Update once per second, but make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
//       _timer = Timer(
//         Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
//         _updateTime,
//       );

      if (_dateTime.minute == _time.minute &&
          _dateTime.hour == _time.hour &&
          flag == 0 &&
          switch_value) {
        print(play);
        flag++;
        if (flag == 1) {
          //FlutterRingtonePlayer.playRingtone();
          FlutterRingtonePlayer.play(
            android: AndroidSounds.alarm,
            ios: IosSounds.glass,
            looping: true, // Android only - API >= 28
            volume: 0.1, // Android only - API >= 28
            asAlarm: true, // Android only - all APIs
          );
        }
        //this.play = false;
      } else if (_dateTime.minute != _time.minute ||
          _dateTime.hour != _time.hour) {
        FlutterRingtonePlayer.stop();
        flag = 0;
      }
    });
  }

  Future<bool> getAllowsNotifications() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_kNotificationsPrefs) ?? false;
  }

  Future<bool> setAllowsNotifications(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setBool(_kNotificationsPrefs, switch_value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
          padding: EdgeInsets.only(top: 20),
          child: Card(
            child: ListTile(
              leading: Icon(Icons.timer),
              title: GestureDetector(
                child: Text(
                  "${_time.hour}:${_time.minute}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  selectTime(context);
                },
              ),
              subtitle: Text(
                "Cycle: Every Day",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Switch(
                value: switch_value,
                onChanged: (bool state) {
                  setState(
                    () {
                      this.switch_value = state;
                      print(switch_value);
                      setAllowsNotifications(switch_value);
                      if (switch_value) {
                        FlutterRingtonePlayer.play(
                          android: AndroidSounds.notification,
                          ios: IosSounds.glass,
                          looping: false, // Android only - API >= 28
                          volume: 0.1, // Android only - API >= 28
                          asAlarm: false, // Android only - all APIs
                        );
                      } else {
                        FlutterRingtonePlayer.stop();
                      }
                    },
                  );
                },
              ),
            ),
            elevation: 10,
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        tooltip: 'Set Alarm',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<Null> selectTime(BuildContext context) async {
    picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );

    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
      });
    }
  }

  Future<Null> alarm(BuildContext context) async {
    print("hello");
    await AndroidAlarmManager.periodic(
        const Duration(minutes: 1), alarmId, printHello);
  }

  void printHello() {
    final DateTime now = DateTime.now();
    final int isolateId = Isolate.current.hashCode;
    print("[$now] Hello, world! isolate=${isolateId} function='$printHello'");
  }
}
