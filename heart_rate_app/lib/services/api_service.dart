import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendHealthData(int userID, Map<String, dynamic> heartRateData, Map<String, dynamic> spO2Data, Map<String, dynamic> stressLevelData) async {
  final url = Uri.parse('http://10.0.2.2:3000/api/healthData');  // Update the URL to match your endpoint

  try {
    // Combine all health data into a single map
    Map<String, dynamic> healthData = {
      'userID': userID,
      'heartRateData': heartRateData,
      'spO2Data': spO2Data,
      'stressLevelData': stressLevelData,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(healthData), // Directly send the combined data
    );

    if (response.statusCode == 201) {
      print('Health data inserted successfully for user $userID');
      print('Heart Rate: ${heartRateData['heartRate']} BPM');
      print('SpO2: ${spO2Data['spO2']} %');
      print('Stress Level: ${stressLevelData['stressLevel']}');
    } else {
      print('Failed to insert health data for user $userID. Response code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (error) {
    print('Error sending health data for user $userID: $error');
  }
}
