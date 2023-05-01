import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sensors/sensors.dart';
// import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
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
      home: const IpAddressPage(),
    );
  }
}
class IpAddressPage extends StatefulWidget {
  const IpAddressPage({Key? key}) : super(key: key);

  @override
  _IpAddressPageState createState() => _IpAddressPageState();
}

class _IpAddressPageState extends State<IpAddressPage> {
  TextEditingController _ipAddressController = TextEditingController();

  void _submitIpAddress() {
    final ipAddress = _ipAddressController.text.trim();
    if (ipAddress.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TemperaturePage(ipAddress: ipAddress),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Server IP Address'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _ipAddressController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Enter the IP Address',
              ),
            ),
            ElevatedButton(
              onPressed: _submitIpAddress,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}


class TemperaturePage extends StatefulWidget {
  final String ipAddress;
  TemperaturePage({Key? key,required this.ipAddress}) : super(key: key);
  bool _isEnabled = false;
  @override
  _TemperaturePageState createState() => _TemperaturePageState();
}

class _TemperaturePageState extends State<TemperaturePage> {
  late final http.Client _client;
  late String _temperature;
  late TextEditingController _temperatureController;
  late TextEditingController _notifyperiod;

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
    _notifyperiod = TextEditingController();
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
          'http://${widget.ipAddress}:8000/api/settings/'));
      final json = jsonDecode(response.body);
      final temperature = json['temp'];
      print('Temperature: $temperature');
      setState(() {
        // _temperature = temperature.toString();
        double beta = double.parse(temperature);
        _temp = beta;
        if (beta > 25){
          Vibration.vibrate(duration: 1000);
        }
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
        Uri.parse('http://${widget.ipAddress}:8000/api/settings/'),
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
      final notifyperiod = _notifyperiod.text.trim();
      if (temperature.isEmpty) {
        return;
      }
      if (notifyperiod.isEmpty){
        return;
      }
      double beta = double.parse(temperature);
      double charlie = double.parse(notifyperiod);
      final response = await _client.post(

        Uri.parse('http://${widget.ipAddress}:8000/api/settings/'),
        body: jsonEncode(<String, dynamic>{
          'temp': beta,
          'notify_period':charlie
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
      TextField(
        controller: _notifyperiod,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Enter the notification Period',
        ),
      ),
    ElevatedButton(
    onPressed: _sendTemperature,
    child: const Text('Send Data'),
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