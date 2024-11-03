import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendHeartRateData(int userID, Map<String, dynamic> heartRateData) async {
  final url = Uri.parse('http://10.0.2.2:3000/api/heartRate'); // Replace with your server address

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userID': userID,
        'heartRateData': json.encode(heartRateData), // JSON stringified
      }),
    );

    if (response.statusCode == 201) {
      print('Heart rate data inserted successfully');
    } else {
      print('Failed to insert heart rate data: ${response.statusCode}');
    }
  } catch (error) {
    print('Error sending heart rate data: $error');
  }
}
