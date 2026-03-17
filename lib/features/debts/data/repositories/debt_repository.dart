import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qlct/core/utils/firestore_helper.dart';
import 'package:qlct/features/debts/data/models/debt_model.dart';

CollectionReference<Map<String, dynamic>> _debtCollection() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw Exception('User not authenticated');
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('debts');
}

Future<void> addDebt(DebtModel debt) async {
  final col = await userCollection('debts');
  await col.doc(debt.id).set(debt.toFirestore());
}

Future<void> updateDebt(
  String id, {
  required String personName,
  required double amount,
  String? note,
  DateTime? dueDate,
}) async {
  final col = await userCollection('debts');
  await col.doc(id).update({
    'personName': personName,
    'amount': amount,
    'note': note,
    'dueDate': dueDate?.millisecondsSinceEpoch,
  });
}

Future<void> toggleDebtPaid(DebtModel debt) async {
  final col = await userCollection('debts');
  await col.doc(debt.id).update({'isPaid': !debt.isPaid});
}

Future<void> deleteDebt(String id) async {
  final col = await userCollection('debts');
  await col.doc(id).delete();
}

Stream<List<DebtModel>> watchDebts() {
  return _debtCollection()
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => DebtModel.fromFirestore(d.id, d.data())).toList(),
      );
}
