import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qlct/features/transactions/data/models/category_model.dart';

CollectionReference<Map<String, dynamic>> _catCollection() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw Exception('User not authenticated');
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('categories');
}

Future<void> initDefaultCategories() async {
  final snapshot = await _catCollection().limit(1).get();
  if (snapshot.docs.isNotEmpty) return;

  final batch = FirebaseFirestore.instance.batch();
  for (final cat in CategoryModel.defaultCategories) {
    batch.set(_catCollection().doc(cat.id), cat.toFirestore());
  }
  await batch.commit();
}

Stream<List<CategoryModel>> watchCategories() {
  return _catCollection().snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
        .toList(),
  );
}

Stream<List<CategoryModel>> watchCategoriesByType(String type) {
  return _catCollection()
      .where('type', isEqualTo: type)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
            .toList(),
      );
}

Future<void> addCategory(CategoryModel category) async {
  await _catCollection().doc(category.id).set(category.toFirestore());
}

Future<void> deleteCategory(String id) async {
  await _catCollection().doc(id).delete();
}
