import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource({FirebaseAuth? auth, FirebaseFirestore? firestore, GoogleSignIn? googleSignIn})
    : _auth = auth,
      _firestore = firestore,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;
  bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  Stream<UserModel?> authStateChanges() {
    if (!isFirebaseReady) return const Stream.empty();
    return auth.authStateChanges().map((user) => user == null ? null : UserModel.fromFirebaseUser(user));
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    _ensureFirebaseReady();
    final credential = await auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    return _persistSignedInUser(credential.user);
  }

  Future<UserModel> signUpWithEmail({required String name, required String email, required String password, String? school}) async {
    _ensureFirebaseReady();
    final credential = await auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = credential.user;
    if (user == null) throw FirebaseAuthException(code: 'missing-user', message: 'No user returned from Firebase Auth.');
    await user.updateDisplayName(name.trim());
    final model = UserModel(uid: user.uid, email: user.email ?? email.trim(), name: name.trim().isEmpty ? 'NurseUp Student' : name.trim());
    await firestore.collection('users').doc(user.uid).set({...model.toMap(), 'school': school, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    return model;
  }

  Future<UserModel> signInWithGoogle() async {
    _ensureFirebaseReady();
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw FirebaseAuthException(code: 'cancelled', message: 'Google sign-in was cancelled.');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    final userCredential = await auth.signInWithCredential(credential);
    return _persistSignedInUser(userCredential.user);
  }

  Future<void> signOut() async {
    _ensureFirebaseReady();
    await _googleSignIn.signOut();
    await _googleSignIn.disconnect().catchError((_) => null);
    await auth.signOut();
  }

  Future<UserModel> _persistSignedInUser(User? user) async {
    if (user == null) throw FirebaseAuthException(code: 'missing-user', message: 'No user returned from Firebase Auth.');
    final model = UserModel.fromFirebaseUser(user);
    await firestore.collection('users').doc(user.uid).set({...model.toMap(), 'photoUrl': user.photoURL, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    await _initializeUsageDocIfMissing(user.uid);
    return model;
  }

  Future<void> _initializeUsageDocIfMissing(String uid) async {
    final usageDoc = firestore.collection('users').doc(uid).collection('usage').doc('current');
    final usageSnap = await usageDoc.get();
    if (!usageSnap.exists) {
      await usageDoc.set({
        'words_used_this_week': 0,
        'week_reset_date': Timestamp.fromDate(_nextMonday()),
        'tier': 'free',
        'files_uploaded': 0,
        'reviewers_generated': 0,
        'streak': 0,
        'last_active_date': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  DateTime _nextMonday() {
    final now = DateTime.now();
    var daysUntilMonday = DateTime.monday - now.weekday;
    if (daysUntilMonday <= 0) daysUntilMonday += 7;
    return DateTime(now.year, now.month, now.day).add(Duration(days: daysUntilMonday));
  }

  void _ensureFirebaseReady() {
    if (!isFirebaseReady) {
      throw FirebaseAuthException(code: 'firebase-not-configured', message: 'Firebase is not configured yet. Run flutterfire configure and add firebase_options.dart.');
    }
  }
}
