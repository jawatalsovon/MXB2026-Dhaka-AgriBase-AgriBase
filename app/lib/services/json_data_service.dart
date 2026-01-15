import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service for loading crop data from JSON files (for web platform)
/// This provides a lightweight, web-friendly alternative to SQLite
class JsonDataService {
  static final JsonDataService _instance = JsonDataService._();

  JsonDataService._();

  static JsonDataService get instance => _instance;

  late Map<String, dynamic> _cropData;
  late Map<String, dynamic> _predictionData;
  late Map<String, dynamic> _attemptData;
  late Map<String, dynamic> _pieData;

  bool _initialized = false;

  /// Initialize by loading JSON files from assets
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load crop data
      final cropJsonString = await rootBundle.loadString(
        'assets/json/crop_data.json',
      );
      _cropData = jsonDecode(cropJsonString) as Map<String, dynamic>;

      // Load prediction data
      final predictionJsonString = await rootBundle.loadString(
        'assets/json/prediction_data.json',
      );
      _predictionData =
          jsonDecode(predictionJsonString) as Map<String, dynamic>;

      // Load attempt data (historical)
      final attemptJsonString = await rootBundle.loadString(
        'assets/json/attempt_data.json',
      );
      _attemptData = jsonDecode(attemptJsonString) as Map<String, dynamic>;

      // Load pie data
      final pieJsonString = await rootBundle.loadString(
        'assets/json/pie_data.json',
      );
      _pieData = jsonDecode(pieJsonString) as Map<String, dynamic>;

