import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/my_crop.dart';

class MyCropsProvider with ChangeNotifier {
  static const String _storageKey = 'my_crops';

  List<MyCrop> _crops = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<MyCrop> get crops => List.unmodifiable(_crops);
  bool get isLoading => _isLoading;
  bool get isEmpty => _crops.isEmpty;
  int get cropCount => _crops.length;

  /// Get crops sorted by days until harvest (soonest first)
  List<MyCrop> get cropsByHarvestDate {
    final sorted = List<MyCrop>.from(_crops);
    sorted.sort((a, b) => a.daysUntilHarvest.compareTo(b.daysUntilHarvest));
    return sorted;
  }

  /// Get crops ready for harvest
  List<MyCrop> get cropsReadyForHarvest =>
      _crops.where((c) => c.isReadyForHarvest).toList();

  /// Get crops needing attention (within 7 days of harvest or in critical stage)
  List<MyCrop> get cropsNeedingAttention => _crops
      .where((c) => c.daysUntilHarvest <= 7 && !c.isReadyForHarvest)
      .toList();

  /// Initialize and load crops from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey) ?? '';
      _crops = deserializeCrops(jsonString);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading crops: $e');
      _crops = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save crops to storage
  Future<void> _saveCrops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, serializeCrops(_crops));
    } catch (e) {
      debugPrint('Error saving crops: $e');
    }
  }

  /// Add a new crop
  Future<void> addCrop(MyCrop crop) async {
    _crops.add(crop);
    notifyListeners();
    await _saveCrops();
  }

  /// Update an existing crop
  Future<void> updateCrop(MyCrop updatedCrop) async {
    final index = _crops.indexWhere((c) => c.id == updatedCrop.id);
    if (index != -1) {
      _crops[index] = updatedCrop;
      notifyListeners();
      await _saveCrops();
    }
  }

  /// Remove a crop
  Future<void> removeCrop(String cropId) async {
    _crops.removeWhere((c) => c.id == cropId);
    notifyListeners();
    await _saveCrops();
  }

  /// Get crop by ID
  MyCrop? getCropById(String id) {
    try {
      return _crops.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear all crops
  Future<void> clearAllCrops() async {
    _crops.clear();
    notifyListeners();
    await _saveCrops();
  }

  /// Get total area under cultivation (in hectares)
  double get totalAreaHectares =>
      _crops.fold(0.0, (sum, crop) => sum + crop.areaInHectares);

  /// Get crops by growth stage
  Map<String, List<MyCrop>> get cropsByGrowthStage {
    final result = <String, List<MyCrop>>{};
    for (final crop in _crops) {
      result.putIfAbsent(crop.growthStage, () => []).add(crop);
    }
    return result;
  }

  /// Generate unique ID
  static String generateId() {
    return 'crop_${DateTime.now().millisecondsSinceEpoch}';
  }
}
