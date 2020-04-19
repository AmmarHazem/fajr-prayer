import 'package:flutter/material.dart';
import 'package:nova_alarm_plugin/nova_alarm_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';

void main() => runApp(EasyLocalization(
      child: MyApp(),
      supportedLocales: [Locale('ar', 'SA')],
      path: 'languages',
      fallbackLocale: Locale('ar', 'SA'),
    ));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        EasyLocalization.of(context).delegate,
      ],
      supportedLocales: EasyLocalization.of(context).supportedLocales,
      locale: EasyLocalization.of(context).locale,
      title: 'صلاة الفجر',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: Color(0xff135775),
        brightness: Brightness.dark,
      ),
      home: FajrPrayer(),
    );
  }
}

class FajrPrayer extends StatefulWidget {
  @override
  _FajrPrayerState createState() => _FajrPrayerState();
}

class _FajrPrayerState extends State<FajrPrayer> {
  TimeOfDay _prayerTime;
  bool _activeAlarm;

  @override
  void initState() {
    super.initState();

    _getSelectedData();
  }

  void _getSelectedData() async {
    final prefs = await SharedPreferences.getInstance();
    final prayerHour = prefs.getInt('prayerHour');
    final prayerMinute = prefs.getInt('prayerMinute');
    if (prayerHour == null || prayerMinute == null) return;
    setState(() {
      _activeAlarm = prefs.getBool('activeAlarm') ?? false;
      _prayerTime = TimeOfDay(
        hour: prayerHour,
        minute: prayerMinute,
      );
    });
  }

  void _pickTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime == null) return;
    setState(() {
      _prayerTime = selectedTime;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('prayerHour', selectedTime.hour);
    prefs.setInt('prayerMinute', selectedTime.minute);
    if (_prayerTime != null) _toggleAlarm(true);
  }

  void _toggleAlarm(bool value) async {
    setState(() {
      _activeAlarm = value;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('activeAlarm', value);
    if (_activeAlarm) {
      final now = DateTime.now();
      final alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        _prayerTime.hour,
        _prayerTime.minute,
      );
      NovaAlarmPlugin.setClock(
        alarmTime.millisecondsSinceEpoch.toString(),
        1,
        title: 'صلاة الفجر',
        content: 'وقت صلاة الفجر',
        androidCallback: _disableAlarm,
        repeats: true,
      );
    } else {
      final succes = await NovaAlarmPlugin.closeClock();
      if (!succes) {
        setState(() {
          _activeAlarm = !_activeAlarm;
        });
      }
    }
  }

  void _disableAlarm() async {
    print('123');
    final succes = await NovaAlarmPlugin.closeClock();
    if (!succes) return;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('activeAlarm', false);
    if (mounted) {
      setState(() {
        _activeAlarm = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.title;
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (cxt, constraints) => Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: <Widget>[
                    Image.asset(
                      'images/muslim-prayer-1571228-1330433.webp',
                      width: constraints.maxWidth * 0.5,
                    ),
                    const SizedBox(height: 20),
                    FlatButton(
                      padding: const EdgeInsets.all(0),
                      onPressed: _pickTime,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'وقت صلاة الفجر',
                            style: titleStyle,
                          ),
                          Text(
                            _prayerTime == null
                                ? '--:--'
                                : '${_prayerTime.hour}:${_prayerTime.minute}',
                            style: titleStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'تشغيل المنبه',
                          style: titleStyle,
                        ),
                        Switch.adaptive(
                          value: _activeAlarm ?? false,
                          onChanged: _toggleAlarm,
                          activeTrackColor: Colors.white,
                          activeColor: Color(0xff4e7094),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
