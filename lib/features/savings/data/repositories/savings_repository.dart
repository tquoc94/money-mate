import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qlct/core/utils/firestore_helper.dart';
import 'package:qlct/features/savings/data/models/savings_goal_model.dart';

CollectionReference<Map<String, dynamic>> _savingsCollection() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw Exception('User not authenticated');
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('savings_goals');
}

Future<void> addSavingsGoal(SavingsGoalModel goal) async {
  final col = await userCollection('savings_goals');
  await col.doc(goal.id).set(goal.toFirestore());
}

Future<void> updateSavingsGoal(
  String id,
  String name,
  double targetAmount,
) async {
  final col = await userCollection('savings_goals');
  await col.doc(id).update({'name': name, 'targetAmount': targetAmount});
}

Future<void> addToSavings(String id, double amount) async {
  final col = await userCollection('savings_goals');
  await col.doc(id).update({'currentAmount': FieldValue.increment(amount)});
}

Future<void> deleteSavingsGoal(String id) async {
  final col = await userCollection('savings_goals');
  await col.doc(id).delete();
}

Stream<List<SavingsGoalModel>> watchSavingsGoals() {
  return _savingsCollection()
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => SavingsGoalModel.fromFirestore(d.id, d.data()))
            .toList(),
      );
}
