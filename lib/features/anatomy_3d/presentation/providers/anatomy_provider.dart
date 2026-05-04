import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/anatomy_model_entity.dart';
import '../../../file_manager/presentation/providers/file_manager_provider.dart';
import '../../../usage/presentation/providers/usage_provider.dart';

// All available anatomy models (static definition)
final _allAnatomyModels = const [
  AnatomyModelEntity(id: 'brain', name: 'Brain', assetPath: 'assets/models/anatomy/brain.glb', parts: 8, iconCodePoint: 0xe3f3, category: 'Nervous System'),
  AnatomyModelEntity(id: 'heart', name: 'Heart', assetPath: 'assets/models/anatomy/heart.glb', parts: 8, iconCodePoint: 0xe25b, category: 'Cardiovascular'),
  AnatomyModelEntity(id: 'lungs', name: 'Lungs', assetPath: 'assets/models/anatomy/lungs.glb', parts: 7, iconCodePoint: 0xe3a8, category: 'Respiratory'),
  AnatomyModelEntity(id: 'stomach', name: 'Stomach', assetPath: 'assets/models/anatomy/stomach.glb', parts: 5, iconCodePoint: 0xe56c, category: 'Digestive'),
  AnatomyModelEntity(id: 'intestines', name: 'Intestines', assetPath: 'assets/models/anatomy/intestines.glb', parts: 6, iconCodePoint: 0xe56c, category: 'Digestive'),
  AnatomyModelEntity(id: 'liver', name: 'Liver', assetPath: 'assets/models/anatomy/liver.glb', parts: 4, iconCodePoint: 0xe56c, category: 'Digestive'),
  AnatomyModelEntity(id: 'kidney', name: 'Kidney', assetPath: 'assets/models/anatomy/kidney.glb', parts: 6, iconCodePoint: 0xe03e, category: 'Urinary'),
  AnatomyModelEntity(id: 'skeleton', name: 'Skeleton', assetPath: 'assets/models/anatomy/skeleton.glb', parts: 24, iconCodePoint: 0xe03e, category: 'Skeletal'),
  AnatomyModelEntity(id: 'skull', name: 'Skull', assetPath: 'assets/models/anatomy/skull.glb', parts: 10, iconCodePoint: 0xe87c, category: 'Skeletal'),
  AnatomyModelEntity(id: 'muscles', name: 'Muscles', assetPath: 'assets/models/anatomy/muscles.glb', parts: 12, iconCodePoint: 0xe3f3, category: 'Muscular'),
  AnatomyModelEntity(id: 'reproductive_female', name: 'Female Reproductive', assetPath: 'assets/models/anatomy/reproductive_female.glb', parts: 8, iconCodePoint: 0xe91e, category: 'Reproductive'),
  AnatomyModelEntity(id: 'reproductive_male', name: 'Male Reproductive', assetPath: 'assets/models/anatomy/reproductive_male.glb', parts: 6, iconCodePoint: 0xe91e, category: 'Reproductive'),
  AnatomyModelEntity(id: 'thyroid', name: 'Thyroid', assetPath: 'assets/models/anatomy/thyroid.glb', parts: 4, iconCodePoint: 0xe3a8, category: 'Endocrine'),
  AnatomyModelEntity(id: 'eye', name: 'Eye', assetPath: 'assets/models/anatomy/eye.glb', parts: 7, iconCodePoint: 0xe3ab, category: 'Sensory'),
  AnatomyModelEntity(id: 'ear', name: 'Ear', assetPath: 'assets/models/anatomy/ear.glb', parts: 5, iconCodePoint: 0xe3ab, category: 'Sensory'),
  AnatomyModelEntity(id: 'skin', name: 'Skin', assetPath: 'assets/models/anatomy/skin.glb', parts: 3, iconCodePoint: 0xe3f3, category: 'Integumentary'),
];

