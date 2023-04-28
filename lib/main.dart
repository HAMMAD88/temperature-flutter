import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sensors/sensors.dart';
// import 'package:sensors_plus/sensors_plus.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temperature App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TemperaturePage(),
    );
  }
}

class TemperaturePage extends StatefulWidget {
   TemperaturePage({Key? key}) : super(key: key);
  bool _isEnabled = false;
  @override
  _TemperaturePageState createState() => _TemperaturePageState();
}

class _TemperaturePageState extends State<TemperaturePage> {
  late final http.Client _client;
  late String _temperature;
  late TextEditingController _temperatureController;
  double _angle = 0;
  late StreamSubscription<AccelerometerEvent> _subscription;
  late double _temp;
  bool check = false;



  @override
  void initState() {
    super.initState();
    _client = http.Client();
    _temperature = '-';
    _temp = 0;
    _temperatureController = TextEditingController();
    _startFetchingTemperature();
    // _listenToRotation();

  }

  @override
  void dispose() {
    _client.close();
    _temperatureController.dispose();

    super.dispose();
  }

  Future<void> _fetchTemperature() async {
    try {
      final response = await _client.get(Uri.parse(
          'http://192.168.143.137:8000/api/settemp/'));
      final json = jsonDecode(response.body);
      final temperature = json['temp'];
      print('Temperature: $temperature');
      setState(() {
        // _temperature = temperature.toString();
        double beta = double.parse(temperature);
        _temp = beta;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _startFetchingTemperature() {
    Future.delayed(const Duration(milliseconds: 50)).then((_) {
      //stopListeningToAccelerometer();
      _fetchTemperature();
      // (put in the if below).
      if (widget._isEnabled){
        _listenToRotation();
         Future.delayed(const Duration(milliseconds: 200));
         _sendAngle(_angle);
         //stopListeningToAccelerometer();
      }
      // else{
      //   stopListeningToAccelerometer();
      // }
      _startFetchingTemperature();

    });

  }
  void _enableGyroscope(){

  }

  void _toggleFunctionEnabled() {
    setState(() {
      widget._isEnabled = !widget._isEnabled;
      check = !check;

    });
    //stopListeningToAccelerometer();
  }

  void _listenToRotation() {
    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _angle = event.x;
        print(_angle);
      });
    }
    );
   // _sendAngle(_angle);
  }
  void stopListeningToAccelerometer() {
    if (_subscription != null) {
      _subscription.cancel();
    }

  }
  Future<void> _sendAngle(double angle) async {
    try {
      if (angle == Null) {
        return;
      }
       double t = -(angle * 0.5);
       double alpha = (t +_temp);
      String a = (alpha).toStringAsFixed(2);
      final response = await _client.post(
        Uri.parse('http://192.168.143.137:8000/api/settemp/'),
        body: jsonEncode(<String, dynamic>{
          'temp': a,
          'notify_period':1
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // Temperature sent successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Temperature sent successfully'),
          ),
        );
      } else {
        // Error sending temperature
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sending temperature'),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
  Future<void> _sendTemperature() async {
    try {
      final temperature = _temperatureController.text.trim();
      if (temperature.isEmpty) {
        return;
      }
      double beta = double.parse(temperature);
      final response = await _client.post(

        Uri.parse('http://192.168.143.137:8000/api/settemp/'),
        body: jsonEncode(<String, dynamic>{
          'temp': beta,
          'notify_period':1
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // Temperature sent successfully
        _temperatureController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Temperature sent successfully'),
          ),
        );
      } else {
        // Error sending temperature
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sending temperature'),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text('Temperature App'),
    centerTitle: true,
    ),
    body: Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
    Text(
    'Current Temperature: $_temp Celcius',
    style: const TextStyle(fontSize: 24),
    ),
    const SizedBox(height: 16),
    TextField(
    controller: _temperatureController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
    labelText: 'Enter your temperature',
    ),
    ),
    ElevatedButton(
    onPressed: _sendTemperature,
    child: const Text('Send Temperature'),
    ),
      ElevatedButton(
        onPressed: _toggleFunctionEnabled,
        child: Text(widget._isEnabled ? 'Disable Accelerometer' : 'Enable Accelerometer'),
      ),
    ],
    ),
    ));

    }

}