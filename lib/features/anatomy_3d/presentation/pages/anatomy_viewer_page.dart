import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/anatomy_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

class AnatomyViewerPage extends ConsumerStatefulWidget {
  const AnatomyViewerPage({super.key});

  @override
  ConsumerState<AnatomyViewerPage> createState() => _AnatomyViewerPageState();
}

class _AnatomyViewerPageState extends ConsumerState<AnatomyViewerPage> {
  bool labels = true;
  bool autoRotate = true;
  String? selectedHotspotId;
  bool _checkedTopic = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTopicDetection(context));
  }

  void _checkTopicDetection(BuildContext context) {
    if (_checkedTopic) return;
    _checkedTopic = true;
    final modelId = GoRouterState.of(context).uri.queryParameters['modelId'];
    if (modelId == null || modelId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.anatomy);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = GoRouterState.of(context).uri.queryParameters;
    final modelId = query['modelId'];
    
    final isPro = ref.watch(subscriptionProvider);
    if (!isPro) {
      return Scaffold(
        appBar: AppBar(title: const Text('3D Anatomy')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 64, color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                const Text('3D Anatomy is a Pro feature.', style: AppTextStyles.h3, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(onPressed: () => context.push(AppRoutes.paywall), child: const Text('Upgrade to Pro')),
              ],
            ),
          ),
        ),
      );
    }

    if (modelId == null || modelId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final model = anatomyModelById(modelId);
    if (model == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('3D Anatomy')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This 3D model is not available.', style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: () => context.go(AppRoutes.anatomy), child: const Text('Back to Catalog')),
            ],
          ),
        ),
      );
    }

    final availableModels = ref.watch(anatomyModelsProvider);
    final hasAccessToModel = availableModels.any((item) => item.id == modelId);
    if (!hasAccessToModel) {
      return Scaffold(
        appBar: AppBar(title: const Text('3D Anatomy')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, color: AppColors.primary, size: 56),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'This model is not unlocked yet.',
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Upload and generate a reviewer for this anatomy topic to unlock the matching 3D model.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.upload),
                  child: const Text('Upload Notes'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hotspots = ref.watch(anatomyHotspotsProvider)[modelId] ?? [];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEAF7FF)])),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(top: 8, left: 8, child: IconButton.filledTonal(onPressed: () { if (context.canPop()) { context.pop(); } else { context.go(AppRoutes.anatomy); } }, icon: const Icon(Icons.arrow_back_rounded))),
              Positioned(top: 22, left: 72, child: Text('${model.name} Model', style: AppTextStyles.h2)),
              Positioned.fill(top: 76, bottom: 118, child: _ModelSurface(assetPath: model.assetPath, autoRotate: autoRotate, hotspots: hotspots, showLabels: labels, onHotspotTap: (hotspot) => _showHotspotInfo(context, hotspot), fallbackIcon: anatomyIcon(model))),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 12))]),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_control(Icons.rotate_right_rounded, autoRotate ? 'Rotating' : 'Rotate', () => setState(() => autoRotate = !autoRotate)), _control(Icons.label_rounded, labels ? 'Hide Labels' : 'Show Labels', () => setState(() => labels = !labels)), _control(Icons.grid_view_rounded, 'Catalog', () => context.go(AppRoutes.anatomy))]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _control(IconData icon, String label, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppSpacing.radiusFull), child: Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Column(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(radius: 28, backgroundColor: AppColors.primary, child: Icon(icon, color: Colors.white)), const SizedBox(height: 6), Text(label, style: AppTextStyles.caption)])));
  }

  void _showHotspotInfo(BuildContext context, AnatomyHotspot hotspot) {
    showModalBottomSheet(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9, expand: false, builder: (_, controller) => Container(padding: const EdgeInsets.all(AppSpacing.xl), child: ListView(controller: controller, children: [Text(hotspot.name, style: AppTextStyles.h2.copyWith(color: AppColors.primary)), const SizedBox(height: AppSpacing.md), _InfoRow(label: 'Function', value: hotspot.description), const SizedBox(height: AppSpacing.md), _InfoRow(label: 'Nursing Significance', value: hotspot.nursingSignificance), const SizedBox(height: AppSpacing.md), _InfoRow(label: 'Exam Tip', value: hotspot.pnleTip)]))));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)), const SizedBox(height: 4), Text(value, style: AppTextStyles.bodyMedium)]);
  }
}

