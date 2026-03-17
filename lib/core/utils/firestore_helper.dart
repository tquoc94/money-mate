import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<String> _getCurrentUid() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) return uid;
  final user = await FirebaseAuth.instance.authStateChanges().firstWhere(
    (u) => u != null,
  );
  return user!.uid;
}

Future<CollectionReference<Map<String, dynamic>>> userCollection(
  String collectionName,
) async {
  final uid = await _getCurrentUid();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection(collectionName);
}
