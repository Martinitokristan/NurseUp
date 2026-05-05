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

class _ModelSurface extends StatelessWidget {
  const _ModelSurface({required this.assetPath, required this.autoRotate, required this.hotspots, required this.showLabels, required this.onHotspotTap, required this.fallbackIcon});

  final String assetPath;
  final bool autoRotate;
  final List<AnatomyHotspot> hotspots;
  final bool showLabels;
  final void Function(AnatomyHotspot) onHotspotTap;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolveSource(assetPath),
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
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(fallbackIcon, color: AppColors.primary, size: 112), const SizedBox(height: 12), Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('3D model unavailable.\nBundle the GLB file to view it.', style: AppTextStyles.caption, textAlign: TextAlign.center))]),
            ),
          );
        }
        return ModelViewer(
          key: ValueKey('${assetPath}_$showLabels'),
          src: src,
          ar: true,
          autoRotate: autoRotate,
          cameraControls: true,
          backgroundColor: Colors.transparent,
          disableZoom: false,
          innerModelViewerHtml: hotspots.isNotEmpty ? _buildHotspotHtml(hotspots) : null,
          relatedCss: hotspots.isNotEmpty ? _kHotspotCss : null,
          relatedJs: hotspots.isNotEmpty ? _kHotspotJs : null,
          minHotspotOpacity: 0,
          maxHotspotOpacity: showLabels ? 1.0 : 0.0,
          javascriptChannels: hotspots.isNotEmpty
              ? {
                  JavascriptChannel(
                    'AnatomyHotspotChannel',
                    onMessageReceived: (msg) {
                      final hotspot = _findHotspotById(hotspots, msg.message);
                      if (hotspot != null) onHotspotTap(hotspot);
                    },
                  ),
                }
              : null,
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
  for (var i = 0; i < hotspots.length; i++) {
    final h = hotspots[i];
    final safeId = _htmlEscape(h.id);
    final safeName = _htmlEscape(h.name);
    final sideClass = i.isEven ? 'label-right' : 'label-left';
    final position = _toModelViewerVector(h.position);
    final normal = _toModelViewerVector(h.normal);
    buf.write(
      '<button class="anatomy-hotspot $sideClass" '
      'slot="hotspot-$safeId" '
      'data-position="$position" '
      'data-normal="$normal" '
      'onclick="AnatomyHotspotChannel.postMessage(\'$safeId\');">'
      '<span class="target-dot"></span>'
      '<span class="leader-line"></span>'
      '<span class="annotation">$safeName</span>'
      '</button>',
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

AnatomyHotspot? _findHotspotById(List<AnatomyHotspot> hotspots, String id) {
  try {
    return hotspots.firstWhere((h) => h.id == id);
  } catch (_) {
    return null;
  }
}

String _htmlEscape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

const String _kHotspotJs = '''
(() => {
  const mv = document.querySelector('model-viewer');
  if (!mv) return;
  function syncVisibility() {
    mv.querySelectorAll('.anatomy-hotspot').forEach((hs) => {
      if (hs.getAttribute('data-visible') === 'false') {
        hs.style.opacity = '0';
        hs.style.pointerEvents = 'none';
      } else {
        hs.style.opacity = '';
        hs.style.pointerEvents = 'auto';
      }
    });
  }
  mv.addEventListener('load', syncVisibility);
  mv.addEventListener('camera-change', syncVisibility);
  setInterval(syncVisibility, 150);
})();
''';

const String _kHotspotCss = '''
.anatomy-hotspot {
  display: block;
  position: relative;
  width: 0;
  height: 0;
  border: 0;
  padding: 0;
  background: transparent;
  cursor: pointer;
  pointer-events: auto;
  transform: translate(-50%, -50%);
  transition: opacity .12s ease;
}
.target-dot {
  position: absolute;
  left: -7px;
  top: -7px;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: #1E88E5;
  border: 3px solid #FFFFFF;
  box-shadow: 0 2px 8px rgba(0,0,0,.35);
  z-index: 3;
}
.leader-line {
  position: absolute;
  left: 8px;
  top: -1px;
  width: 72px;
  height: 2px;
  background: rgba(15, 27, 45, .85);
  transform-origin: left center;
  z-index: 2;
}
.annotation {
  position: absolute;
  left: 82px;
  top: -17px;
  min-width: 86px;
  max-width: 170px;
  padding: 7px 11px;
  border-radius: 999px;
  background: rgba(255,255,255,.96);
  border: 1px solid rgba(30,136,229,.35);
  color: #0F1B2D;
  font-family: Poppins, Arial, sans-serif;
  font-size: 13px;
  font-weight: 800;
  line-height: 1.1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  box-shadow: 0 4px 14px rgba(0,0,0,.16);
  z-index: 1;
}
.anatomy-hotspot.label-left .leader-line {
  left: -80px;
}
.anatomy-hotspot.label-left .annotation {
  left: auto;
  right: 82px;
}
.anatomy-hotspot[data-visible="false"] {
  opacity: 0;
  pointer-events: none;
}
''';
