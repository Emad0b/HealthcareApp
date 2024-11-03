import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

// Add a new user to Firestore (if needed)
Future<void> addUser(String userID, String name, String email, int age, String gender) async {
  await firestore.collection('Users').doc(userID).set({
    'userID': userID,
    'name': name,
    'email': email,
    'age': age,
    'gender': gender,
  });
}

// Add heart rate data to the user's HeartRateReadings subcollection
Future<void> addHeartRateReading(String userID, double heartRate, String status) async {
  await firestore
      .collection('Users')
      .doc(userID) // Use userID as document ID
      .collection('HeartRateReadings') // Create a subcollection
      .add({
        'heartRate': heartRate,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
}
