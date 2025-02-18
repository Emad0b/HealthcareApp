import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase core
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for database
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase before running the app
  runApp(const HealthCareApp());
}

class HealthCareApp extends StatelessWidget {
  const HealthCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Care App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(background: Colors.black), // Dark background for readability on watches
      ),
      home: const HeartRateMonitor(),
    );
  }
}

class HeartRateMonitor extends StatefulWidget {
  const HeartRateMonitor({super.key});

  @override
  _HeartRateMonitorState createState() => _HeartRateMonitorState();
}

class _HeartRateMonitorState extends State<HeartRateMonitor> {
  static const platform = MethodChannel('com.example.heart_rate_app/heartRate');
  double _heartRate = 0.0;
  double _spO2 = 0.0;
  double _stressLevel = 0.0;
  bool _emergency = false;
  bool _isDialogOpen = false;
  Timer? _timer;
  String _emergencyMessage = ''; // Custom message for cardiac issue
  String userID = 'user123'; // Replace with actual user ID from your app's authentication system

  @override
  void initState() {
    super.initState();
    _startHeartRateUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startHeartRateUpdates() async {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) async {
      try {
        final heartRate = await platform.invokeMethod('getHeartRate');
        final spO2 = await platform.invokeMethod('getSpO2'); // New method for SpO2
        final stressLevel = await platform.invokeMethod('getStressLevel'); // New method for stress level

        setState(() {
          _heartRate = double.parse(heartRate);
          _spO2 = double.parse(spO2);
          _stressLevel = double.parse(stressLevel);
          _checkForEmergency(_heartRate);
        });

        // Prepare heart rate, SpO2, and stress data for Firestore
        Map<String, dynamic> healthData = {
          'heartRate': _heartRate,
          'spO2': _spO2,
          'stressLevel': _stressLevel,
          'status': _emergencyMessage,
          'timestamp': FieldValue.serverTimestamp(), // Firestore server timestamp
        };

        // Send health data to Firestore under user's subcollection
        await addHealthData(userID, healthData);

        // Send health data to API
        await sendHealthData(userID, healthData);

      } on PlatformException catch (e) {
        print("Failed to get health data: '${e.message}'");
      }
    });
  }

  void _checkForEmergency(double heartRate) {
    if (heartRate > 120 && !_isDialogOpen) {
      setState(() {
        _emergency = true;
        _emergencyMessage = _getEmergencyMessage(heartRate);
        _isDialogOpen = true;
      });
      _showEmergencyDialog();
    } else if (heartRate <= 120 && _isDialogOpen) {
      // Reset dialog state if heart rate drops below emergency level
      setState(() {
        _emergency = false;
        _isDialogOpen = false;  
      });
    }
  }

  // Define different cardiac issue messages based on heart rate levels
  String _getEmergencyMessage(double heartRate) {
    if (heartRate > 180) {
      return 'Possible Heart Attack! Seek immediate assistance!';
    } else if (heartRate > 150) {
      return 'Severe Tachycardia Detected! High risk.';
    } else if (heartRate > 120) {
      return 'Moderate Tachycardia. Caution advised.';
    } else {
      return 'Heart rate is elevated.';
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Emergency!', 
            style: TextStyle(fontSize: 14),
          ),
          content: Text(
            _emergencyMessage, // Display the cardiac issue message
            style: const TextStyle(fontSize: 12),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(fontSize: 12)),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isDialogOpen = false; // Reset dialog open state
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Heart Rate Monitor', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Current Heart Rate:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _heartRate.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Current SpO2:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _spO2.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Current Stress Level:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _stressLevel.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_emergency)
              Text(
                'Emergency detected!',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  // Firestore function to add heart rate, SpO2, and stress data under user's HeartRateReadings subcollection
  Future<void> addHealthData(String userID, Map<String, dynamic> healthData) async {
    final firestore = FirebaseFirestore.instance;

    try {
      await firestore
          .collection('Users')
          .doc(userID) // Use userID as document ID in Users collection
          .collection('HealthReadings') // Subcollection for each user's health data
          .add(healthData); // Add the health data document
      print('Health data inserted successfully');
    } catch (error) {
      print('Error sending health data: $error');
    }
  }

  // **Function to Send Data to API**
  Future<void> sendHealthData(String userID, Map<String, dynamic> healthData) async {
    final url = Uri.parse('http://10.0.2.2:3000/api/healthData'); // Localhost for Android emulator

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userID': userID,
          'healthData': healthData,
        }),
      );

      if (response.statusCode == 201) {
        print('Health data inserted successfully');
      } else {
        print('Failed to insert health data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending health data: $error');
    }
  }
}
