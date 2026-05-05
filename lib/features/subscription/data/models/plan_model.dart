import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A Pricing/feature plan driven entirely from Firestore (`plans/{planId}`).
///
/// Fields:
///   - id:                       document id (e.g. `free`, `pro`)
///   - name:                     human-readable label shown in UI
///   - priceCents:               monthly price in minor units (PHP centavos)
///   - currency:                 ISO currency code, e.g. `PHP`
///   - weeklyWordLimit:          max words per rolling 7-day window
///   - monthlyUploadLimit:       max files per 30-day window (-1 = unlimited)
///   - monthlyReviewerLimit:     max reviewers per 30-day window (-1 = unlimited)
///   - features:                 list of unlocked feature keys
///   - isActive:                 hide the plan from UI without deleting it
class PlanModel extends Equatable {
  const PlanModel({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.currency,
    required this.weeklyWordLimit,
    required this.monthlyUploadLimit,
    required this.monthlyReviewerLimit,
    required this.features,
    required this.isActive,
  });

  final String id;
  final String name;
  final int priceCents;
  final String currency;
  final int weeklyWordLimit;
  final int monthlyUploadLimit;
  final int monthlyReviewerLimit;
  final List<String> features;
  final bool isActive;

  bool get isFree => priceCents == 0;
  bool get isPro => id == 'pro';

  String get formattedPrice {
    if (priceCents == 0) return 'Free';
    final whole = priceCents / 100;
    final symbol = currency == 'PHP' ? 'PHP ' : '$currency ';
    return '$symbol${whole.toStringAsFixed(0)}';
  }

  factory PlanModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PlanModel(
      id: id,
      name: data['name'] as String? ?? id,
      priceCents: (data['price_cents'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'PHP',
      weeklyWordLimit: (data['weekly_word_limit'] as num?)?.toInt() ??
          (id == 'pro' ? 5000 : 1000),
      monthlyUploadLimit: (data['monthly_upload_limit'] as num?)?.toInt() ?? -1,
      monthlyReviewerLimit:
          (data['monthly_reviewer_limit'] as num?)?.toInt() ?? -1,
      features: ((data['features'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      isActive: data['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'price_cents': priceCents,
        'currency': currency,
        'weekly_word_limit': weeklyWordLimit,
        'monthly_upload_limit': monthlyUploadLimit,
        'monthly_reviewer_limit': monthlyReviewerLimit,
        'features': features,
        'is_active': isActive,
        'updated_at': FieldValue.serverTimestamp(),
      };

  /// Built-in fallback if Firestore has no `plans/free` doc yet. Keeps the app
  /// usable in demo mode but real data from Firestore always wins.
  static const PlanModel fallbackFree = PlanModel(
    id: 'free',
    name: 'Free Plan',
    priceCents: 0,
    currency: 'PHP',
    weeklyWordLimit: 1000,
    monthlyUploadLimit: 3,
    monthlyReviewerLimit: 3,
    features: ['basic_reviewer'],
    isActive: true,
  );

  static const PlanModel fallbackPro = PlanModel(
    id: 'pro',
    name: 'Pro Plan',
    priceCents: 30000,
    currency: 'PHP',
    weeklyWordLimit: 5000,
    monthlyUploadLimit: -1,
    monthlyReviewerLimit: -1,
    features: [
      'basic_reviewer',
      'unlimited_uploads',
      'unlimited_reviewers',
      'anatomy_3d',
      'priority_ai',
    ],
    isActive: true,
  );

  @override
  List<Object?> get props => [
        id,
        name,
        priceCents,
        currency,
        weeklyWordLimit,
        monthlyUploadLimit,
        monthlyReviewerLimit,
        features,
        isActive,
      ];
}
