/// Crop information database with growth data, care tips, and recommendations
/// Based on Bangladesh agricultural practices

class CropInfo {
  final String name;
  final String nameBn;
  final String icon;
  final int growthDurationDays;
  final String season;
  final String seasonBn;
  final List<String> careTopics;
  final List<String> careTopicsBn;
  final Map<String, StageInfo> stages;
  final List<String> commonDiseases;
  final List<String> commonPests;
  final double waterRequirement; // mm per week
  final String optimalTemp;
  final String description;
  final String descriptionBn;

  const CropInfo({
    required this.name,
    required this.nameBn,
    required this.icon,
    required this.growthDurationDays,
    required this.season,
    required this.seasonBn,
    required this.careTopics,
    required this.careTopicsBn,
    required this.stages,
    required this.commonDiseases,
    required this.commonPests,
    required this.waterRequirement,
    required this.optimalTemp,
    required this.description,
    required this.descriptionBn,
  });
}

class StageInfo {
  final String name;
  final String nameBn;
  final int startDay;
  final int endDay;
  final String care;
  final String careBn;
  final List<String> warnings;
  final List<String> warningsBn;

  const StageInfo({
    required this.name,
    required this.nameBn,
    required this.startDay,
    required this.endDay,
    required this.care,
    required this.careBn,
    required this.warnings,
    required this.warningsBn,
  });
}

class CropInfoService {
  static final CropInfoService _instance = CropInfoService._internal();

  factory CropInfoService() => _instance;

  CropInfoService._internal();

  /// Get all available crops
  List<String> getAvailableCrops() => _cropDatabase.keys.toList();

  /// Get crop info by name
  CropInfo? getCropInfo(String cropName) {
    final key = cropName.toLowerCase();
    return _cropDatabase[key];
  }

  /// Get current stage info for a crop based on days since planting
  StageInfo? getCurrentStageInfo(String cropName, int daysSincePlanting) {
    final crop = getCropInfo(cropName);
    if (crop == null) return null;

    for (final stage in crop.stages.values) {
      if (daysSincePlanting >= stage.startDay &&
          daysSincePlanting <= stage.endDay) {
        return stage;
      }
    }
    return crop.stages.values.last;
  }

  /// Get care recommendations for current stage
  List<String> getCareRecommendations(
    String cropName,
    int daysSincePlanting, {
    bool isBangla = false,
  }) {
    final crop = getCropInfo(cropName);
    if (crop == null) return [];

    final stage = getCurrentStageInfo(cropName, daysSincePlanting);
    if (stage == null) return [];

    final recommendations = <String>[];
    recommendations.add(isBangla ? stage.careBn : stage.care);
    recommendations.addAll(isBangla ? stage.warningsBn : stage.warnings);

    return recommendations;
  }

  /// Get warnings based on weather conditions
  List<Map<String, dynamic>> getWeatherBasedWarnings(
    String cropName,
    int daysSincePlanting, {
    double? currentTemp,
    double? humidity,
    double? precipitation,
    bool isBangla = false,
  }) {
    final crop = getCropInfo(cropName);
    if (crop == null) return [];

    final warnings = <Map<String, dynamic>>[];
    final stage = getCurrentStageInfo(cropName, daysSincePlanting);

    // Temperature warnings
    if (currentTemp != null) {
      if (currentTemp > 35) {
        warnings.add({
          'severity': 'high',
          'message': isBangla
              ? 'উচ্চ তাপমাত্রা! ${crop.nameBn} এর জন্য অতিরিক্ত সেচ দিন।'
              : 'High temperature! Provide extra irrigation for ${crop.name}.',
          'icon': 'wb_sunny',
        });
      } else if (currentTemp < 10) {
        warnings.add({
          'severity': 'high',
          'message': isBangla
              ? 'নিম্ন তাপমাত্রা! ${crop.nameBn} ক্ষতিগ্রস্ত হতে পারে।'
              : 'Low temperature! ${crop.name} may be affected.',
          'icon': 'ac_unit',
        });
      }
    }

    // Humidity warnings for disease
    if (humidity != null && humidity > 85) {
      warnings.add({
        'severity': 'medium',
        'message': isBangla
            ? 'উচ্চ আর্দ্রতা! ছত্রাক রোগের ঝুঁকি বাড়ছে।'
            : 'High humidity! Increased risk of fungal diseases.',
        'icon': 'water_drop',
      });
    }

    // Stage-specific warnings
    if (stage != null) {
      for (final warning in (isBangla ? stage.warningsBn : stage.warnings)) {
        warnings.add({'severity': 'info', 'message': warning, 'icon': 'info'});
      }
    }

    return warnings;
  }

