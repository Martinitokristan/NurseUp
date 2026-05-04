import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../features/subscription/data/models/plan_model.dart';
import '../firebase_options.dart';

/// Seeds Firestore with NurseUp's pricing plans.
///
/// Run this once from a dev Dart entry (or call it manually from the Profile
/// debug screen) to create the `plans` collection with real data the app can consume.
///
/// Usage (from a one-off main):
///   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
///   await FirestoreSeeder.seedAll();
class FirestoreSeeder {
  FirestoreSeeder._();

  static Future<void> seedAll() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await seedPlans();
    if (kDebugMode) {
      // ignore: avoid_print
      print('[FirestoreSeeder] Seeding complete.');
    }
  }

  /// Writes `plans/free` and `plans/pro` documents. Idempotent — re-running
  /// keeps the same ids and overwrites the values.
  static Future<void> seedPlans() async {
    final plans = FirebaseFirestore.instance.collection('plans');
    await plans.doc('free').set(PlanModel.fallbackFree.toFirestore());
    await plans.doc('pro').set(PlanModel.fallbackPro.toFirestore());
  }

}
