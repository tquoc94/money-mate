import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qlct/core/utils/firestore_helper.dart';
import 'package:qlct/features/transactions/data/models/transaction_model.dart';

CollectionReference<Map<String, dynamic>> _txnCollection() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw Exception('User not authenticated');
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('transactions');
}

Future<void> addTransaction(TransactionModel txn) async {
  final col = await userCollection('transactions');
  await col.add(txn.toFirestore());
}

Future<void> updateTransaction(TransactionModel txn) async {
  final col = await userCollection('transactions');
  await col.doc(txn.id).update(txn.toFirestore());
}

Future<void> deleteTransaction(String id) async {
  final col = await userCollection('transactions');
  await col.doc(id).delete();
}

Stream<List<TransactionModel>> watchTransactions() {
  return _txnCollection()
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList(),
      );
}

Stream<List<TransactionModel>> watchTransactionsByDateRange(
  DateTime start,
  DateTime end,
) {
  return _txnCollection()
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList(),
      );
}

Future<TransactionModel?> getTransaction(String id) async {
  final col = await userCollection('transactions');
  final doc = await col.doc(id).get();
  if (!doc.exists) return null;
  return TransactionModel.fromFirestore(doc);
}
