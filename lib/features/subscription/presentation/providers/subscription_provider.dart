import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/plan_model.dart';
import '../../data/models/subscription_model.dart';

/// Local demo override so the paywall CTA can unlock features in environments
/// that have no Firebase connection. Real users always get real Firestore data.
final demoSubscriptionOverrideProvider = StateProvider<bool>((ref) => false);

/// Streams the full subscription document at `subscriptions/{uid}`.
///
/// Returns a `SubscriptionModel.free()` when:
///   - Firebase isn't initialized,
///   - the user isn't signed in, or
///   - the doc doesn't exist yet.
final subscriptionDocProvider = StreamProvider<SubscriptionModel>((ref) {
  if (Firebase.apps.isEmpty) return Stream.value(SubscriptionModel.free());
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(SubscriptionModel.free());
  return FirebaseFirestore.instance
      .collection('subscriptions')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    final data = doc.data();
    if (data == null) return SubscriptionModel.free();
    return SubscriptionModel.fromFirestore(data);
  });
});

/// Streams the full `plans` catalog from Firestore, keyed by plan id.
final plansProvider = StreamProvider<Map<String, PlanModel>>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value({
      'free': PlanModel.fallbackFree,
      'pro': PlanModel.fallbackPro,
    });
  }
  return FirebaseFirestore.instance.collection('plans').snapshots().map((snap) {
    if (snap.docs.isEmpty) {
      return {
        'free': PlanModel.fallbackFree,
        'pro': PlanModel.fallbackPro,
      };
    }
    return {
      for (final doc in snap.docs)
        doc.id: PlanModel.fromFirestore(doc.id, doc.data())
    };
  });
});

/// Resolves the plan that matches the active subscription tier. Used for
/// dynamic usage limits and feature gating.
final activePlanProvider = Provider<PlanModel>((ref) {
  final plans = ref.watch(plansProvider).valueOrNull ?? const {};
  final sub = ref.watch(subscriptionDocProvider).valueOrNull ??
      SubscriptionModel.free();
  final localOverride = ref.watch(demoSubscriptionOverrideProvider);
  if (localOverride) {
    return plans['pro'] ?? PlanModel.fallbackPro;
  }
  if (sub.effectivelyActive) {
    return plans[sub.tier] ??
        (sub.tier == 'pro' ? PlanModel.fallbackPro : PlanModel.fallbackFree);
  }
  return plans['free'] ?? PlanModel.fallbackFree;
});

/// Boolean gate used by existing UI code (`PaywallGate`, etc.).
final subscriptionProvider = Provider<bool>((ref) {
  final localOverride = ref.watch(demoSubscriptionOverrideProvider);
  final sub = ref.watch(subscriptionDocProvider).valueOrNull;
  return localOverride || (sub?.effectivelyActive ?? false);
});

/// Controller for activating paid subscriptions.
final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, SubscriptionActionState>(
        (ref) => SubscriptionController());

class SubscriptionActionState {
  const SubscriptionActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  SubscriptionActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) =>
      SubscriptionActionState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        successMessage: successMessage,
      );
}

class SubscriptionController extends StateNotifier<SubscriptionActionState> {
  SubscriptionController() : super(const SubscriptionActionState());

  /// Marks the user's subscription as active Pro (called on successful
  /// payment). For the demo/GCash flow we extend by 30 days.
  Future<bool> activatePaidPro({int durationDays = 30}) async {
    if (Firebase.apps.isEmpty) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final now = DateTime.now();
    final sub = SubscriptionModel(
      tier: 'pro',
      isActive: true,
      startedAt: now,
      expiresAt: now.add(Duration(days: durationDays)),
      source: 'paid',
    );
    try {
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(user.uid)
          .set(sub.toFirestore(), SetOptions(merge: true));
      state = const SubscriptionActionState(
          successMessage: 'Pro activated. Enjoy!');
      return true;
    } catch (_) {
      state = const SubscriptionActionState(
          errorMessage: 'Could not activate subscription.');
      return false;
    }
  }

  void clearMessages() => state = const SubscriptionActionState();
}