  /// Crop database
  static const Map<String, CropInfo> _cropDatabase = {
    'rice': CropInfo(
      name: 'Rice',
      nameBn: 'ধান',
      icon: '🌾',
      growthDurationDays: 120,
      season: 'Kharif (June-November)',
      seasonBn: 'খরিফ (জুন-নভেম্বর)',
      careTopics: [
        'Water management',
        'Weed control',
        'Pest monitoring',
        'Fertilizer application',
      ],
      careTopicsBn: [
        'পানি ব্যবস্থাপনা',
        'আগাছা নিয়ন্ত্রণ',
        'পোকা পর্যবেক্ষণ',
        'সার প্রয়োগ',
      ],
      stages: {
        'germination': StageInfo(
          name: 'Germination',
          nameBn: 'অঙ্কুরোদগম',
          startDay: 0,
          endDay: 14,
          care:
              'Maintain 2-3 cm standing water. Ensure proper seedbed preparation.',
          careBn: '২-৩ সেমি পানি রাখুন। সঠিক বীজতলা তৈরি নিশ্চিত করুন।',
          warnings: [
            'Watch for birds eating seeds',
            'Check for proper germination',
          ],
          warningsBn: [
            'পাখি থেকে বীজ রক্ষা করুন',
            'সঠিক অঙ্কুরোদগম পরীক্ষা করুন',
          ],
        ),
        'vegetative': StageInfo(
          name: 'Vegetative (Tillering)',
          nameBn: 'বৃদ্ধি পর্যায় (কুশি)',
          startDay: 15,
          endDay: 50,
          care:
              'Apply first dose of urea. Maintain 5cm water level. Control weeds.',
          careBn:
              'ইউরিয়ার প্রথম ডোজ দিন। ৫ সেমি পানি রাখুন। আগাছা নিয়ন্ত্রণ করুন।',
          warnings: ['Monitor for stem borer', 'Check for BPH infestation'],
          warningsBn: [
            'মাজরা পোকা পর্যবেক্ষণ করুন',
            'বাদামী গাছফড়িং পরীক্ষা করুন',
          ],
        ),
        'flowering': StageInfo(
          name: 'Flowering (Panicle)',
          nameBn: 'ফুল আসার সময় (শীষ)',
          startDay: 51,
          endDay: 80,
          care:
              'Apply second dose of urea at panicle initiation. Maintain consistent water.',
          careBn:
              'শীষ আসার সময় ইউরিয়ার দ্বিতীয় ডোজ দিন। পানির স্তর ধরে রাখুন।',
          warnings: [
            'Critical stage - avoid water stress',
            'Watch for blast disease',
          ],
          warningsBn: [
            'গুরুত্বপূর্ণ পর্যায় - পানির অভাব এড়িয়ে চলুন',
            'ব্লাস্ট রোগ দেখুন',
          ],
        ),
        'fruiting': StageInfo(
          name: 'Grain Filling',
          nameBn: 'দানা পুষ্ট হওয়া',
          startDay: 81,
          endDay: 105,
          care: 'Reduce water gradually. Monitor for diseases.',
          careBn: 'ধীরে ধীরে পানি কমান। রোগ পর্যবেক্ষণ করুন।',
          warnings: ['Check for sheath blight', 'Protect from birds'],
          warningsBn: ['শিথ ব্লাইট পরীক্ষা করুন', 'পাখি থেকে রক্ষা করুন'],
        ),
        'maturation': StageInfo(
          name: 'Maturation',
          nameBn: 'পরিপক্বতা',
          startDay: 106,
          endDay: 120,
          care: 'Drain field 2 weeks before harvest. Check grain moisture.',
          careBn: 'কাটার ২ সপ্তাহ আগে জমি শুকান। দানার আর্দ্রতা পরীক্ষা করুন।',
          warnings: ['Harvest at 20-22% moisture', 'Avoid over-ripening'],
          warningsBn: ['২০-২২% আর্দ্রতায় কাটুন', 'অতিরিক্ত পাকা এড়িয়ে চলুন'],
        ),
      },
      commonDiseases: [
        'Blast',
        'Sheath blight',
        'Brown spot',
        'Bacterial leaf blight',
      ],
      commonPests: ['Stem borer', 'BPH', 'Leaf folder', 'Gall midge'],
      waterRequirement: 50,
      optimalTemp: '25-30°C',
      description:
          'Rice is the staple food crop of Bangladesh, grown mainly during the monsoon season.',
      descriptionBn:
          'ধান বাংলাদেশের প্রধান খাদ্য ফসল, প্রধানত বর্ষা মৌসুমে চাষ করা হয়।',
    ),
    'wheat': CropInfo(
      name: 'Wheat',
      nameBn: 'গম',
      icon: '🌾',
      growthDurationDays: 110,
      season: 'Rabi (November-April)',
      seasonBn: 'রবি (নভেম্বর-এপ্রিল)',
      careTopics: [
        'Irrigation scheduling',
        'Disease management',
        'Weed control',
        'Timely harvest',
      ],
      careTopicsBn: [
        'সেচ সময়সূচী',
        'রোগ ব্যবস্থাপনা',
        'আগাছা নিয়ন্ত্রণ',
        'সময়মতো কাটা',
      ],
      stages: {
        'germination': StageInfo(
          name: 'Germination',
          nameBn: 'অঙ্কুরোদগম',
          startDay: 0,
          endDay: 10,
          care: 'Ensure proper soil moisture. Light irrigation if dry.',
          careBn:
              'মাটিতে পর্যাপ্ত আর্দ্রতা নিশ্চিত করুন। শুকনো হলে হালকা সেচ দিন।',
          warnings: ['Check seed quality', 'Avoid waterlogging'],
          warningsBn: ['বীজের গুণমান পরীক্ষা করুন', 'জলাবদ্ধতা এড়িয়ে চলুন'],
        ),
        'vegetative': StageInfo(
          name: 'Tillering',
          nameBn: 'কুশি পর্যায়',
          startDay: 11,
          endDay: 45,
          care: 'First irrigation at 21 DAS. Apply nitrogen fertilizer.',
          careBn: '২১ দিনে প্রথম সেচ দিন। নাইট্রোজেন সার প্রয়োগ করুন।',
          warnings: ['Monitor for aphids', 'Control broad-leaf weeds'],
          warningsBn: [
            'জাব পোকা পর্যবেক্ষণ করুন',
            'চওড়া পাতার আগাছা নিয়ন্ত্রণ করুন',
          ],
        ),
        'flowering': StageInfo(
          name: 'Flowering',
          nameBn: 'ফুল আসার সময়',
          startDay: 46,
          endDay: 70,
          care: 'Critical irrigation at flowering. Watch for rust diseases.',
          careBn: 'ফুল আসার সময় গুরুত্বপূর্ণ সেচ দিন। মরিচা রোগ দেখুন।',
          warnings: ['Avoid water stress', 'Scout for yellow rust'],
          warningsBn: ['পানির অভাব এড়িয়ে চলুন', 'হলুদ মরিচা খুঁজুন'],
        ),
        'fruiting': StageInfo(
          name: 'Grain Development',
          nameBn: 'দানা গঠন',
          startDay: 71,
          endDay: 95,
          care: 'Last irrigation at dough stage. Monitor grain filling.',
          careBn: 'ডাফ পর্যায়ে শেষ সেচ দিন। দানা পুষ্ট হওয়া পর্যবেক্ষণ করুন।',
          warnings: ['Check for ear head diseases', 'Protect from birds'],
          warningsBn: ['শীষের রোগ পরীক্ষা করুন', 'পাখি থেকে রক্ষা করুন'],
        ),
        'maturation': StageInfo(
          name: 'Maturation',
          nameBn: 'পরিপক্বতা',
          startDay: 96,
          endDay: 110,
          care: 'Harvest when golden yellow. Avoid shattering.',
          careBn: 'সোনালী হলুদ হলে কাটুন। ঝরে পড়া এড়িয়ে চলুন।',
          warnings: ['Harvest at 12-14% moisture', 'Timely harvest essential'],
          warningsBn: ['১২-১৪% আর্দ্রতায় কাটুন', 'সময়মতো কাটা জরুরি'],
        ),
      },
      commonDiseases: [
        'Yellow rust',
        'Leaf blight',
        'Karnal bunt',
        'Loose smut',
      ],
      commonPests: ['Aphids', 'Termites', 'Army worm'],
      waterRequirement: 30,
      optimalTemp: '15-25°C',
      description:
          'Wheat is the second most important cereal crop in Bangladesh.',
      descriptionBn: 'গম বাংলাদেশের দ্বিতীয় গুরুত্বপূর্ণ দানাদার ফসল।',
    ),
    'potato': CropInfo(
      name: 'Potato',
      nameBn: 'আলু',
      icon: '🥔',
      growthDurationDays: 90,
      season: 'Rabi (November-February)',
      seasonBn: 'রবি (নভেম্বর-ফেব্রুয়ারি)',
      careTopics: [
        'Earthing up',
        'Late blight management',
        'Irrigation',
        'Haulm cutting',
      ],
      careTopicsBn: [
        'মাটি চাপা দেওয়া',
        'মড়ক রোগ ব্যবস্থাপনা',
        'সেচ',
        'গাছ কাটা',
      ],
      stages: {
        'germination': StageInfo(
          name: 'Sprouting',
          nameBn: 'অঙ্কুরোদগম',
          startDay: 0,
          endDay: 15,
          care: 'Ensure proper soil moisture. Temperature 15-20°C optimal.',
          careBn:
              'মাটিতে পর্যাপ্ত আর্দ্রতা নিশ্চিত করুন। ১৫-২০°C তাপমাত্রা আদর্শ।',
          warnings: ['Check for rotting tubers', 'Protect from frost'],
          warningsBn: ['পচা বীজ আলু পরীক্ষা করুন', 'শীত থেকে রক্ষা করুন'],
        ),
        'vegetative': StageInfo(
          name: 'Vegetative Growth',
          nameBn: 'বৃদ্ধি পর্যায়',
          startDay: 16,
          endDay: 40,
          care: 'First earthing up at 25 DAS. Apply nitrogen fertilizer.',
          careBn: '২৫ দিনে প্রথম মাটি চাপা দিন। নাইট্রোজেন সার দিন।',
          warnings: ['Monitor for early blight', 'Control aphids'],
          warningsBn: [
            'আগাম পাতা পোড়া পর্যবেক্ষণ করুন',
            'জাব পোকা নিয়ন্ত্রণ করুন',
          ],
        ),
        'flowering': StageInfo(
          name: 'Tuber Initiation',
          nameBn: 'আলু ধরা শুরু',
          startDay: 41,
          endDay: 55,
          care: 'Second earthing up. Consistent irrigation critical.',
          careBn: 'দ্বিতীয় মাটি চাপা দিন। নিয়মিত সেচ গুরুত্বপূর্ণ।',
          warnings: ['Watch for late blight', 'Avoid water stress'],
          warningsBn: ['মড়ক রোগ দেখুন', 'পানির অভাব এড়িয়ে চলুন'],
        ),
        'fruiting': StageInfo(
          name: 'Tuber Bulking',
          nameBn: 'আলু বড় হওয়া',
          startDay: 56,
          endDay: 75,
          care: 'Maintain soil moisture. Apply potassium for quality.',
          careBn: 'মাটির আর্দ্রতা বজায় রাখুন। গুণমানের জন্য পটাশ দিন।',
          warnings: ['Critical period for late blight', 'Check tuber size'],
          warningsBn: [
            'মড়ক রোগের জন্য গুরুত্বপূর্ণ সময়',
            'আলুর আকার পরীক্ষা করুন',
          ],
        ),
        'maturation': StageInfo(
          name: 'Maturation',
          nameBn: 'পরিপক্বতা',
          startDay: 76,
          endDay: 90,
          care: 'Cut haulms 10 days before harvest. Let skin harden.',
          careBn: 'কাটার ১০ দিন আগে গাছ কাটুন। চামড়া শক্ত হতে দিন।',
          warnings: ['Avoid harvesting wet soil', 'Handle tubers carefully'],
          warningsBn: ['ভেজা মাটিতে কাটা এড়িয়ে চলুন', 'আলু সাবধানে তুলুন'],
        ),
      },
      commonDiseases: [
        'Late blight',
        'Early blight',
        'Black scurf',
        'Bacterial wilt',
      ],
      commonPests: ['Aphids', 'Cutworm', 'Potato tuber moth'],
      waterRequirement: 35,
      optimalTemp: '15-22°C',
      description:
          'Potato is a major vegetable crop and important source of carbohydrates.',
      descriptionBn: 'আলু একটি প্রধান সবজি ফসল এবং শর্করার গুরুত্বপূর্ণ উৎস।',
    ),
    'maize': CropInfo(
      name: 'Maize',
      nameBn: 'ভুট্টা',
      icon: '🌽',
      growthDurationDays: 100,
      season: 'Rabi/Kharif',
      seasonBn: 'রবি/খরিফ',
      careTopics: [
        'Spacing management',
        'Tasseling care',
        'Fall armyworm control',
        'Harvest timing',
      ],
      careTopicsBn: [
        'দূরত্ব ব্যবস্থাপনা',
        'ফুল আসার যত্ন',
        'ফল আর্মিওয়ার্ম নিয়ন্ত্রণ',
        'কাটার সময়',
      ],
      stages: {
        'germination': StageInfo(
          name: 'Emergence',
          nameBn: 'অঙ্কুরোদগম',
          startDay: 0,
          endDay: 10,
          care: 'Ensure adequate moisture. Thin to proper spacing.',
          careBn: 'পর্যাপ্ত আর্দ্রতা নিশ্চিত করুন। সঠিক দূরত্বে পাতলা করুন।',
          warnings: ['Watch for cutworms', 'Check germination rate'],
          warningsBn: ['কাটা পোকা দেখুন', 'অঙ্কুরোদগম হার পরীক্ষা করুন'],
        ),
        'vegetative': StageInfo(
          name: 'Vegetative (V6-V12)',
          nameBn: 'বৃদ্ধি পর্যায়',
          startDay: 11,
          endDay: 45,
          care: 'Apply nitrogen in splits. First irrigation at knee-high.',
          careBn: 'নাইট্রোজেন ভাগে ভাগে দিন। হাঁটু উচ্চতায় প্রথম সেচ।',
          warnings: ['Monitor for fall armyworm', 'Control weeds early'],
          warningsBn: [
            'ফল আর্মিওয়ার্ম পর্যবেক্ষণ করুন',
            'আগে আগাছা নিয়ন্ত্রণ করুন',
          ],
        ),
        'flowering': StageInfo(
          name: 'Tasseling/Silking',
          nameBn: 'ফুল আসা',
          startDay: 46,
          endDay: 65,
          care: 'Critical irrigation stage. Ensure pollination.',
          careBn: 'গুরুত্বপূর্ণ সেচের পর্যায়। পরাগায়ন নিশ্চিত করুন।',
          warnings: ['Water stress causes barren ears', 'Watch for ear rot'],
          warningsBn: ['পানির অভাবে ফাঁকা মোচা হয়', 'মোচা পচা দেখুন'],
        ),
        'fruiting': StageInfo(
          name: 'Grain Fill',
          nameBn: 'দানা পুষ্ট হওয়া',
          startDay: 66,
          endDay: 85,
          care: 'Maintain moisture. Watch for ear diseases.',
          careBn: 'আর্দ্রতা বজায় রাখুন। মোচার রোগ দেখুন।',
          warnings: ['Check for aflatoxin in stress', 'Protect from birds'],
          warningsBn: ['চাপে আফলাটক্সিন পরীক্ষা করুন', 'পাখি থেকে রক্ষা করুন'],
        ),
        'maturation': StageInfo(
          name: 'Maturity',
          nameBn: 'পরিপক্বতা',
          startDay: 86,
          endDay: 100,
          care: 'Harvest when black layer forms. Dry properly.',
          careBn: 'কালো স্তর তৈরি হলে কাটুন। সঠিকভাবে শুকান।',
          warnings: ['Harvest at 20-25% moisture', 'Avoid field drying losses'],
          warningsBn: [
            '২০-২৫% আর্দ্রতায় কাটুন',
            'মাঠে শুকানোর ক্ষতি এড়িয়ে চলুন',
          ],
        ),
      },
      commonDiseases: ['Leaf blight', 'Downy mildew', 'Ear rot', 'Stalk rot'],
      commonPests: ['Fall armyworm', 'Stem borer', 'Aphids', 'Earworm'],
      waterRequirement: 40,
      optimalTemp: '20-30°C',
      description:
          'Maize is a versatile crop used for food, feed, and industrial purposes.',
      descriptionBn:
          'ভুট্টা খাদ্য, পশুখাদ্য এবং শিল্পের জন্য ব্যবহৃত বহুমুখী ফসল।',
    ),
    'jute': CropInfo(
      name: 'Jute',
      nameBn: 'পাট',
      icon: '🌿',
      growthDurationDays: 120,
      season: 'Kharif (March-August)',
      seasonBn: 'খরিফ (মার্চ-আগস্ট)',
      careTopics: [
        'Proper spacing',
        'Retting process',
        'Weed management',
        'Harvest timing',
      ],
      careTopicsBn: [
        'সঠিক দূরত্ব',
        'জাগ দেওয়া',
        'আগাছা ব্যবস্থাপনা',
        'কাটার সময়',
      ],
      stages: {
        'germination': StageInfo(
          name: 'Germination',
          nameBn: 'অঙ্কুরোদগম',
          startDay: 0,
          endDay: 10,
          care: 'Maintain soil moisture. Thin seedlings after emergence.',
          careBn: 'মাটির আর্দ্রতা বজায় রাখুন। অঙ্কুরোদগমের পর পাতলা করুন।',
          warnings: ['Check for damping off', 'Ensure proper drainage'],
          warningsBn: [
            'ড্যাম্পিং অফ পরীক্ষা করুন',
            'সঠিক নিষ্কাশন নিশ্চিত করুন',
          ],
        ),
        'vegetative': StageInfo(
          name: 'Vegetative Growth',
          nameBn: 'বৃদ্ধি পর্যায়',
          startDay: 11,
          endDay: 60,
          care: 'Weed 2-3 times. Apply urea at 30 DAS.',
          careBn: '২-৩ বার আগাছা পরিষ্কার করুন। ৩০ দিনে ইউরিয়া দিন।',
          warnings: ['Monitor for hairy caterpillar', 'Control weeds timely'],
          warningsBn: [
            'লোমশ শুঁয়াপোকা পর্যবেক্ষণ করুন',
            'সময়মতো আগাছা নিয়ন্ত্রণ করুন',
          ],
        ),
        'flowering': StageInfo(
          name: 'Fibre Development',
          nameBn: 'আঁশ তৈরি',
          startDay: 61,
          endDay: 90,
          care: 'Rapid growth phase. Ensure adequate water.',
          careBn: 'দ্রুত বৃদ্ধির পর্যায়। পর্যাপ্ত পানি নিশ্চিত করুন।',
          warnings: ['Watch plant height', 'Monitor fibre quality'],
          warningsBn: ['গাছের উচ্চতা দেখুন', 'আঁশের গুণমান পর্যবেক্ষণ করুন'],
        ),
        'fruiting': StageInfo(
          name: 'Flowering',
          nameBn: 'ফুল আসা',
          startDay: 91,
          endDay: 105,
          care: 'Harvest before excessive flowering for quality fibre.',
          careBn: 'গুণমান আঁশের জন্য অতিরিক্ত ফুল আসার আগে কাটুন।',
          warnings: ['Flowering reduces fibre quality', 'Plan harvest timing'],
          warningsBn: ['ফুল আঁশের গুণমান কমায়', 'কাটার সময় পরিকল্পনা করুন'],
        ),
        'maturation': StageInfo(
          name: 'Harvest/Retting',
          nameBn: 'কাটা/জাগ দেওয়া',
          startDay: 106,
          endDay: 120,
          care: 'Cut at base. Ret in clean, slow-flowing water.',
          careBn: 'গোড়া থেকে কাটুন। পরিষ্কার, ধীর প্রবাহিত পানিতে জাগ দিন।',
          warnings: [
            'Over-retting damages fibre',
            'Under-retting difficult to extract',
          ],
          warningsBn: ['অতিরিক্ত জাগে আঁশ নষ্ট হয়', 'কম জাগে ছাড়ানো কঠিন'],
        ),
      },
      commonDiseases: ['Stem rot', 'Anthracnose', 'Soft rot'],
      commonPests: ['Hairy caterpillar', 'Semilooper', 'Jute aphid', 'Mite'],
      waterRequirement: 45,
      optimalTemp: '25-35°C',
      description:
          'Jute is the golden fibre of Bangladesh, a major export crop.',
      descriptionBn: 'পাট বাংলাদেশের সোনালি আঁশ, একটি প্রধান রপ্তানি পণ্য।',
    ),
    'sugarcane': CropInfo(
      name: 'Sugarcane',
      nameBn: 'আখ',
      icon: '🎋',
      growthDurationDays: 300,
      season: 'Year-round (plant Oct-Feb)',
      seasonBn: 'সারা বছর (রোপণ অক্টো-ফেব্রু)',
      careTopics: [
        'Ratoon management',
        'Earthing up',
        'Trash mulching',
        'Internode development',
      ],
      careTopicsBn: [
        'রেটুন ব্যবস্থাপনা',
        'মাটি চাপা দেওয়া',
        'ছেঁড়া পাতা বিছানো',
        'গিঁট তৈরি',
      ],
      stages: {
        'germination': StageInfo(
          name: 'Germination',
          nameBn: 'অঙ্কুরোদগম',
          startDay: 0,
          endDay: 35,
          care: 'Light irrigation. Maintain soil moisture. Gap filling.',
          careBn:
              'হালকা সেচ দিন। মাটির আর্দ্রতা বজায় রাখুন। শূন্যস্থান পূরণ করুন।',
          warnings: ['Check bud sprouting', 'Protect from termites'],
          warningsBn: ['কুঁড়ি গজানো পরীক্ষা করুন', 'উইপোকা থেকে রক্ষা করুন'],
        ),
        'vegetative': StageInfo(
          name: 'Tillering',
          nameBn: 'কুশি পর্যায়',
          startDay: 36,
          endDay: 120,
          care: 'First earthing up at 45 DAS. Apply nitrogen.',
          careBn: '৪৫ দিনে প্রথম মাটি চাপা দিন। নাইট্রোজেন দিন।',
          warnings: ['Remove water shoots', 'Control weeds'],
          warningsBn: ['পানির চারা সরান', 'আগাছা নিয়ন্ত্রণ করুন'],
        ),
        'flowering': StageInfo(
          name: 'Grand Growth',
          nameBn: 'দ্রুত বৃদ্ধি',
          startDay: 121,
          endDay: 240,
          care: 'Heavy irrigation. Second earthing up. Trash mulching.',
          careBn: 'প্রচুর সেচ দিন। দ্বিতীয় মাটি চাপা দিন। ছেঁড়া পাতা বিছান।',
          warnings: ['Monitor for borers', 'Tie canes if lodging'],
          warningsBn: ['মাজরা পোকা পর্যবেক্ষণ করুন', 'হেলে পড়লে বাঁধুন'],
        ),
        'fruiting': StageInfo(
          name: 'Sucrose Accumulation',
          nameBn: 'চিনি জমা হওয়া',
          startDay: 241,
          endDay: 280,
          care: 'Reduce irrigation. Avoid nitrogen. Trash removal.',
          careBn: 'সেচ কমান। নাইট্রোজেন এড়িয়ে চলুন। ছেঁড়া পাতা সরান।',
          warnings: ['Water stress improves sugar', 'Watch for red rot'],
          warningsBn: ['পানির অভাবে চিনি বাড়ে', 'লাল পচা দেখুন'],
        ),
        'maturation': StageInfo(
          name: 'Maturity',
          nameBn: 'পরিপক্বতা',
          startDay: 281,
          endDay: 300,
          care: 'Test brix level (>18%). Harvest at ground level.',
          careBn: 'ব্রিক্স পরীক্ষা করুন (>১৮%)। মাটির সমান করে কাটুন।',
          warnings: [
            'Avoid flowering for sugar',
            'Rapid crushing after harvest',
          ],
          warningsBn: [
            'চিনির জন্য ফুল আসা এড়িয়ে চলুন',
            'কাটার পর দ্রুত মাড়াই করুন',
          ],
        ),
      },
      commonDiseases: ['Red rot', 'Smut', 'Wilt', 'Grassy shoot'],
      commonPests: ['Top borer', 'Stem borer', 'Termites', 'Pyrilla'],
      waterRequirement: 60,
      optimalTemp: '25-35°C',
      description:
          'Sugarcane is a major cash crop for sugar and gur production.',
      descriptionBn: 'আখ চিনি ও গুড় উৎপাদনের জন্য একটি প্রধান অর্থকরী ফসল।',
    ),
    'tomato': CropInfo(
      name: 'Tomato',
      nameBn: 'টমেটো',
      icon: '🍅',
      growthDurationDays: 90,
      season: 'Rabi (October-March)',
      seasonBn: 'রবি (অক্টোবর-মার্চ)',
      careTopics: ['Staking', 'Pruning', 'Disease management', 'Fruit set'],
      careTopicsBn: ['খুঁটি দেওয়া', 'ছাঁটাই', 'রোগ ব্যবস্থাপনা', 'ফল ধরা'],
      stages: {
        'germination': StageInfo(
          name: 'Nursery/Transplant',
          nameBn: 'নার্সারি/রোপণ',
          startDay: 0,
          endDay: 15,
          care: 'Harden seedlings before transplant. Water immediately after.',
          careBn: 'রোপণের আগে চারা শক্ত করুন। রোপণের পর সাথে সাথে পানি দিন।',
          warnings: ['Protect from damping off', 'Avoid transplant shock'],
          warningsBn: ['ড্যাম্পিং অফ থেকে রক্ষা করুন', 'রোপণ শক এড়িয়ে চলুন'],
        ),
        'vegetative': StageInfo(
          name: 'Vegetative Growth',
          nameBn: 'বৃদ্ধি পর্যায়',
          startDay: 16,
          endDay: 35,
          care: 'Stake plants. Remove suckers. Apply fertilizer.',
          careBn: 'খুঁটি দিন। পার্শ্ব শাখা সরান। সার দিন।',
          warnings: ['Train to single stem', 'Monitor for early blight'],
          warningsBn: ['একটি কাণ্ডে রাখুন', 'আগাম ব্লাইট পর্যবেক্ষণ করুন'],
        ),
        'flowering': StageInfo(
          name: 'Flowering',
          nameBn: 'ফুল আসা',
          startDay: 36,
          endDay: 50,
          care: 'Ensure pollination. Avoid water stress. Light tap flowers.',
          careBn:
              'পরাগায়ন নিশ্চিত করুন। পানির অভাব এড়িয়ে চলুন। ফুল হালকা ঝাঁকান।',
          warnings: [
            'Temperature >35°C causes flower drop',
            'Watch for leaf curl virus',
          ],
          warningsBn: [
            '৩৫°C এর উপরে ফুল ঝরে যায়',
            'পাতা কোঁকড়ানো ভাইরাস দেখুন',
          ],
        ),
        'fruiting': StageInfo(
          name: 'Fruit Development',
          nameBn: 'ফল ধরা',
          startDay: 51,
          endDay: 75,
          care: 'Regular irrigation. Support heavy clusters. Apply potash.',
          careBn: 'নিয়মিত সেচ দিন। ভারী গুচ্ছ ঠেকা দিন। পটাশ দিন।',
          warnings: ['Watch for fruit borer', 'Prevent blossom end rot'],
          warningsBn: ['ফলের মাজরা দেখুন', 'ফুলের দিকের পচা রোধ করুন'],
        ),
        'maturation': StageInfo(
          name: 'Ripening',
          nameBn: 'পরিপক্বতা',
          startDay: 76,
          endDay: 90,
          care:
              'Harvest at breaker stage for distant market. Handle carefully.',
          careBn: 'দূরের বাজারের জন্য গোলাপি হলে তুলুন। সাবধানে তুলুন।',
          warnings: ['Avoid over-ripening', 'Multiple harvests needed'],
          warningsBn: ['অতিরিক্ত পাকা এড়িয়ে চলুন', 'একাধিকবার তুলতে হবে'],
        ),
      },
      commonDiseases: [
        'Early blight',
        'Late blight',
        'Bacterial wilt',
        'Leaf curl virus',
      ],
      commonPests: ['Fruit borer', 'Whitefly', 'Aphids', 'Mites'],
      waterRequirement: 30,
      optimalTemp: '18-27°C',
      description:
          'Tomato is a popular vegetable grown widely in winter season.',
      descriptionBn: 'টমেটো শীতকালে ব্যাপকভাবে চাষ করা একটি জনপ্রিয় সবজি।',
    ),
    'onion': CropInfo(
      name: 'Onion',
      nameBn: 'পেঁয়াজ',
      icon: '🧅',
      growthDurationDays: 110,
      season: 'Rabi (November-April)',
      seasonBn: 'রবি (নভেম্বর-এপ্রিল)',
      careTopics: [
        'Bulb development',
        'Curing process',
        'Storage management',
        'Bolting prevention',
      ],
      careTopicsBn: [
        'কন্দ তৈরি',
        'শুকানো প্রক্রিয়া',
        'সংরক্ষণ ব্যবস্থাপনা',
        'ফুল আসা রোধ',
      ],
      stages: {
        'germination': StageInfo(
          name: 'Establishment',
          nameBn: 'স্থাপন',
          startDay: 0,
          endDay: 20,
          care: 'Light frequent irrigation. Ensure good drainage.',
          careBn: 'ঘন ঘন হালকা সেচ দিন। ভালো নিষ্কাশন নিশ্চিত করুন।',
          warnings: ['Watch for damping off', 'Avoid waterlogging'],
          warningsBn: ['ড্যাম্পিং অফ দেখুন', 'জলাবদ্ধতা এড়িয়ে চলুন'],
        ),
        'vegetative': StageInfo(
          name: 'Leaf Growth',
          nameBn: 'পাতা বৃদ্ধি',
          startDay: 21,
          endDay: 50,
          care: 'Apply nitrogen. Maintain consistent moisture.',
          careBn: 'নাইট্রোজেন দিন। ধারাবাহিক আর্দ্রতা বজায় রাখুন।',
          warnings: ['Monitor for thrips', 'Control purple blotch'],
          warningsBn: ['থ্রিপস পর্যবেক্ষণ করুন', 'বেগুনি দাগ নিয়ন্ত্রণ করুন'],
        ),
        'flowering': StageInfo(
          name: 'Bulb Initiation',
          nameBn: 'কন্দ শুরু',
          startDay: 51,
          endDay: 70,
          care: 'Stop nitrogen. Apply potash for bulb quality.',
          careBn: 'নাইট্রোজেন বন্ধ করুন। কন্দের গুণমানের জন্য পটাশ দিন।',
          warnings: ['Long days trigger bulbing', 'Avoid bolting'],
          warningsBn: ['দীর্ঘ দিন কন্দ তৈরি শুরু করে', 'ফুল আসা এড়িয়ে চলুন'],
        ),
        'fruiting': StageInfo(
          name: 'Bulb Enlargement',
          nameBn: 'কন্দ বড় হওয়া',
          startDay: 71,
          endDay: 95,
          care: 'Reduce irrigation. Earthing up not recommended.',
          careBn: 'সেচ কমান। মাটি চাপা দেওয়া সুপারিশ নয়।',
          warnings: ['Irregular water causes splitting', 'Check for soft rot'],
          warningsBn: ['অনিয়মিত পানিতে ফাটল ধরে', 'নরম পচা পরীক্ষা করুন'],
        ),
        'maturation': StageInfo(
          name: 'Maturity/Curing',
          nameBn: 'পরিপক্বতা/শুকানো',
          startDay: 96,
          endDay: 110,
          care: 'Stop irrigation when tops fall. Cure for 7-10 days.',
          careBn: 'গাছ শুকিয়ে গেলে সেচ বন্ধ করুন। ৭-১০ দিন শুকান।',
          warnings: [
            'Harvest when 50% tops down',
            'Proper curing essential for storage',
          ],
          warningsBn: [
            '৫০% গাছ শুকালে তুলুন',
            'সংরক্ষণের জন্য সঠিক শুকানো জরুরি',
          ],
        ),
      },
      commonDiseases: [
        'Purple blotch',
        'Downy mildew',
        'Soft rot',
        'Stemphylium blight',
      ],
      commonPests: ['Thrips', 'Onion maggot', 'Mites'],
      waterRequirement: 25,
      optimalTemp: '15-25°C',
      description: 'Onion is an essential spice crop with high market demand.',
      descriptionBn: 'পেঁয়াজ উচ্চ বাজার চাহিদা সহ একটি অপরিহার্য মসলা ফসল।',
    ),
    'chili': CropInfo(
      name: 'Chili',
      nameBn: 'মরিচ',
      icon: '🌶️',
      growthDurationDays: 120,
      season: 'Year-round (main: Rabi)',
      seasonBn: 'সারা বছর (প্রধান: রবি)',
      careTopics: [
        'Fruit set',
        'Virus management',
        'Picking schedule',
        'Quality maintenance',
      ],
      careTopicsBn: [
        'ফল ধরা',
        'ভাইরাস ব্যবস্থাপনা',
        'তোলার সময়সূচী',
        'গুণমান রক্ষা',
      ],
      stages: {
        'germination': StageInfo(
          name: 'Transplanting',
          nameBn: 'রোপণ',
          startDay: 0,
          endDay: 15,
          care: 'Water immediately after transplant. Provide shade.',
          careBn: 'রোপণের পর সাথে সাথে পানি দিন। ছায়া দিন।',
          warnings: ['Protect from transplant shock', 'Watch for damping off'],
          warningsBn: ['রোপণ শক থেকে রক্ষা করুন', 'ড্যাম্পিং অফ দেখুন'],
        ),
        'vegetative': StageInfo(
          name: 'Vegetative',
          nameBn: 'বৃদ্ধি পর্যায়',
          startDay: 16,
          endDay: 40,
          care: 'Apply nitrogen. Pinch first flowers for stronger plants.',
          careBn: 'নাইট্রোজেন দিন। শক্তিশালী গাছের জন্য প্রথম ফুল ভাঙুন।',
          warnings: [
            'Monitor for aphids (virus vector)',
            'Control leaf curl early',
          ],
          warningsBn: [
            'জাব পোকা (ভাইরাস বাহক) পর্যবেক্ষণ করুন',
            'আগে পাতা কোঁকড়ানো নিয়ন্ত্রণ করুন',
          ],
        ),
        'flowering': StageInfo(
          name: 'Flowering',
          nameBn: 'ফুল আসা',
          startDay: 41,
          endDay: 60,
          care: 'Ensure pollination. Avoid water stress.',
          careBn: 'পরাগায়ন নিশ্চিত করুন। পানির অভাব এড়িয়ে চলুন।',
          warnings: ['High temp causes flower drop', 'Watch for thrips'],
          warningsBn: ['উচ্চ তাপমাত্রায় ফুল ঝরে', 'থ্রিপস দেখুন'],
        ),
        'fruiting': StageInfo(
          name: 'Fruiting',
          nameBn: 'ফল ধরা',
          startDay: 61,
          endDay: 100,
          care: 'Regular picking encourages more fruits. Apply potash.',
          careBn: 'নিয়মিত তোলায় বেশি ফল হয়। পটাশ দিন।',
          warnings: ['Watch for fruit rot', 'Control fruit borer'],
          warningsBn: ['ফল পচা দেখুন', 'ফলের মাজরা নিয়ন্ত্রণ করুন'],
        ),
        'maturation': StageInfo(
          name: 'Harvest Period',
          nameBn: 'তোলার সময়',
          startDay: 101,
          endDay: 120,
          care: 'Harvest at right color stage. Dry properly for storage.',
          careBn: 'সঠিক রঙে তুলুন। সংরক্ষণের জন্য সঠিকভাবে শুকান।',
          warnings: [
            'Multiple harvests over season',
            'Handle carefully to avoid bruising',
          ],
          warningsBn: ['মৌসুমে একাধিকবার তুলুন', 'আঘাত এড়াতে সাবধানে তুলুন'],
        ),
      },
      commonDiseases: [
        'Leaf curl virus',
        'Anthracnose',
        'Bacterial wilt',
        'Die-back',
      ],
      commonPests: ['Thrips', 'Aphids', 'Mites', 'Fruit borer'],
      waterRequirement: 25,
      optimalTemp: '20-30°C',
      description: 'Chili is a major spice crop with both green and dry uses.',
      descriptionBn:
          'মরিচ কাঁচা এবং শুকনো উভয় ব্যবহারের একটি প্রধান মসলা ফসল।',
    ),
    'lentil': CropInfo(
      name: 'Lentil',
      nameBn: 'মসুর',
      icon: '🫘',
      growthDurationDays: 100,
      season: 'Rabi (October-March)',
      seasonBn: 'রবি (অক্টোবর-মার্চ)',
      careTopics: [
        'Seed inoculation',
        'Wilt management',
        'Harvest timing',
        'Pod shattering',
      ],
      careTopicsBn: [
        'বীজ শোধন',
        'ঢলে পড়া ব্যবস্থাপনা',
        'কাটার সময়',
        'শুঁটি ঝরা',
      ],
      stages: {
        'germination': StageInfo(
          name: 'Emergence',
          nameBn: 'অঙ্কুরোদগম',
          startDay: 0,
          endDay: 10,
          care: 'Pre-sowing irrigation. Seed treatment with Rhizobium.',
          careBn: 'বপনের আগে সেচ দিন। রাইজোবিয়াম দিয়ে বীজ শোধন করুন।',
          warnings: ['Check germination rate', 'Avoid waterlogging'],
          warningsBn: ['অঙ্কুরোদগম হার পরীক্ষা করুন', 'জলাবদ্ধতা এড়িয়ে চলুন'],
        ),
        'vegetative': StageInfo(
          name: 'Vegetative',
          nameBn: 'বৃদ্ধি পর্যায়',
          startDay: 11,
          endDay: 40,
          care: 'One irrigation at 40-45 DAS if dry. Control weeds.',
          careBn: 'শুষ্ক হলে ৪০-৪৫ দিনে একটি সেচ দিন। আগাছা নিয়ন্ত্রণ করুন।',
          warnings: ['Monitor for wilt', 'Watch for aphids'],
          warningsBn: ['ঢলে পড়া পর্যবেক্ষণ করুন', 'জাব পোকা দেখুন'],
        ),
        'flowering': StageInfo(
          name: 'Flowering',
          nameBn: 'ফুল আসা',
          startDay: 41,
          endDay: 60,
          care: 'Critical stage. Light irrigation if very dry.',
          careBn: 'গুরুত্বপূর্ণ পর্যায়। খুব শুষ্ক হলে হালকা সেচ দিন।',
          warnings: ['Avoid water stress', 'Watch for rust'],
          warningsBn: ['পানির অভাব এড়িয়ে চলুন', 'মরিচা দেখুন'],
        ),
        'fruiting': StageInfo(
          name: 'Pod Formation',
          nameBn: 'শুঁটি তৈরি',
          startDay: 61,
          endDay: 85,
          care: 'No irrigation needed. Monitor pod filling.',
          careBn: 'সেচের প্রয়োজন নেই। শুঁটি পুষ্ট হওয়া পর্যবেক্ষণ করুন।',
          warnings: ['Check for pod borer', 'Protect from birds'],
          warningsBn: ['শুঁটির মাজরা পরীক্ষা করুন', 'পাখি থেকে রক্ষা করুন'],
        ),
        'maturation': StageInfo(
          name: 'Maturity',
          nameBn: 'পরিপক্বতা',
          startDay: 86,
          endDay: 100,
          care:
              'Harvest when 80% pods turn brown. Morning harvest reduces shattering.',
          careBn: '৮০% শুঁটি বাদামী হলে কাটুন। সকালে কাটলে ঝরা কম হয়।',
          warnings: ['Avoid over-maturity', 'Quick threshing needed'],
          warningsBn: ['অতিরিক্ত পাকা এড়িয়ে চলুন', 'দ্রুত মাড়াই করুন'],
        ),
      },
      commonDiseases: ['Rust', 'Wilt', 'Root rot', 'Stemphylium blight'],
      commonPests: ['Pod borer', 'Aphids', 'Cutworm'],
      waterRequirement: 20,
      optimalTemp: '15-25°C',
      description: 'Lentil is an important pulse crop rich in protein.',
      descriptionBn: 'মসুর প্রোটিন সমৃদ্ধ একটি গুরুত্বপূর্ণ ডাল ফসল।',
    ),
  };
}
