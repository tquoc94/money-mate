import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qlct/core/utils/firestore_helper.dart';
import 'package:qlct/features/reminders/data/models/reminder_model.dart';

CollectionReference<Map<String, dynamic>> _reminderCollection() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw Exception('User not authenticated');
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('reminders');
}

Future<void> addReminder(ReminderModel reminder) async {
  final col = await userCollection('reminders');
  await col.doc(reminder.id).set(reminder.toFirestore());
}

Future<void> updateReminder(
  String id, {
  required String title,
  required double amount,
  required int dueDay,
}) async {
  final col = await userCollection('reminders');
  await col.doc(id).update({
    'title': title,
    'amount': amount,
    'dueDay': dueDay,
  });
}

Future<void> toggleReminder(ReminderModel reminder) async {
  final col = await userCollection('reminders');
  await col.doc(reminder.id).update({'isActive': !reminder.isActive});
}

Future<void> deleteReminder(String id) async {
  final col = await userCollection('reminders');
  await col.doc(id).delete();
}

Stream<List<ReminderModel>> watchReminders() {
  return _reminderCollection()
      .orderBy('dueDay')
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => ReminderModel.fromFirestore(d.id, d.data()))
            .toList(),
      );
}
