import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qlct/core/utils/firestore_helper.dart';
import 'package:qlct/features/budget/data/models/budget_model.dart';

CollectionReference<Map<String, dynamic>> _budgetCollection() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw Exception('User not authenticated');
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('budgets');
}

Future<void> setBudget(BudgetModel budget) async {
  final col = await userCollection('budgets');
  await col.doc(budget.docId).set(budget.toFirestore());
}

Future<void> deleteBudget(String docId) async {
  final col = await userCollection('budgets');
  await col.doc(docId).delete();
}

Future<void> updateBudgetLimit(String docId, double newLimit) async {
  final col = await userCollection('budgets');
  await col.doc(docId).update({'limit': newLimit});
}

Future<void> toggleBudgetPin(BudgetModel budget) async {
  final col = await userCollection('budgets');
  await col.doc(budget.docId).update({'isPinned': !budget.isPinned});
}

Stream<List<BudgetModel>> watchBudgets(int month, int year) {
  return _budgetCollection()
      .where('month', isEqualTo: month)
      .where('year', isEqualTo: year)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromFirestore(doc.data()))
            .toList(),
      );
}
