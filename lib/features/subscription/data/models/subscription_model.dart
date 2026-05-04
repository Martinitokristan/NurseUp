import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Full subscription record stored at `subscriptions/{uid}`.
///
/// This is the authoritative source of truth for whether a user has Pro
/// entitlements active and why.
class SubscriptionModel extends Equatable {
  const SubscriptionModel({
    required this.tier,
    required this.isActive,
    this.startedAt,
    this.expiresAt,
    this.source = 'free',
  });

  /// Plan id (must match a `plans/{planId}` document).
  final String tier;

  /// True when a paid entitlement is currently active.
  final bool isActive;
  final DateTime? startedAt;
  final DateTime? expiresAt;

  /// One of: `free`, `paid`, `demo`.
  final String source;

  bool get isPro => isActive && tier == 'pro';

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Compute effective status (expiry-aware) to avoid showing Pro after the
  /// Firestore doc becomes stale.
  bool get effectivelyActive => isActive && !isExpired;

  factory SubscriptionModel.free() => const SubscriptionModel(
        tier: 'free',
        isActive: false,
        source: 'free',
      );

  factory SubscriptionModel.fromFirestore(Map<String, dynamic> data) {
    final started = data['started_at'];
    final expires = data['expires_at'];
    return SubscriptionModel(
      tier: data['tier'] as String? ?? 'free',
      isActive: data['is_active'] as bool? ?? data['isActive'] as bool? ?? false,
      startedAt: started is Timestamp ? started.toDate() : null,
      expiresAt: expires is Timestamp ? expires.toDate() : null,
      source: data['source'] as String? ?? 'free',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'tier': tier,
        'is_active': isActive,
        'isActive': isActive, // legacy field kept for backward compatibility
        'started_at':
            startedAt != null ? Timestamp.fromDate(startedAt!) : null,
        'expires_at':
            expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'source': source,
        'updated_at': FieldValue.serverTimestamp(),
      };

  SubscriptionModel copyWith({
    String? tier,
    bool? isActive,
    DateTime? startedAt,
    DateTime? expiresAt,
    String? source,
  }) =>
      SubscriptionModel(
        tier: tier ?? this.tier,
        isActive: isActive ?? this.isActive,
        startedAt: startedAt ?? this.startedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        source: source ?? this.source,
      );

  @override
  List<Object?> get props =>
      [tier, isActive, startedAt, expiresAt, source];
}
