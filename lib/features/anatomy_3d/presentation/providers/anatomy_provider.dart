import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/anatomy_model_entity.dart';
import '../../../file_manager/presentation/providers/file_manager_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

// Confirmed models with available GLB assets
final _allAnatomyModels = const [
  AnatomyModelEntity(id: 'brain', name: 'Brain', assetPath: 'assets/models/anatomy/brain.glb', parts: 8, iconCodePoint: 0xe3f3, category: 'Nervous System'),
  AnatomyModelEntity(id: 'heart', name: 'Heart', assetPath: 'assets/models/anatomy/heart.glb', parts: 8, iconCodePoint: 0xe25b, category: 'Cardiovascular'),
  AnatomyModelEntity(id: 'lungs', name: 'Lungs', assetPath: 'assets/models/anatomy/lungs.glb', parts: 7, iconCodePoint: 0xe3a8, category: 'Respiratory'),
  AnatomyModelEntity(id: 'stomach', name: 'Stomach', assetPath: 'assets/models/anatomy/stomach.glb', parts: 5, iconCodePoint: 0xe56c, category: 'Digestive'),
  AnatomyModelEntity(id: 'liver', name: 'Liver', assetPath: 'assets/models/anatomy/liver.glb', parts: 4, iconCodePoint: 0xe56c, category: 'Digestive'),
  AnatomyModelEntity(id: 'kidney', name: 'Kidney', assetPath: 'assets/models/anatomy/kidney.glb', parts: 6, iconCodePoint: 0xe03e, category: 'Urinary'),
  AnatomyModelEntity(id: 'skeleton', name: 'Skeleton', assetPath: 'assets/models/anatomy/skeleton.glb', parts: 24, iconCodePoint: 0xe03e, category: 'Skeletal'),
  AnatomyModelEntity(id: 'eye', name: 'Eye', assetPath: 'assets/models/anatomy/eye.glb', parts: 7, iconCodePoint: 0xe3ab, category: 'Sensory'),
  AnatomyModelEntity(id: 'ear', name: 'Ear', assetPath: 'assets/models/anatomy/anatomi_telinga_ear_anatomy.glb', parts: 5, iconCodePoint: 0xe3ab, category: 'Sensory'),
];

/// Returns a model by its [id], or null if not found.
AnatomyModelEntity? anatomyModelById(String? id) {
  if (id == null || id.trim().isEmpty) return null;
  for (final model in _allAnatomyModels) {
    if (model.id == id) return model;
  }
  return null;
}

/// Keyword map used for scoring-based topic detection.
/// Multi-word keywords score 3x; single-word keywords score 1x per occurrence.
const Map<String, List<String>> anatomyTopicKeywords = {
  'brain': ['brain', 'neurology', 'neurological', 'nervous system', 'cerebral', 'cerebellum', 'brainstem', 'brain stem', 'neuron', 'cranial nerve', 'stroke', 'seizure', 'gcs'],
  'heart': ['heart', 'cardiac', 'cardio', 'cardiovascular', 'myocardial', 'atrium', 'ventricle', 'ecg', 'ekg', 'arrhythmia', 'hypertension', 'heart failure', 'coronary'],
  'lungs': ['lung', 'lungs', 'respiratory', 'pulmonary', 'breathing', 'oxygenation', 'alveoli', 'bronchi', 'asthma', 'copd', 'pneumonia', 'airway'],
  'stomach': ['stomach', 'gastric', 'digestion', 'digestive', 'abdomen', 'gastrointestinal', 'nausea', 'vomiting', 'ulcer'],
  'liver': ['liver', 'hepatic', 'hepatitis', 'bile', 'bilirubin', 'cirrhosis', 'jaundice'],
  'kidney': ['kidney', 'kidneys', 'renal', 'urinary', 'nephron', 'urine', 'creatinine', 'bun', 'dialysis', 'uti'],
  'skeleton': ['skeleton', 'skeletal', 'bone', 'bones', 'fracture', 'joint', 'orthopedic', 'osteoporosis', 'spine', 'vertebra'],
  'eye': ['eye', 'eyes', 'vision', 'visual', 'ocular', 'optic', 'retina', 'pupil', 'cataract', 'glaucoma'],
  'ear': ['ear', 'ears', 'hearing', 'auditory', 'tympanic', 'cochlea', 'otitis', 'vestibular'],
};

