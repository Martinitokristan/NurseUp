import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../providers/reviewer_provider.dart';

void openOrGenerateReviewer({
  required BuildContext context,
  required WidgetRef ref,
  required String fileId,
}) {
  final reviewerId = ref.read(reviewerIdForFileProvider(fileId));

  if (reviewerId != null && reviewerId.isNotEmpty) {
    context.push('${AppRoutes.reviewerDetail}?id=$reviewerId&from=file');
    return;
  }

  context.push('${AppRoutes.reviewerGenerating}?fileId=$fileId');
}