class _ModelSurface extends StatefulWidget {
  const _ModelSurface({required this.assetPath, required this.autoRotate, required this.hotspots, required this.showLabels, required this.onHotspotTap, required this.fallbackIcon});

  final String assetPath;
  final bool autoRotate;
  final List<AnatomyHotspot> hotspots;
  final bool showLabels;
  final void Function(AnatomyHotspot) onHotspotTap;
  final IconData fallbackIcon;

  @override
  State<_ModelSurface> createState() => _ModelSurfaceState();
}

class _ModelSurfaceState extends State<_ModelSurface> {
  final Map<String, Offset> _hotspotScreenPositions = {};
  final Set<String> _visibleHotspots = {};

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolveSource(widget.assetPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final src = snapshot.data;
        if (src == null) {
          return Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFD6EEFF)]), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, 20))]),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(widget.fallbackIcon, color: AppColors.primary, size: 112), const SizedBox(height: 12), Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('3D model unavailable.\nBundle the GLB file to view it.', style: AppTextStyles.caption, textAlign: TextAlign.center))]),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              children: [
                ModelViewer(
                  key: ValueKey(widget.assetPath),
                  src: src,
                  ar: true,
                  autoRotate: widget.autoRotate,
                  cameraControls: true,
                  backgroundColor: Colors.transparent,
                  disableZoom: false,
                  innerModelViewerHtml: widget.hotspots.isNotEmpty ? _buildHotspotHtml(widget.hotspots) : null,
                  relatedCss: widget.hotspots.isNotEmpty ? _kAnchorCss : null,
                  relatedJs: widget.hotspots.isNotEmpty ? _kHotspotProjectionJs : null,
                  minHotspotOpacity: 0,
                  maxHotspotOpacity: 0,
                  javascriptChannels: widget.hotspots.isNotEmpty
                      ? {
                          JavascriptChannel(
                            'AnatomyProjectionChannel',
                            onMessageReceived: (msg) {
                              final decoded = jsonDecode(msg.message) as List<dynamic>;
                              if (!mounted) return;
                              setState(() {
                                _hotspotScreenPositions.clear();
                                _visibleHotspots.clear();
                                for (final item in decoded) {
                                  final map = item as Map<String, dynamic>;
                                  final id = map['id']?.toString();
                                  final x = (map['x'] as num?)?.toDouble();
                                  final y = (map['y'] as num?)?.toDouble();
                                  final visible = map['visible'] == true;
                                  if (id == null || x == null || y == null) continue;
                                  if (visible) {
                                    _visibleHotspots.add(id);
                                    _hotspotScreenPositions[id] = Offset(x, y);
                                  }
                                }
                              });
                            },
                          ),
                        }
                      : null,
                ),
                if (widget.showLabels)
                  Positioned.fill(
                    child: _HotspotOverlay(
                      hotspots: widget.hotspots,
                      targetPositions: _hotspotScreenPositions,
                      visibleHotspots: _visibleHotspots,
                      size: size,
                      onTap: widget.onHotspotTap,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<String?> _resolveSource(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return assetPath;
    } catch (error) {
      debugPrint('[NurseUp] Missing bundled GLB asset: $assetPath — $error');
      return null;
    }
  }
}

String _buildHotspotHtml(List<AnatomyHotspot> hotspots) {
  final buf = StringBuffer();
  for (final h in hotspots) {
    final safeId = _htmlEscape(h.id);
    final position = _toModelViewerVector(h.position);
    final normal = _toModelViewerVector(h.normal);
    buf.write(
      '<button class="anatomy-anchor" '
      'id="anchor-$safeId" '
      'slot="hotspot-$safeId" '
      'data-id="$safeId" '
      'data-position="$position" '
      'data-normal="$normal"></button>',
    );
  }
  return buf.toString();
}

String _toModelViewerVector(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return value;
  return parts.map((part) {
    final cleaned = part.trim();
    if (cleaned.endsWith('m') || cleaned.endsWith('cm') || cleaned.endsWith('mm')) {
      return cleaned;
    }
    return '${cleaned}m';
  }).join(' ');
}

String _htmlEscape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

class _HotspotOverlay extends StatelessWidget {
  const _HotspotOverlay({
    required this.hotspots,
    required this.targetPositions,
    required this.visibleHotspots,
    required this.size,
    required this.onTap,
  });

  final List<AnatomyHotspot> hotspots;
  final Map<String, Offset> targetPositions;
  final Set<String> visibleHotspots;
  final Size size;
  final void Function(AnatomyHotspot) onTap;

  @override
  Widget build(BuildContext context) {
    final visible = hotspots
        .where((h) => visibleHotspots.contains(h.id) && targetPositions.containsKey(h.id))
        .toList();
    final labelPositions = {
      for (final hotspot in visible)
        hotspot.id: _labelPositionFor(hotspot, targetPositions[hotspot.id]!, size),
    };

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _HotspotLinePainter(
              hotspots: visible,
              targetPositions: targetPositions,
              labelPositions: labelPositions,
            ),
          ),
        ),
        for (final hotspot in visible)
          _HotspotLabelButton(
            hotspot: hotspot,
            labelPosition: labelPositions[hotspot.id]!,
            onTap: () => onTap(hotspot),
          ),
      ],
    );
  }
}