/// Detects the most likely anatomy model ID from free text using keyword scoring.
/// Returns null if confidence is too low (score < 2).
String? detectAnatomyTopic(String text) {
  final normalized = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]+'), ' ');
  final scores = <String, int>{};

  anatomyTopicKeywords.forEach((modelId, keywords) {
    var score = 0;
    for (final keyword in keywords) {
      final pattern = RegExp('(^|\\s)${RegExp.escape(keyword.toLowerCase())}(\\s|\$)');
      final matches = pattern.allMatches(normalized).length;
      if (matches > 0) score += matches * (keyword.contains(' ') ? 3 : 1);
    }
    if (score > 0) scores[modelId] = score;
  });

  if (scores.isEmpty) return null;
  final ranked = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  if (ranked.first.value < 2) return null;
  return ranked.first.key;
}

/// Detects and returns the matching [AnatomyModelEntity] from text, or null.
AnatomyModelEntity? detectAnatomyModel(String text) => anatomyModelById(detectAnatomyTopic(text));

/// All confirmed anatomy models — use for catalog display (Pro only).
final allAnatomyModelsProvider = Provider<List<AnatomyModelEntity>>((ref) => _allAnatomyModels);

/// Models matching the user's uploaded file topics (Pro only).
/// Falls back to all models when no files have detected topics.
final anatomyModelsProvider = Provider<List<AnatomyModelEntity>>((ref) {
  final isPro = ref.watch(subscriptionProvider);
  if (!isPro) return const [];

  final files = ref.watch(userFilesProvider).valueOrNull ?? const [];
  if (files.isEmpty) return _allAnatomyModels;

  final modelIds = <String>{};
  for (final file in files) {
    if (file.anatomyModelId != null && anatomyModelById(file.anatomyModelId) != null) {
      modelIds.add(file.anatomyModelId!);
      continue;
    }
    final fallbackId = detectAnatomyTopic(file.name);
    if (fallbackId != null) modelIds.add(fallbackId);
  }

  if (modelIds.isEmpty) return _allAnatomyModels;
  return _allAnatomyModels.where((m) => modelIds.contains(m.id)).toList();
});

IconData anatomyIcon(AnatomyModelEntity model) {
  // Use constant Icons.* values so Flutter can tree-shake icon fonts.
  switch (model.iconCodePoint) {
    case 0xe3f3:
      return Icons.psychology;
    case 0xe25b:
      return Icons.favorite;
    case 0xe3a8:
      return Icons.air;
    case 0xe56c:
      return Icons.restaurant;
    case 0xe03e:
      return Icons.accessibility_new;
    case 0xe87c:
      return Icons.face;
    case 0xe91e:
      return Icons.pregnant_woman;
    case 0xe3ab:
      return Icons.visibility;
    default:
      return Icons.medical_services;
  }
}

