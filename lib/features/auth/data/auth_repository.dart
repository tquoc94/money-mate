import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qlct/features/transactions/data/repositories/category_repository.dart';

Future<UserCredential?> signInWithGoogle() async {
  final googleUser = await GoogleSignIn().signIn();
  if (googleUser == null) return null;

  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final userCredential = await FirebaseAuth.instance.signInWithCredential(
    credential,
  );

  await _saveUserProfile(userCredential.user);

  return userCredential;
}

Future<void> signOutFromGoogle() async {
  await GoogleSignIn().signOut();
  await FirebaseAuth.instance.signOut();
}

Stream<User?> authStateChanges() {
  return FirebaseAuth.instance.authStateChanges();
}

User? getCurrentUser() {
  return FirebaseAuth.instance.currentUser;
}

Future<void> _saveUserProfile(User? user) async {
  if (user == null) return;

  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final docSnapshot = await userDoc.get();

  final userData = {
    'displayName': user.displayName ?? '',
    'email': user.email ?? '',
    'photoUrl': user.photoURL ?? '',
    'settings': {'currency': 'VND', 'theme': 'system', 'locale': 'vi'},
  };

  if (!docSnapshot.exists) {
    userData['createdAt'] = FieldValue.serverTimestamp();
    await userDoc.set(userData);
    await initDefaultCategories();
  } else {
    await userDoc.update({
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
    });
  }
}
