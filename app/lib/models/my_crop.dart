import 'dart:convert';

class MyCrop {
  final String id;
  final String cropName;
  final String cropNameBn;
  final double landArea;
  final String landUnit; // hectare, bigha, acre, decimal
  final DateTime plantedDate;
  final int growthDurationDays;
  final String? notes;
  final DateTime createdAt;

  MyCrop({
    required this.id,
    required this.cropName,
    required this.cropNameBn,
    required this.landArea,
    required this.landUnit,
    required this.plantedDate,
    required this.growthDurationDays,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate expected harvest date
  DateTime get expectedHarvestDate =>
      plantedDate.add(Duration(days: growthDurationDays));

  /// Days remaining until harvest
  int get daysUntilHarvest {
    final remaining = expectedHarvestDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  /// Days since planting
  int get daysSincePlanting => DateTime.now().difference(plantedDate).inDays;

  /// Progress percentage (0.0 to 1.0)
  double get growthProgress {
    if (growthDurationDays <= 0) return 1.0;
    final progress = daysSincePlanting / growthDurationDays;
    return progress > 1.0 ? 1.0 : progress;
  }

  /// Current growth stage
  String get growthStage {
    final progress = growthProgress;
    if (progress < 0.15) return 'germination';
    if (progress < 0.35) return 'vegetative';
    if (progress < 0.55) return 'flowering';
    if (progress < 0.80) return 'fruiting';
    if (progress < 1.0) return 'maturation';
    return 'harvest';
  }

  /// Growth stage display name
  String getGrowthStageName(bool isBangla) {
    switch (growthStage) {
      case 'germination':
        return isBangla ? 'অঙ্কুরোদগম' : 'Germination';
      case 'vegetative':
        return isBangla ? 'বৃদ্ধি পর্যায়' : 'Vegetative';
      case 'flowering':
        return isBangla ? 'ফুল আসার সময়' : 'Flowering';
      case 'fruiting':
        return isBangla ? 'ফল ধরার সময়' : 'Fruiting';
      case 'maturation':
        return isBangla ? 'পরিপক্বতা' : 'Maturation';
      case 'harvest':
        return isBangla ? 'ফসল কাটার সময়' : 'Harvest Ready';
      default:
        return isBangla ? 'অজানা' : 'Unknown';
    }
  }

  /// Is the crop ready for harvest?
  bool get isReadyForHarvest => daysUntilHarvest <= 0;

  /// Convert area to hectares for calculations
  double get areaInHectares {
    switch (landUnit) {
      case 'hectare':
        return landArea;
      case 'bigha':
        return landArea * 0.66;
      case 'acre':
        return landArea * 0.405;
      case 'decimal':
        return landArea * 0.004;
      default:
        return landArea;
    }
  }

  /// Create from JSON
  factory MyCrop.fromJson(Map<String, dynamic> json) {
    return MyCrop(
      id: json['id'] as String,
      cropName: json['cropName'] as String,
      cropNameBn: json['cropNameBn'] as String? ?? json['cropName'] as String,
      landArea: (json['landArea'] as num).toDouble(),
      landUnit: json['landUnit'] as String? ?? 'hectare',
      plantedDate: DateTime.parse(json['plantedDate'] as String),
      growthDurationDays: json['growthDurationDays'] as int,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropName': cropName,
      'cropNameBn': cropNameBn,
      'landArea': landArea,
      'landUnit': landUnit,
      'plantedDate': plantedDate.toIso8601String(),
      'growthDurationDays': growthDurationDays,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  MyCrop copyWith({
    String? id,
    String? cropName,
    String? cropNameBn,
    double? landArea,
    String? landUnit,
    DateTime? plantedDate,
    int? growthDurationDays,
    String? notes,
  }) {
    return MyCrop(
      id: id ?? this.id,
      cropName: cropName ?? this.cropName,
      cropNameBn: cropNameBn ?? this.cropNameBn,
      landArea: landArea ?? this.landArea,
      landUnit: landUnit ?? this.landUnit,
      plantedDate: plantedDate ?? this.plantedDate,
      growthDurationDays: growthDurationDays ?? this.growthDurationDays,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'MyCrop(id: $id, cropName: $cropName, landArea: $landArea $landUnit, '
        'plantedDate: $plantedDate, daysUntilHarvest: $daysUntilHarvest)';
  }
}

/// Serialize list of crops to JSON string
String serializeCrops(List<MyCrop> crops) {
  return jsonEncode(crops.map((c) => c.toJson()).toList());
}

/// Deserialize crops from JSON string
List<MyCrop> deserializeCrops(String jsonString) {
  if (jsonString.isEmpty) return [];
  try {
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((json) => MyCrop.fromJson(json)).toList();
  } catch (e) {
    return [];
  }
}