// Dynamic provider that returns models based on user's Pro status and uploaded topics
final anatomyModelsProvider = Provider<List<AnatomyModelEntity>>((ref) {
  final usageAsync = ref.watch(usageProvider);
  final filesAsync = ref.watch(userFilesProvider);
  
  // If not Pro, return empty list
  final usage = usageAsync.valueOrNull;
  if (usage == null || usage.tier != 'pro') {
    return [];
  }
  
  // Get user's uploaded files
  final files = filesAsync.valueOrNull ?? [];
  if (files.isEmpty) {
    return [];
  }
  
  // Extract topics from file names
  final availableTopics = _extractTopicsFromFiles(files);
  
  // Return only models that match available topics
  return _allAnatomyModels.where((model) => availableTopics.contains(model.id)).toList();
});

// Extract anatomy topics from file names
Set<String> _extractTopicsFromFiles(List files) {
  final topics = <String>{};
  final topicMapping = {
    'brain': ['brain', 'neurology', 'nervous', 'cerebral', 'cranial'],
    'heart': ['heart', 'cardiac', 'cardio', 'cardiovascular'],
    'lungs': ['lungs', 'lung', 'respiratory', 'pulmonary', 'breathing'],
    'stomach': ['stomach', 'gastric', 'digestion', 'digestive'],
    'intestines': ['intestine', 'bowel', 'colon'],
    'liver': ['liver', 'hepatic', 'bile'],
    'kidney': ['kidney', 'renal', 'urinary', 'nephro'],
    'skeleton': ['skeleton', 'skeletal', 'bone', 'bones', 'fracture'],
    'skull': ['skull', 'cranium', 'head'],
    'muscles': ['muscle', 'muscular', 'myology'],
    'reproductive_female': ['uterus', 'ovary', 'maternal', 'obstetric', 'reproductive'],
    'reproductive_male': ['prostate', 'testicular'],
    'thyroid': ['thyroid', 'endocrine', 'hormone'],
    'eye': ['eye', 'vision', 'ocular', 'optic'],
    'ear': ['ear', 'hearing', 'auditory'],
    'skin': ['skin', 'integumentary', 'dermal', 'wound'],
  };
  
  for (final file in files) {
    final fileName = file.name.toLowerCase();
    topicMapping.forEach((modelId, keywords) {
      for (final keyword in keywords) {
        if (fileName.contains(keyword)) {
          topics.add(modelId);
          break;
        }
      }
    });
  }
  
  return topics;
}