      _initialized = true;
      debugPrint('JsonDataService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing JsonDataService: $e');
      _initialized = false;
    }
  }

  bool get isInitialized => _initialized;

  /// Get all unique crops from data
  List<String> getAllCrops() {
    if (!_initialized) return [];
    try {
      final crops = <String>{};
      final cropList = _cropData['crops'] as List<dynamic>? ?? [];
      for (final item in cropList) {
        final cropName = item['crop_name'] as String?;
        if (cropName != null) crops.add(cropName);
      }
      return crops.toList()..sort();
    } catch (e) {
      debugPrint('Error getting crops: $e');
      return [];
    }
  }

  /// Get all years for a crop
  List<String> getYearsForCrop(String cropName) {
    if (!_initialized) return [];
    try {
      final years = <String>{};
      final cropList = _cropData['crops'] as List<dynamic>? ?? [];
      for (final item in cropList) {
        if (item['crop_name'] == cropName) {
          final year = item['year'] as String?;
          if (year != null) years.add(year);
        }
      }
      return years.toList()..sort((a, b) => b.compareTo(a)); // Descending
    } catch (e) {
      debugPrint('Error getting years: $e');
      return [];
    }
  }

  /// Get all years for a district
  List<String> getYearsForDistrict(String district) {
    if (!_initialized) return [];
    try {
      final years = <String>{};
      final cropList = _cropData['crops'] as List<dynamic>? ?? [];
      for (final item in cropList) {
        if (item['district'] == district) {
          final year = item['year'] as String?;
          if (year != null) years.add(year);
        }
      }
      return years.toList()..sort((a, b) => b.compareTo(a)); // Descending
    } catch (e) {
      debugPrint('Error getting years for district: $e');
      return [];
    }
  }

  /// Get all districts
  List<String> getAllDistricts() {
    if (!_initialized) return [];
    try {
      final districts = <String>{};
      final cropList = _cropData['crops'] as List<dynamic>? ?? [];
      for (final item in cropList) {
        final district = item['district'] as String?;
        if (district != null && district.isNotEmpty) {
          districts.add(district);
        }
      }
      return districts.toList()..sort();
    } catch (e) {
      debugPrint('Error getting districts: $e');
      return [];
    }
  }

  /// Get top yield districts for a crop and year
  List<Map<String, dynamic>> getTopYieldDistricts(
    String cropName,
    String year, {
    int limit = 10,
  }) {
    if (!_initialized) return [];
    try {
      final results = <Map<String, dynamic>>[];
      final cropList = _cropData['crops'] as List<dynamic>? ?? [];

      for (final item in cropList) {
        if (item['crop_name'] == cropName && item['year'] == year) {
          final productionMt = (item['production_mt'] as num?)?.toDouble() ?? 0;
          final hectares = (item['hectares'] as num?)?.toDouble() ?? 0;
          final yieldPerHectare = hectares > 0 ? productionMt / hectares : 0;

          results.add({
            'district': item['district'] ?? '',
            'production_mt': productionMt,
            'hectares': hectares,
            'yield_per_hectare': yieldPerHectare,
          });
        }
      }

      // Sort by yield descending
      results.sort(
        (a, b) => (b['yield_per_hectare'] as num).compareTo(
          a['yield_per_hectare'] as num,
        ),
      );

      // Limit results
      return limit > 0 ? results.take(limit).toList() : results;
    } catch (e) {
      debugPrint('Error getting top yield districts: $e');
      return [];
    }
  }

  /// Get total yield for a crop and year
  Map<String, dynamic> getTotalYield(String cropName, String year) {
    if (!_initialized) return {};
    try {
      double totalProduction = 0;
      double totalHectares = 0;

      final cropList = _cropData['crops'] as List<dynamic>? ?? [];
      for (final item in cropList) {
        if (item['crop_name'] == cropName && item['year'] == year) {
          totalProduction += (item['production_mt'] as num?)?.toDouble() ?? 0;
          totalHectares += (item['hectares'] as num?)?.toDouble() ?? 0;
        }
      }

      final averageYield = totalHectares > 0
          ? totalProduction / totalHectares
          : 0;

      return {
        'total_production': totalProduction,
        'total_hectares': totalHectares,
        'average_yield': averageYield,
      };
    } catch (e) {
      debugPrint('Error getting total yield: $e');
      return {};
    }
  }

  /// Get yield data by years for a crop and district
  List<Map<String, dynamic>> getYieldByYears(String cropName, String district) {
    if (!_initialized) return [];
    try {
      final results = <Map<String, dynamic>>[];
      final cropList = _cropData['crops'] as List<dynamic>? ?? [];

      for (final item in cropList) {
        if (item['crop_name'] == cropName && item['district'] == district) {
          final productionMt = (item['production_mt'] as num?)?.toDouble() ?? 0;
          final hectares = (item['hectares'] as num?)?.toDouble() ?? 0;
          final yieldPerHectare = hectares > 0 ? productionMt / hectares : 0;

          results.add({
            'year': item['year'] ?? '',
            'production_mt': productionMt,
            'hectares': hectares,
            'yield_per_hectare': yieldPerHectare,
          });
        }
      }

      // Sort by year ascending
      results.sort(
        (a, b) => (a['year'] as String).compareTo(b['year'] as String),
      );
      return results;
    } catch (e) {
      debugPrint('Error getting yield by years: $e');
      return [];
    }
  }

  /// Get district data for map visualization
  Map<String, Map<String, dynamic>> getDistrictDataForMap(
    String cropName,
    String year,
  ) {
    if (!_initialized) return {};
    try {
      final districtMap = <String, Map<String, dynamic>>{};
      double totalProduction = 0;

      final cropList = _cropData['crops'] as List<dynamic>? ?? [];

      // First pass: collect data and calculate total
      final tempData = <String, Map<String, dynamic>>{};
      for (final item in cropList) {
        if (item['crop_name'] == cropName &&
            item['year'] == year &&
            item['district'] != null) {
          final district = item['district'] as String;
          final production = (item['production_mt'] as num?)?.toDouble() ?? 0;
          final hectares = (item['hectares'] as num?)?.toDouble() ?? 0;
          final yieldPerHectare = hectares > 0 ? production / hectares : 0;

          tempData[district] = {
            'production': production,
            'hectares': hectares,
            'yield': yieldPerHectare,
          };
          totalProduction += production;
        }
      }

      // Second pass: calculate percentages
      for (final entry in tempData.entries) {
        final production = entry.value['production'] as double;
        final percentage = totalProduction > 0
            ? (production / totalProduction * 100)
            : 0;

        districtMap[entry.key] = {...entry.value, 'percentage': percentage};
      }

      return districtMap;
    } catch (e) {
      debugPrint('Error getting district map data: $e');
      return {};
    }
  }

  /// Get top crops for a district and year
  List<Map<String, dynamic>> getTopCropsForDistrict(
    String district,
    String year, {
    int limit = 10,
  }) {
    if (!_initialized) return [];
    try {
      final results = <Map<String, dynamic>>[];
      final cropList = _cropData['crops'] as List<dynamic>? ?? [];

      for (final item in cropList) {
        if (item['district'] == district && item['year'] == year) {
          final productionMt = (item['production_mt'] as num?)?.toDouble() ?? 0;
          final hectares = (item['hectares'] as num?)?.toDouble() ?? 0;
          final yieldPerHectare = hectares > 0 ? productionMt / hectares : 0;

          results.add({
            'crop_name': item['crop_name'] ?? '',
            'production_mt': productionMt,
            'hectares': hectares,
            'yield_per_hectare': yieldPerHectare,
          });
        }
      }

      // Sort by yield descending
      results.sort(
        (a, b) => (b['yield_per_hectare'] as num).compareTo(
          a['yield_per_hectare'] as num,
        ),
      );

      return limit > 0 ? results.take(limit).toList() : results;
    } catch (e) {
      debugPrint('Error getting top crops for district: $e');
      return [];
    }
  }

  /// Get prediction data for a crop
  List<Map<String, dynamic>> getPredictionData(String cropName) {
    if (!_initialized) return [];
    try {
      final results = <Map<String, dynamic>>[];
      // New export script aggregates all prediction tables into 'predictions' key
      final predList = _predictionData['predictions'] as List<dynamic>? ?? [];

      for (final item in predList) {
        if (item['crop_name'] == cropName) {
          results.add({
            'district': item['district'] ?? '',
            'area_hectares_pred': item['area_hectares_pred'] ?? 0,
            'production_mt_pred': item['production_mt_pred'] ?? 0,
          });
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error getting prediction data: $e');
      return [];
    }
  }

  /// Get top yield districts from predictions
  List<Map<String, dynamic>> getTopYieldDistrictsFromPredictions(
    String cropName, {
    int limit = 10,
  }) {
    if (!_initialized) return [];
    try {
      final results = <Map<String, dynamic>>[];
      final predList = _predictionData['predictions'] as List<dynamic>? ?? [];

      for (final item in predList) {
        if (item['crop_name'] == cropName) {
          final areaPred =
              (item['area_hectares_pred'] as num?)?.toDouble() ?? 0;
          final productionPred =
              (item['production_mt_pred'] as num?)?.toDouble() ?? 0;
          final yieldPerHectare = areaPred > 0 ? productionPred / areaPred : 0;

          results.add({
            'district': item['district'] ?? '',
            'area_hectares_pred': areaPred,
            'production_mt_pred': productionPred,
            'yield_per_hectare': yieldPerHectare,
          });
        }
      }

      // Sort by yield descending
      results.sort(
        (a, b) => (b['yield_per_hectare'] as num).compareTo(
          a['yield_per_hectare'] as num,
        ),
      );

      return limit > 0 ? results.take(limit).toList() : results;
    } catch (e) {
      debugPrint('Error getting top yield from predictions: $e');
      return [];
    }
  }

  /// Get total yield from predictions
  Map<String, dynamic> getTotalYieldFromPredictions(String cropName) {
    if (!_initialized) return {};
    try {
      double totalProduction = 0;
      double totalHectares = 0;

      final predList = _predictionData['predictions'] as List<dynamic>? ?? [];
      for (final item in predList) {
        if (item['crop_name'] == cropName) {
          totalProduction +=
              (item['production_mt_pred'] as num?)?.toDouble() ?? 0;
          totalHectares +=
              (item['area_hectares_pred'] as num?)?.toDouble() ?? 0;
        }
      }

      final averageYield = totalHectares > 0
          ? totalProduction / totalHectares
          : 0;

      return {
        'total_production': totalProduction,
        'total_hectares': totalHectares,
        'average_yield': averageYield,
      };
    } catch (e) {
      debugPrint('Error getting total yield from predictions: $e');
      return {};
    }
  }

  /// Get pie crop area data
  List<Map<String, dynamic>> getPieCropArea() {
    if (!_initialized) return [];
    try {
      final pieDataMap = _pieData['pie_data'] as Map<String, dynamic>? ?? {};
      final cropAreaList = pieDataMap['pie_crop_area'] as List<dynamic>? ?? [];
      return cropAreaList.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting pie crop area: $e');
      return [];
    }
  }

  /// Get pie fibre area data
  List<Map<String, dynamic>> getPieFibreArea() {
    if (!_initialized) return [];
    try {
      final pieDataMap = _pieData['pie_data'] as Map<String, dynamic>? ?? {};
      final fibreAreaList =
          pieDataMap['pie_fibre_area'] as List<dynamic>? ?? [];
      return fibreAreaList.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting pie fibre area: $e');
      return [];
    }
  }

  /// Get pie narcos area data
  List<Map<String, dynamic>> getPieNarcosArea() {
    if (!_initialized) return [];
    try {
      final pieDataMap = _pieData['pie_data'] as Map<String, dynamic>? ?? {};
      final narcosAreaList =
          pieDataMap['pie_narcos_area'] as List<dynamic>? ?? [];
      return narcosAreaList
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error getting pie narcos area: $e');
      return [];
    }
  }

  /// Get pie oilseed area data
  List<Map<String, dynamic>> getPieOilseedArea() {
    if (!_initialized) return [];
    try {
      final pieDataMap = _pieData['pie_data'] as Map<String, dynamic>? ?? {};
      final oilseedAreaList =
          pieDataMap['pie_oilseed_area'] as List<dynamic>? ?? [];
      return oilseedAreaList
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error getting pie oilseed area: $e');
      return [];
    }
  }

  /// Get pie pulse area data
  List<Map<String, dynamic>> getPiePulseArea() {
    if (!_initialized) return [];
    try {
      final pieDataMap = _pieData['pie_data'] as Map<String, dynamic>? ?? {};
      final pulseAreaList =
          pieDataMap['pie_pulse_area'] as List<dynamic>? ?? [];
      return pulseAreaList.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting pie pulse area: $e');
      return [];
    }
  }

  /// Get pie rice area data
  List<Map<String, dynamic>> getPieRiceArea() {
    if (!_initialized) return [];
    try {
      final pieDataMap = _pieData['pie_data'] as Map<String, dynamic>? ?? {};
      final riceAreaList = pieDataMap['pie_rice_area'] as List<dynamic>? ?? [];
      return riceAreaList.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting pie rice area: $e');
      return [];
    }
  }

  /// Get pie spices area data
  List<Map<String, dynamic>> getPieSpicesArea() {
    if (!_initialized) return [];
    try {
      final pieDataMap = _pieData['pie_data'] as Map<String, dynamic>? ?? {};
      final spicesAreaList =
          pieDataMap['pie_spices_area'] as List<dynamic>? ?? [];
      return spicesAreaList
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error getting pie spices area: $e');
      return [];
    }
  }

  /// Get pie sugar area data
  List<Map<String, dynamic>> getPieSugerArea() {
    if (!_initialized) return [];
    try {
      final pieDataMap = _pieData['pie_data'] as Map<String, dynamic>? ?? {};
      final sugarAreaList =
          pieDataMap['pie_suger_area'] as List<dynamic>? ?? [];
      return sugarAreaList.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting pie sugar area: $e');
      return [];
    }
  }
}