Offset _labelPositionFor(AnatomyHotspot hotspot, Offset target, Size size) {
  Offset offset;
  switch (hotspot.id) {
    case 'frontal_lobe':
      offset = const Offset(82, -46);
      break;
    case 'parietal_lobe':
      offset = const Offset(68, -74);
      break;
    case 'temporal_lobe':
      offset = const Offset(-180, -26);
      break;
    case 'occipital_lobe':
      offset = const Offset(-184, -44);
      break;
    case 'cerebellum':
      offset = const Offset(72, 34);
      break;
    case 'brain_stem':
      offset = const Offset(56, 70);
      break;
    default:
      offset = target.dx < size.width / 2 ? const Offset(72, -28) : const Offset(-176, -28);
  }

  final raw = target + offset;
  return Offset(
    raw.dx.clamp(8.0, size.width - 150.0),
    raw.dy.clamp(8.0, size.height - 48.0),
  );
}

class _HotspotLinePainter extends CustomPainter {
  const _HotspotLinePainter({
    required this.hotspots,
    required this.targetPositions,
    required this.labelPositions,
  });

  final List<AnatomyHotspot> hotspots;
  final Map<String, Offset> targetPositions;
  final Map<String, Offset> labelPositions;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF0F1B2D).withValues(alpha: .78)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final dotFill = Paint()..color = AppColors.primary;
    final dotStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final hotspot in hotspots) {
      final target = targetPositions[hotspot.id];
      final label = labelPositions[hotspot.id];
      if (target == null || label == null) continue;
      final labelAnchor = label.dx > target.dx
          ? Offset(label.dx, label.dy + 19)
          : Offset(label.dx + 142, label.dy + 19);
      canvas.drawLine(target, labelAnchor, linePaint);
      canvas.drawCircle(target, 8, dotStroke);
      canvas.drawCircle(target, 5.5, dotFill);
    }
  }

  @override
  bool shouldRepaint(covariant _HotspotLinePainter oldDelegate) => true;
}

class _HotspotLabelButton extends StatelessWidget {
  const _HotspotLabelButton({
    required this.hotspot,
    required this.labelPosition,
    required this.onTap,
  });

  final AnatomyHotspot hotspot;
  final Offset labelPosition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: labelPosition.dx,
      top: labelPosition.dy,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 142,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .14),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            hotspot.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF0F1B2D),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

const String _kHotspotProjectionJs = '''
(() => {
  const mv = document.querySelector('model-viewer');
  if (!mv || window.__nurseupProjectionInstalled) return;
  window.__nurseupProjectionInstalled = true;

  function postPositions() {
    const mvRect = mv.getBoundingClientRect();
    const anchors = Array.from(mv.querySelectorAll('.anatomy-anchor'));
    const payload = anchors.map((anchor) => {
      const rect = anchor.getBoundingClientRect();
      const visible = anchor.getAttribute('data-visible') !== 'false';
      return {
        id: anchor.getAttribute('data-id'),
        x: rect.left + rect.width / 2 - mvRect.left,
        y: rect.top + rect.height / 2 - mvRect.top,
        visible: visible
      };
    });
    if (window.AnatomyProjectionChannel) {
      window.AnatomyProjectionChannel.postMessage(JSON.stringify(payload));
    }
  }

  mv.addEventListener('load', postPositions);
  mv.addEventListener('camera-change', postPositions);
  mv.addEventListener('model-visibility', postPositions);
  setInterval(postPositions, 120);
})();
''';

const String _kAnchorCss = '''
.anatomy-anchor {
  display: block;
  width: 14px;
  height: 14px;
  border: 0;
  padding: 0;
  border-radius: 999px;
  background: transparent;
  pointer-events: none;
}
.anatomy-anchor[data-visible="false"] {
  opacity: 0;
}
''';