final anatomyHotspotsProvider = Provider<Map<String, List<AnatomyHotspot>>>((ref) {
  return const {
    'brain': [
      AnatomyHotspot(id: 'frontal_lobe', name: 'Frontal Lobe', position: '0.02 0.08 0.09', normal: '0 0.3 1', description: 'Controls reasoning, motor skills, and higher level thinking.', nursingSignificance: 'Assess for personality changes, motor weakness, and decision-making abilities after head injury.', pnleTip: 'Frontal lobe injuries often cause personality changes and impaired judgment.'),
      AnatomyHotspot(id: 'parietal_lobe', name: 'Parietal Lobe', position: '0 0.12 0.02', normal: '0 1 0.1', description: 'Processes sensory information and spatial awareness.', nursingSignificance: 'Monitor for sensory deficits and spatial disorientation in stroke patients.', pnleTip: 'Parietal lobe affects sensation and spatial awareness.'),
      AnatomyHotspot(id: 'temporal_lobe', name: 'Temporal Lobe', position: '-0.09 0.02 0.03', normal: '-1 0 0', description: 'Processes auditory information and memory.', nursingSignificance: 'Assess hearing and memory function in neurological patients.', pnleTip: 'Temporal lobe affects memory and hearing.'),
      AnatomyHotspot(id: 'occipital_lobe', name: 'Occipital Lobe', position: '0 0.06 -0.09', normal: '0 0.2 -1', description: 'Processes visual information.', nursingSignificance: 'Check visual fields and acuity in neurological assessments.', pnleTip: 'Occipital lobe controls vision.'),
      AnatomyHotspot(id: 'cerebellum', name: 'Cerebellum', position: '0 -0.06 -0.07', normal: '0 -0.3 -1', description: 'Coordinates movement and balance.', nursingSignificance: 'Assess coordination, balance, and fine motor skills.', pnleTip: 'Cerebellar dysfunction causes ataxia and coordination problems.'),
      AnatomyHotspot(id: 'brain_stem', name: 'Brain Stem', position: '0 -0.09 0.01', normal: '0 -1 0.2', description: 'Controls vital functions like breathing and heart rate.', nursingSignificance: 'Critical for life support - assess respiratory and cardiovascular status.', pnleTip: 'Brain stem injury is life-threatening - monitor ABCs closely.'),
      AnatomyHotspot(id: 'corpus_callosum', name: 'Corpus Callosum', position: '0.01 0.03 0.01', normal: '0 1 0', description: 'Connects the two hemispheres of the brain.', nursingSignificance: 'Facilitates communication between brain hemispheres.', pnleTip: 'Corpus callosum affects interhemispheric communication.'),
      AnatomyHotspot(id: 'hippocampus', name: 'Hippocampus', position: '-0.06 -0.01 0.02', normal: '-1 -0.2 0', description: 'Critical for memory formation.', nursingSignificance: 'Assess memory formation and recall in cognitive evaluations.', pnleTip: 'Hippocampus damage causes memory impairment.'),
    ],
    'heart': [
      AnatomyHotspot(id: 'aortic_valve', name: 'Aortic Valve', position: '0.02 0.09 0.02', normal: '0 1 0.2', description: 'Controls blood flow from left ventricle to aorta.', nursingSignificance: 'Listen for systolic murmur indicating stenosis or regurgitation.', pnleTip: 'Aortic stenosis causes systolic murmur radiating to carotids.'),
      AnatomyHotspot(id: 'pulmonary_valve', name: 'Pulmonary Valve', position: '-0.04 0.08 0.02', normal: '-0.3 1 0', description: 'Controls blood flow from right ventricle to pulmonary artery.', nursingSignificance: 'Assess for signs of pulmonary hypertension.', pnleTip: 'Pulmonary valve disease causes right-sided heart failure.'),
      AnatomyHotspot(id: 'mitral_valve', name: 'Mitral Valve', position: '0.03 0.04 0.04', normal: '0.2 0.5 1', description: 'Controls blood flow from left atrium to left ventricle.', nursingSignificance: 'Listen for diastolic murmur indicating mitral stenosis.', pnleTip: 'Mitral stenosis causes diastolic murmur and left atrial enlargement.'),
      AnatomyHotspot(id: 'tricuspid_valve', name: 'Tricuspid Valve', position: '-0.03 0.04 0.04', normal: '-0.2 0.5 1', description: 'Controls blood flow from right atrium to right ventricle.', nursingSignificance: 'Assess for signs of right-sided heart failure.', pnleTip: 'Tricuspid regurgitation causes systolic murmur at lower left sternal border.'),
      AnatomyHotspot(id: 'left_ventricle', name: 'Left Ventricle', position: '0.04 -0.02 0.03', normal: '1 0 0.3', description: 'Pumps oxygenated blood to the body.', nursingSignificance: 'Monitor for signs of left-sided heart failure.', pnleTip: 'Left ventricle is the strongest chamber - assess ejection fraction.'),
      AnatomyHotspot(id: 'right_ventricle', name: 'Right Ventricle', position: '-0.04 -0.02 0.04', normal: '-1 0 0.3', description: 'Pumps deoxygenated blood to lungs.', nursingSignificance: 'Assess for right-sided heart failure signs.', pnleTip: 'Right ventricle failure causes peripheral edema and JVD.'),
      AnatomyHotspot(id: 'left_atrium', name: 'Left Atrium', position: '0.03 0.07 -0.04', normal: '0.3 1 -0.5', description: 'Receives oxygenated blood from lungs.', nursingSignificance: 'Assess for atrial fibrillation and thrombus risk.', pnleTip: 'Left atrial enlargement increases stroke risk in AFib.'),
      AnatomyHotspot(id: 'right_atrium', name: 'Right Atrium', position: '-0.04 0.07 -0.03', normal: '-0.3 1 -0.3', description: 'Receives deoxygenated blood from body.', nursingSignificance: 'Monitor for signs of right atrial enlargement.', pnleTip: 'Right atrial enlargement occurs in right heart failure.'),
    ],
    'lungs': [
      AnatomyHotspot(id: 'right_upper_lobe', name: 'Right Upper Lobe', position: '0.07 0.1 0.01', normal: '1 0.5 0', description: 'Upper portion of right lung.', nursingSignificance: 'Auscultate anterior and posterior chest wall.', pnleTip: 'Right lung has 3 lobes - upper, middle, lower.'),
      AnatomyHotspot(id: 'right_middle_lobe', name: 'Right Middle Lobe', position: '0.08 0.04 0.02', normal: '1 0 0', description: 'Middle portion of right lung.', nursingSignificance: 'Common site for aspiration pneumonia.', pnleTip: 'Middle lobe syndrome causes atelectasis.'),
      AnatomyHotspot(id: 'right_lower_lobe', name: 'Right Lower Lobe', position: '0.06 -0.04 0', normal: '1 -0.3 0', description: 'Lower portion of right lung.', nursingSignificance: 'Auscultate for crackles indicating fluid accumulation.', pnleTip: 'Lower lobes are common sites for pneumonia.'),
      AnatomyHotspot(id: 'left_upper_lobe', name: 'Left Upper Lobe', position: '-0.07 0.1 0.01', normal: '-1 0.5 0', description: 'Upper portion of left lung.', nursingSignificance: 'Assess for breath sounds and percussion.', pnleTip: 'Left lung has 2 lobes - upper and lower.'),
      AnatomyHotspot(id: 'left_lower_lobe', name: 'Left Lower Lobe', position: '-0.06 -0.04 0', normal: '-1 -0.3 0', description: 'Lower portion of left lung.', nursingSignificance: 'Monitor for consolidation and atelectasis.', pnleTip: 'Left lower lobe is prone to aspiration.'),
      AnatomyHotspot(id: 'bronchi', name: 'Bronchi', position: '0 0.01 0.04', normal: '0 0 1', description: 'Main airways to lungs.', nursingSignificance: 'Assess for wheezing and breath sounds.', pnleTip: 'Bronchial sounds are louder and harsher than vesicular.'),
      AnatomyHotspot(id: 'trachea', name: 'Trachea', position: '0 0.14 0.06', normal: '0 0.3 1', description: 'Windpipe connecting throat to bronchi.', nursingSignificance: 'Maintain airway patency in emergency situations.', pnleTip: 'Trachea divides into right and left mainstem bronchi.'),
    ],
    'kidney': [
      AnatomyHotspot(id: 'renal_cortex', name: 'Renal Cortex', position: '0.04 0.03 0.05', normal: '0.5 0.3 1', description: 'Outer layer of kidney containing glomeruli.', nursingSignificance: 'Monitor GFR and filtration rate.', pnleTip: 'Cortex contains glomeruli for filtration.'),
      AnatomyHotspot(id: 'renal_medulla', name: 'Renal Medulla', position: '0 0 0.02', normal: '0 0 1', description: 'Inner portion containing renal pyramids.', nursingSignificance: 'Assess for medullary concentration ability.', pnleTip: 'Medulla concentrates urine through countercurrent exchange.'),
      AnatomyHotspot(id: 'renal_pelvis', name: 'Renal Pelvis', position: '-0.03 -0.03 0.02', normal: '-0.5 -0.5 0.7', description: 'Funnel-like structure collecting urine.', nursingSignificance: 'Monitor for hydronephrosis and obstruction.', pnleTip: 'Renal pelvis connects kidney to ureter.'),
      AnatomyHotspot(id: 'ureter', name: 'Ureter', position: '-0.04 -0.09 0', normal: '-0.3 -1 0', description: 'Tube carrying urine to bladder.', nursingSignificance: 'Assess for ureteral obstruction or stones.', pnleTip: 'Ureteral stones cause severe flank pain.'),
      AnatomyHotspot(id: 'renal_artery', name: 'Renal Artery', position: '0.06 0.05 0', normal: '1 0.5 0', description: 'Supplies blood to kidney.', nursingSignificance: 'Monitor renal blood flow and perfusion.', pnleTip: 'Renal artery stenosis causes hypertension.'),
      AnatomyHotspot(id: 'renal_vein', name: 'Renal Vein', position: '0.06 -0.05 0', normal: '1 -0.5 0', description: 'Drains blood from kidney.', nursingSignificance: 'Assess for renal vein thrombosis.', pnleTip: 'Renal vein drains into inferior vena cava.'),
    ],
    'skeleton': [
      AnatomyHotspot(id: 'skull', name: 'Skull', position: '0 0.2 0', normal: '0 1 0', description: 'Protects the brain and facial structures.', nursingSignificance: 'Assess for skull fractures after head trauma.', pnleTip: 'Skull fractures can cause brain injury.'),
      AnatomyHotspot(id: 'clavicle', name: 'Clavicle', position: '0.15 0.1 0', normal: '0 1 0', description: 'Collarbone connecting arm to trunk.', nursingSignificance: 'Assess for clavicle fractures and shoulder mobility.', pnleTip: 'Clavicle fractures are common after falls.'),
      AnatomyHotspot(id: 'sternum', name: 'Sternum', position: '0 0.05 0.05', normal: '0 1 0', description: 'Breastbone protecting heart and lungs.', nursingSignificance: 'Monitor for sternal pain after cardiac surgery.', pnleTip: 'Sternum is divided into manubrium, body, and xiphoid.'),
      AnatomyHotspot(id: 'humerus', name: 'Humerus', position: '0.2 0 0', normal: '0 1 0', description: 'Upper arm bone.', nursingSignificance: 'Assess for humeral fractures and arm mobility.', pnleTip: 'Humerus fractures can damage radial nerve.'),
      AnatomyHotspot(id: 'radius_ulna', name: 'Radius/Ulna', position: '0.25 -0.05 0', normal: '0 1 0', description: 'Forearm bones.', nursingSignificance: 'Assess for wrist and forearm fractures.', pnleTip: 'Radius and ulna rotate around each other.'),
      AnatomyHotspot(id: 'femur', name: 'Femur', position: '-0.15 -0.1 0', normal: '0 1 0', description: 'Thigh bone - strongest in body.', nursingSignificance: 'Assess for femoral fractures and hip mobility.', pnleTip: 'Femur fractures can cause significant blood loss.'),
      AnatomyHotspot(id: 'tibia_fibula', name: 'Tibia/Fibula', position: '-0.2 -0.2 0', normal: '0 1 0', description: 'Lower leg bones.', nursingSignificance: 'Assess for tibial fractures and ankle stability.', pnleTip: 'Tibia is weight-bearing, fibula provides stability.'),
      AnatomyHotspot(id: 'vertebral_column', name: 'Vertebral Column', position: '0 0 0', normal: '0 1 0', description: 'Spine protecting spinal cord.', nursingSignificance: 'Assess spinal alignment and cord function.', pnleTip: 'Spine has 7 cervical, 12 thoracic, 5 lumbar vertebrae.'),
    ],
  };
});

class AnatomyHotspot {
  const AnatomyHotspot({required this.id, required this.name, required this.position, required this.normal, required this.description, required this.nursingSignificance, required this.pnleTip});

  final String id;
  final String name;
  final String position;
  final String normal;
  final String description;
  final String nursingSignificance;
  final String pnleTip;
}