final topicToModelProvider = Provider<Map<String, String>>((ref) {
  return const {
    'brain': 'assets/models/anatomy/brain.glb',
    'neurology': 'assets/models/anatomy/brain.glb',
    'nervous': 'assets/models/anatomy/brain.glb',
    'cerebral': 'assets/models/anatomy/brain.glb',
    'cranial': 'assets/models/anatomy/brain.glb',
    'heart': 'assets/models/anatomy/heart.glb',
    'cardiac': 'assets/models/anatomy/heart.glb',
    'cardio': 'assets/models/anatomy/heart.glb',
    'cardiovascular': 'assets/models/anatomy/heart.glb',
    'lungs': 'assets/models/anatomy/lungs.glb',
    'lung': 'assets/models/anatomy/lungs.glb',
    'respiratory': 'assets/models/anatomy/lungs.glb',
    'pulmonary': 'assets/models/anatomy/lungs.glb',
    'breathing': 'assets/models/anatomy/lungs.glb',
    'stomach': 'assets/models/anatomy/stomach.glb',
    'gastric': 'assets/models/anatomy/stomach.glb',
    'digestion': 'assets/models/anatomy/stomach.glb',
    'digestive': 'assets/models/anatomy/stomach.glb',
    'intestine': 'assets/models/anatomy/intestines.glb',
    'bowel': 'assets/models/anatomy/intestines.glb',
    'colon': 'assets/models/anatomy/intestines.glb',
    'liver': 'assets/models/anatomy/liver.glb',
    'hepatic': 'assets/models/anatomy/liver.glb',
    'bile': 'assets/models/anatomy/liver.glb',
    'kidney': 'assets/models/anatomy/kidney.glb',
    'renal': 'assets/models/anatomy/kidney.glb',
    'urinary': 'assets/models/anatomy/kidney.glb',
    'nephro': 'assets/models/anatomy/kidney.glb',
    'skeleton': 'assets/models/anatomy/skeleton.glb',
    'skeletal': 'assets/models/anatomy/skeleton.glb',
    'bone': 'assets/models/anatomy/skeleton.glb',
    'bones': 'assets/models/anatomy/skeleton.glb',
    'fracture': 'assets/models/anatomy/skeleton.glb',
    'skull': 'assets/models/anatomy/skull.glb',
    'cranium': 'assets/models/anatomy/skull.glb',
    'head': 'assets/models/anatomy/skull.glb',
    'muscle': 'assets/models/anatomy/muscles.glb',
    'muscular': 'assets/models/anatomy/muscles.glb',
    'myology': 'assets/models/anatomy/muscles.glb',
    'uterus': 'assets/models/anatomy/reproductive_female.glb',
    'ovary': 'assets/models/anatomy/reproductive_female.glb',
    'maternal': 'assets/models/anatomy/reproductive_female.glb',
    'obstetric': 'assets/models/anatomy/reproductive_female.glb',
    'reproductive': 'assets/models/anatomy/reproductive_female.glb',
    'prostate': 'assets/models/anatomy/reproductive_male.glb',
    'testicular': 'assets/models/anatomy/reproductive_male.glb',
    'thyroid': 'assets/models/anatomy/thyroid.glb',
    'endocrine': 'assets/models/anatomy/thyroid.glb',
    'hormone': 'assets/models/anatomy/thyroid.glb',
    'eye': 'assets/models/anatomy/eye.glb',
    'vision': 'assets/models/anatomy/eye.glb',
    'ocular': 'assets/models/anatomy/eye.glb',
    'optic': 'assets/models/anatomy/eye.glb',
    'ear': 'assets/models/anatomy/ear.glb',
    'hearing': 'assets/models/anatomy/ear.glb',
    'auditory': 'assets/models/anatomy/ear.glb',
    'skin': 'assets/models/anatomy/skin.glb',
    'integumentary': 'assets/models/anatomy/skin.glb',
    'dermal': 'assets/models/anatomy/skin.glb',
    'wound': 'assets/models/anatomy/skin.glb',
  };
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

String? detectAnatomyTopic(String text) {
  final topicToModel = const {
    'brain': 'assets/models/anatomy/brain.glb',
    'neurology': 'assets/models/anatomy/brain.glb',
    'nervous': 'assets/models/anatomy/brain.glb',
    'cerebral': 'assets/models/anatomy/brain.glb',
    'cranial': 'assets/models/anatomy/brain.glb',
    'heart': 'assets/models/anatomy/heart.glb',
    'cardiac': 'assets/models/anatomy/heart.glb',
    'cardio': 'assets/models/anatomy/heart.glb',
    'cardiovascular': 'assets/models/anatomy/heart.glb',
    'lungs': 'assets/models/anatomy/lungs.glb',
    'lung': 'assets/models/anatomy/lungs.glb',
    'respiratory': 'assets/models/anatomy/lungs.glb',
    'pulmonary': 'assets/models/anatomy/lungs.glb',
    'breathing': 'assets/models/anatomy/lungs.glb',
    'stomach': 'assets/models/anatomy/stomach.glb',
    'gastric': 'assets/models/anatomy/stomach.glb',
    'digestion': 'assets/models/anatomy/stomach.glb',
    'digestive': 'assets/models/anatomy/stomach.glb',
    'intestine': 'assets/models/anatomy/intestines.glb',
    'bowel': 'assets/models/anatomy/intestines.glb',
    'colon': 'assets/models/anatomy/intestines.glb',
    'liver': 'assets/models/anatomy/liver.glb',
    'hepatic': 'assets/models/anatomy/liver.glb',
    'bile': 'assets/models/anatomy/liver.glb',
    'kidney': 'assets/models/anatomy/kidney.glb',
    'renal': 'assets/models/anatomy/kidney.glb',
    'urinary': 'assets/models/anatomy/kidney.glb',
    'nephro': 'assets/models/anatomy/kidney.glb',
    'skeleton': 'assets/models/anatomy/skeleton.glb',
    'skeletal': 'assets/models/anatomy/skeleton.glb',
    'bone': 'assets/models/anatomy/skeleton.glb',
    'bones': 'assets/models/anatomy/skeleton.glb',
    'fracture': 'assets/models/anatomy/skeleton.glb',
    'skull': 'assets/models/anatomy/skull.glb',
    'cranium': 'assets/models/anatomy/skull.glb',
    'head': 'assets/models/anatomy/skull.glb',
    'muscle': 'assets/models/anatomy/muscles.glb',
    'muscular': 'assets/models/anatomy/muscles.glb',
    'myology': 'assets/models/anatomy/muscles.glb',
    'uterus': 'assets/models/anatomy/reproductive_female.glb',
    'ovary': 'assets/models/anatomy/reproductive_female.glb',
    'maternal': 'assets/models/anatomy/reproductive_female.glb',
    'obstetric': 'assets/models/anatomy/reproductive_female.glb',
    'reproductive': 'assets/models/anatomy/reproductive_female.glb',
    'prostate': 'assets/models/anatomy/reproductive_male.glb',
    'testicular': 'assets/models/anatomy/reproductive_male.glb',
    'thyroid': 'assets/models/anatomy/thyroid.glb',
    'endocrine': 'assets/models/anatomy/thyroid.glb',
    'hormone': 'assets/models/anatomy/thyroid.glb',
    'eye': 'assets/models/anatomy/eye.glb',
    'vision': 'assets/models/anatomy/eye.glb',
    'ocular': 'assets/models/anatomy/eye.glb',
    'optic': 'assets/models/anatomy/eye.glb',
    'ear': 'assets/models/anatomy/ear.glb',
    'hearing': 'assets/models/anatomy/ear.glb',
    'auditory': 'assets/models/anatomy/ear.glb',
    'skin': 'assets/models/anatomy/skin.glb',
    'integumentary': 'assets/models/anatomy/skin.glb',
    'dermal': 'assets/models/anatomy/skin.glb',
    'wound': 'assets/models/anatomy/skin.glb',
  };
  
  final lowerText = text.toLowerCase();
  for (final keyword in topicToModel.keys) {
    if (lowerText.contains(keyword)) {
      final modelPath = topicToModel[keyword]!;
      final models = const [
        AnatomyModelEntity(id: 'brain', name: 'Brain', assetPath: 'assets/models/anatomy/brain.glb', parts: 8, iconCodePoint: 0xe3f3, category: 'Nervous System'),
        AnatomyModelEntity(id: 'heart', name: 'Heart', assetPath: 'assets/models/anatomy/heart.glb', parts: 8, iconCodePoint: 0xe25b, category: 'Cardiovascular'),
        AnatomyModelEntity(id: 'lungs', name: 'Lungs', assetPath: 'assets/models/anatomy/lungs.glb', parts: 7, iconCodePoint: 0xe3a8, category: 'Respiratory'),
        AnatomyModelEntity(id: 'stomach', name: 'Stomach', assetPath: 'assets/models/anatomy/stomach.glb', parts: 5, iconCodePoint: 0xe56c, category: 'Digestive'),
        AnatomyModelEntity(id: 'intestines', name: 'Intestines', assetPath: 'assets/models/anatomy/intestines.glb', parts: 6, iconCodePoint: 0xe56c, category: 'Digestive'),
        AnatomyModelEntity(id: 'liver', name: 'Liver', assetPath: 'assets/models/anatomy/liver.glb', parts: 4, iconCodePoint: 0xe56c, category: 'Digestive'),
        AnatomyModelEntity(id: 'kidney', name: 'Kidney', assetPath: 'assets/models/anatomy/kidney.glb', parts: 6, iconCodePoint: 0xe03e, category: 'Urinary'),
        AnatomyModelEntity(id: 'skeleton', name: 'Skeleton', assetPath: 'assets/models/anatomy/skeleton.glb', parts: 24, iconCodePoint: 0xe03e, category: 'Skeletal'),
        AnatomyModelEntity(id: 'skull', name: 'Skull', assetPath: 'assets/models/anatomy/skull.glb', parts: 10, iconCodePoint: 0xe87c, category: 'Skeletal'),
        AnatomyModelEntity(id: 'muscles', name: 'Muscles', assetPath: 'assets/models/anatomy/muscles.glb', parts: 12, iconCodePoint: 0xe3f3, category: 'Muscular'),
        AnatomyModelEntity(id: 'reproductive_female', name: 'Female Reproductive', assetPath: 'assets/models/anatomy/reproductive_female.glb', parts: 8, iconCodePoint: 0xe91e, category: 'Reproductive'),
        AnatomyModelEntity(id: 'reproductive_male', name: 'Male Reproductive', assetPath: 'assets/models/anatomy/reproductive_male.glb', parts: 6, iconCodePoint: 0xe91e, category: 'Reproductive'),
        AnatomyModelEntity(id: 'thyroid', name: 'Thyroid', assetPath: 'assets/models/anatomy/thyroid.glb', parts: 4, iconCodePoint: 0xe3a8, category: 'Endocrine'),
        AnatomyModelEntity(id: 'eye', name: 'Eye', assetPath: 'assets/models/anatomy/eye.glb', parts: 7, iconCodePoint: 0xe3ab, category: 'Sensory'),
        AnatomyModelEntity(id: 'ear', name: 'Ear', assetPath: 'assets/models/anatomy/ear.glb', parts: 5, iconCodePoint: 0xe3ab, category: 'Sensory'),
        AnatomyModelEntity(id: 'skin', name: 'Skin', assetPath: 'assets/models/anatomy/skin.glb', parts: 3, iconCodePoint: 0xe3f3, category: 'Integumentary'),
      ];
      final model = models.firstWhere((m) => m.assetPath == modelPath);
      return model.id;
    }
  }
  return null;
}

final anatomyHotspotsProvider = Provider<Map<String, List<AnatomyHotspot>>>((ref) {
  return const {
    'brain': [
      AnatomyHotspot(id: 'frontal_lobe', name: 'Frontal Lobe', position: '0 0.1 0.05', normal: '0 1 0', description: 'Controls reasoning, motor skills, and higher level thinking.', nursingSignificance: 'Assess for personality changes, motor weakness, and decision-making abilities after head injury.', pnleTip: 'Frontal lobe injuries often cause personality changes and impaired judgment.'),
      AnatomyHotspot(id: 'parietal_lobe', name: 'Parietal Lobe', position: '0 0.15 0', normal: '0 1 0', description: 'Processes sensory information and spatial awareness.', nursingSignificance: 'Monitor for sensory deficits and spatial disorientation in stroke patients.', pnleTip: 'Parietal lobe affects sensation and spatial awareness.'),
      AnatomyHotspot(id: 'temporal_lobe', name: 'Temporal Lobe', position: '-0.05 0.05 0', normal: '0 1 0', description: 'Processes auditory information and memory.', nursingSignificance: 'Assess hearing and memory function in neurological patients.', pnleTip: 'Temporal lobe affects memory and hearing.'),
      AnatomyHotspot(id: 'occipital_lobe', name: 'Occipital Lobe', position: '0 0.05 -0.05', normal: '0 1 0', description: 'Processes visual information.', nursingSignificance: 'Check visual fields and acuity in neurological assessments.', pnleTip: 'Occipital lobe controls vision.'),
      AnatomyHotspot(id: 'cerebellum', name: 'Cerebellum', position: '0 -0.05 -0.03', normal: '0 1 0', description: 'Coordinates movement and balance.', nursingSignificance: 'Assess coordination, balance, and fine motor skills.', pnleTip: 'Cerebellar dysfunction causes ataxia and coordination problems.'),
      AnatomyHotspot(id: 'brain_stem', name: 'Brain Stem', position: '0 -0.1 0', normal: '0 1 0', description: 'Controls vital functions like breathing and heart rate.', nursingSignificance: 'Critical for life support - assess respiratory and cardiovascular status.', pnleTip: 'Brain stem injury is life-threatening - monitor ABCs closely.'),
      AnatomyHotspot(id: 'corpus_callosum', name: 'Corpus Callosum', position: '0 0 0', normal: '0 1 0', description: 'Connects the two hemispheres of the brain.', nursingSignificance: 'Facilitates communication between brain hemispheres.', pnleTip: 'Corpus callosum affects interhemispheric communication.'),
      AnatomyHotspot(id: 'hippocampus', name: 'Hippocampus', position: '-0.03 0 0.02', normal: '0 1 0', description: 'Critical for memory formation.', nursingSignificance: 'Assess memory formation and recall in cognitive evaluations.', pnleTip: 'Hippocampus damage causes memory impairment.'),
    ],
    'heart': [
      AnatomyHotspot(id: 'aortic_valve', name: 'Aortic Valve', position: '0.05 0.1 0', normal: '0 1 0', description: 'Controls blood flow from left ventricle to aorta.', nursingSignificance: 'Listen for systolic murmur indicating stenosis or regurgitation.', pnleTip: 'Aortic stenosis causes systolic murmur radiating to carotids.'),
      AnatomyHotspot(id: 'pulmonary_valve', name: 'Pulmonary Valve', position: '-0.05 0.05 0', normal: '0 1 0', description: 'Controls blood flow from right ventricle to pulmonary artery.', nursingSignificance: 'Assess for signs of pulmonary hypertension.', pnleTip: 'Pulmonary valve disease causes right-sided heart failure.'),
      AnatomyHotspot(id: 'mitral_valve', name: 'Mitral Valve', position: '0 0.05 0.03', normal: '0 1 0', description: 'Controls blood flow from left atrium to left ventricle.', nursingSignificance: 'Listen for diastolic murmur indicating mitral stenosis.', pnleTip: 'Mitral stenosis causes diastolic murmur and left atrial enlargement.'),
      AnatomyHotspot(id: 'tricuspid_valve', name: 'Tricuspid Valve', position: '0 -0.05 -0.03', normal: '0 1 0', description: 'Controls blood flow from right atrium to right ventricle.', nursingSignificance: 'Assess for signs of right-sided heart failure.', pnleTip: 'Tricuspid regurgitation causes systolic murmur at lower left sternal border.'),
      AnatomyHotspot(id: 'left_ventricle', name: 'Left Ventricle', position: '0.03 0 0', normal: '0 1 0', description: 'Pumps oxygenated blood to the body.', nursingSignificance: 'Monitor for signs of left-sided heart failure.', pnleTip: 'Left ventricle is the strongest chamber - assess ejection fraction.'),
      AnatomyHotspot(id: 'right_ventricle', name: 'Right Ventricle', position: '-0.03 0 0', normal: '0 1 0', description: 'Pumps deoxygenated blood to lungs.', nursingSignificance: 'Assess for right-sided heart failure signs.', pnleTip: 'Right ventricle failure causes peripheral edema and JVD.'),
      AnatomyHotspot(id: 'left_atrium', name: 'Left Atrium', position: '0 0.08 0.05', normal: '0 1 0', description: 'Receives oxygenated blood from lungs.', nursingSignificance: 'Assess for atrial fibrillation and thrombus risk.', pnleTip: 'Left atrial enlargement increases stroke risk in AFib.'),
      AnatomyHotspot(id: 'right_atrium', name: 'Right Atrium', position: '0 -0.08 -0.05', normal: '0 1 0', description: 'Receives deoxygenated blood from body.', nursingSignificance: 'Monitor for signs of right atrial enlargement.', pnleTip: 'Right atrial enlargement occurs in right heart failure.'),
    ],
    'lungs': [
      AnatomyHotspot(id: 'right_upper_lobe', name: 'Right Upper Lobe', position: '0.05 0.1 0', normal: '0 1 0', description: 'Upper portion of right lung.', nursingSignificance: 'Auscultate anterior and posterior chest wall.', pnleTip: 'Right lung has 3 lobes - upper, middle, lower.'),
      AnatomyHotspot(id: 'right_middle_lobe', name: 'Right Middle Lobe', position: '0.03 0.05 0', normal: '0 1 0', description: 'Middle portion of right lung.', nursingSignificance: 'Common site for aspiration pneumonia.', pnleTip: 'Middle lobe syndrome causes atelectasis.'),
      AnatomyHotspot(id: 'right_lower_lobe', name: 'Right Lower Lobe', position: '0.01 0 0', normal: '0 1 0', description: 'Lower portion of right lung.', nursingSignificance: 'Auscillate for crackles indicating fluid accumulation.', pnleTip: 'Lower lobes are common sites for pneumonia.'),
      AnatomyHotspot(id: 'left_upper_lobe', name: 'Left Upper Lobe', position: '-0.05 0.1 0', normal: '0 1 0', description: 'Upper portion of left lung.', nursingSignificance: 'Assess for breath sounds and percussion.', pnleTip: 'Left lung has 2 lobes - upper and lower.'),
      AnatomyHotspot(id: 'left_lower_lobe', name: 'Left Lower Lobe', position: '-0.03 0 0', normal: '0 1 0', description: 'Lower portion of left lung.', nursingSignificance: 'Monitor for consolidation and atelectasis.', pnleTip: 'Left lower lobe is prone to aspiration.'),
      AnatomyHotspot(id: 'bronchi', name: 'Bronchi', position: '0 0 0.05', normal: '0 1 0', description: 'Main airways to lungs.', nursingSignificance: 'Assess for wheezing and breath sounds.', pnleTip: 'Bronchial sounds are louder and harsher than vesicular.'),
      AnatomyHotspot(id: 'trachea', name: 'Trachea', position: '0 0.15 0.1', normal: '0 1 0', description: 'Windpipe connecting throat to bronchi.', nursingSignificance: 'Maintain airway patency in emergency situations.', pnleTip: 'Trachea divides into right and left mainstem bronchi.'),
    ],
    'kidney': [
      AnatomyHotspot(id: 'renal_cortex', name: 'Renal Cortex', position: '0.05 0.05 0', normal: '0 1 0', description: 'Outer layer of kidney containing glomeruli.', nursingSignificance: 'Monitor GFR and filtration rate.', pnleTip: 'Cortex contains glomeruli for filtration.'),
      AnatomyHotspot(id: 'renal_medulla', name: 'Renal Medulla', position: '0 0 0', normal: '0 1 0', description: 'Inner portion containing renal pyramids.', nursingSignificance: 'Assess for medullary concentration ability.', pnleTip: 'Medulla concentrates urine through countercurrent exchange.'),
      AnatomyHotspot(id: 'renal_pelvis', name: 'Renal Pelvis', position: '-0.05 -0.05 0', normal: '0 1 0', description: 'Funnel-like structure collecting urine.', nursingSignificance: 'Monitor for hydronephrosis and obstruction.', pnleTip: 'Renal pelvis connects kidney to ureter.'),
      AnatomyHotspot(id: 'ureter', name: 'Ureter', position: '-0.1 -0.1 0', normal: '0 1 0', description: 'Tube carrying urine to bladder.', nursingSignificance: 'Assess for ureteral obstruction or stones.', pnleTip: 'Ureteral stones cause severe flank pain.'),
      AnatomyHotspot(id: 'renal_artery', name: 'Renal Artery', position: '0.1 0.1 0', normal: '0 1 0', description: 'Supplies blood to kidney.', nursingSignificance: 'Monitor renal blood flow and perfusion.', pnleTip: 'Renal artery stenosis causes hypertension.'),
      AnatomyHotspot(id: 'renal_vein', name: 'Renal Vein', position: '0.08 -0.1 0', normal: '0 1 0', description: 'Drains blood from kidney.', nursingSignificance: 'Assess for renal vein thrombosis.', pnleTip: 'Renal vein drains into inferior vena cava.'),
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
