import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/my_crop.dart';
import '../providers/my_crops_provider.dart';
import '../providers/localization_provider.dart';
import '../services/crop_info_service.dart';
import '../services/crops_database_service.dart';
import '../utils/translation_helper.dart';
import 'crop_detail_screen.dart';

class MyCropsScreen extends StatefulWidget {
  const MyCropsScreen({super.key});

  @override
  State<MyCropsScreen> createState() => _MyCropsScreenState();
}

class _MyCropsScreenState extends State<MyCropsScreen> {
  final CropInfoService _cropInfoService = CropInfoService();

  String _formatCropName(String raw) {
    return raw
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1) : ''}',
        )
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MyCropsProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<MyCropsProvider, LocalizationProvider>(
      builder: (context, cropsProvider, locProvider, child) {
        final isBangla = locProvider.locale.languageCode == 'bn';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.colorScheme.primary,
            title: Text(isBangla ? 'আমার ফসল' : 'My Crops'),
            centerTitle: true,
            elevation: 0,
          ),
          body: cropsProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : cropsProvider.isEmpty
              ? _buildEmptyState(theme, isBangla)
              : _buildCropsList(theme, isBangla, cropsProvider),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddCropDialog(context, isBangla),
            backgroundColor: theme.colorScheme.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              isBangla ? 'ফসল যোগ করুন' : 'Add Crop',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isBangla) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.eco_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isBangla ? 'কোনো ফসল নেই' : 'No Crops Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isBangla
                  ? 'আপনার ফসল যোগ করুন এবং\nব্যক্তিগত পরামর্শ পান'
                  : 'Add your crops to get\npersonalized insights',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _showAddCropDialog(context, isBangla),
              icon: const Icon(Icons.add),
              label: Text(
                isBangla ? 'প্রথম ফসল যোগ করুন' : 'Add Your First Crop',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropsList(
    ThemeData theme,
    bool isBangla,
    MyCropsProvider provider,
  ) {
    final crops = provider.cropsByHarvestDate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          _buildSummaryCard(theme, isBangla, provider),
          const SizedBox(height: 16),

          // Crops needing attention
          if (provider.cropsNeedingAttention.isNotEmpty) ...[
            _buildSectionHeader(
              theme,
              isBangla ? '⚠️ মনোযোগ দরকার' : '⚠️ Needs Attention',
            ),
            const SizedBox(height: 8),
            ...provider.cropsNeedingAttention.map(
              (crop) => _buildCropCard(theme, isBangla, crop, isUrgent: true),
            ),
            const SizedBox(height: 16),
          ],

          // Ready for harvest
          if (provider.cropsReadyForHarvest.isNotEmpty) ...[
            _buildSectionHeader(
              theme,
              isBangla ? '🌾 কাটার জন্য প্রস্তুত' : '🌾 Ready for Harvest',
            ),
            const SizedBox(height: 8),
            ...provider.cropsReadyForHarvest.map(
              (crop) =>
                  _buildCropCard(theme, isBangla, crop, isHarvestReady: true),
            ),
            const SizedBox(height: 16),
          ],

          // All crops
          _buildSectionHeader(theme, isBangla ? '🌱 সব ফসল' : '🌱 All Crops'),
          const SizedBox(height: 8),
          ...crops
              .where((c) => !c.isReadyForHarvest && c.daysUntilHarvest > 7)
              .map((crop) => _buildCropCard(theme, isBangla, crop)),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    bool isBangla,
    MyCropsProvider provider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBangla ? 'ফসলের সারসংক্ষেপ' : 'Crop Summary',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                theme,
                isBangla ? 'মোট ফসল' : 'Total Crops',
                '${provider.cropCount}',
                Icons.eco,
              ),
              _buildSummaryItem(
                theme,
                isBangla ? 'মোট জমি' : 'Total Area',
                '${provider.totalAreaHectares.toStringAsFixed(2)} ha',
                Icons.landscape,
              ),
              _buildSummaryItem(
                theme,
                isBangla ? 'কাটার জন্য প্রস্তুত' : 'Ready',
                '${provider.cropsReadyForHarvest.length}',
                Icons.check_circle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCropCard(
    ThemeData theme,
    bool isBangla,
    MyCrop crop, {
    bool isUrgent = false,
    bool isHarvestReady = false,
  }) {
    final cropInfo = _cropInfoService.getCropInfo(crop.cropName);
    final stageInfo = _cropInfoService.getCurrentStageInfo(
      crop.cropName,
      crop.daysSincePlanting,
    );

    Color cardColor = theme.colorScheme.surface;
    Color borderColor = theme.colorScheme.outline.withOpacity(0.2);

    if (isHarvestReady) {
      cardColor = Colors.green.withOpacity(0.05);
      borderColor = Colors.green.withOpacity(0.3);
    } else if (isUrgent) {
      cardColor = Colors.orange.withOpacity(0.05);
      borderColor = Colors.orange.withOpacity(0.3);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      color: cardColor,
      child: InkWell(
        onTap: () => _navigateToDetail(crop),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cropInfo?.icon ?? '🌱',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBangla
                              ? (cropInfo?.nameBn ?? crop.cropNameBn)
                              : _formatCropName(
                                  cropInfo?.name ?? crop.cropName,
                                ),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${crop.landArea} ${_getUnitLabel(crop.landUnit, isBangla)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isHarvestReady)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isBangla ? 'প্রস্তুত!' : 'Ready!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          isBangla
                              ? '${crop.daysUntilHarvest} দিন বাকি'
                              : '${crop.daysUntilHarvest} days left',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUrgent
                                ? Colors.orange[700]
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stageInfo != null
                            ? (isBangla ? stageInfo.nameBn : stageInfo.name)
                            : crop.getGrowthStageName(isBangla),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(crop.growthProgress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: crop.growthProgress,
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isHarvestReady
                            ? Colors.green
                            : isUrgent
                            ? Colors.orange
                            : theme.colorScheme.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUnitLabel(String unit, bool isBangla) {
    switch (unit) {
      case 'hectare':
        return isBangla ? 'হেক্টর' : 'hectare';
      case 'bigha':
        return isBangla ? 'বিঘা' : 'bigha';
      case 'acre':
        return isBangla ? 'একর' : 'acre';
      case 'decimal':
        return isBangla ? 'ডেসিমেল' : 'decimal';
      default:
        return unit;
    }
  }

  void _navigateToDetail(MyCrop crop) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CropDetailScreen(crop: crop)),
    );
  }

  void _showAddCropDialog(BuildContext context, bool isBangla) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCropBottomSheet(isBangla: isBangla),
    );
  }
}

class AddCropBottomSheet extends StatefulWidget {
  final bool isBangla;

  const AddCropBottomSheet({super.key, required this.isBangla});

  @override
  State<AddCropBottomSheet> createState() => _AddCropBottomSheetState();
}

class _AddCropBottomSheetState extends State<AddCropBottomSheet> {
  final CropInfoService _cropInfoService = CropInfoService();
  final CropsDatabaseService _cropsDatabaseService = CropsDatabaseService();
  final _formKey = GlobalKey<FormState>();

  String? _selectedCrop;
  double _landArea = 1.0;
  String _landUnit = 'hectare';
  DateTime _plantedDate = DateTime.now();
  List<String> _availableCrops = [];
  bool _loadingCrops = true;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    setState(() => _loadingCrops = true);
    try {
      final crops = await _cropsDatabaseService.getAllCrops();
      setState(() {
        _availableCrops = crops;
        _selectedCrop = crops.isNotEmpty ? crops.first : null;
      });
    } catch (_) {
      setState(() {
        _availableCrops = [];
      });
    } finally {
      if (mounted) {
        setState(() => _loadingCrops = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBangla = widget.isBangla;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                isBangla ? 'নতুন ফসল যোগ করুন' : 'Add New Crop',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Crop Selection
              Text(
                isBangla ? 'ফসল নির্বাচন করুন' : 'Select Crop',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingCrops)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_availableCrops.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    isBangla ? 'কোনো ফসল পাওয়া যায়নি' : 'No crops found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedCrop,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  hint: Text(isBangla ? 'একটি ফসল বেছে নিন' : 'Choose a crop'),
                  items: _availableCrops.map((crop) {
                    return DropdownMenuItem(
                      value: crop,
                      child: Text(
                        TranslationHelper.formatCropName(
                          crop,
                          isBangla ? const Locale('bn') : const Locale('en'),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCrop = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return isBangla
                          ? 'একটি ফসল নির্বাচন করুন'
                          : 'Please select a crop';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 20),

              // Land Area
              Text(
                isBangla ? 'জমির পরিমাণ' : 'Land Area',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: '1.0',
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: isBangla ? 'পরিমাণ' : 'Amount',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _landArea = double.tryParse(value) ?? 1.0;
                      },
                      validator: (value) {
                        if (value == null || double.tryParse(value) == null) {
                          return isBangla
                              ? 'সঠিক সংখ্যা দিন'
                              : 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _landUnit,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'hectare', child: Text('ha')),
                        DropdownMenuItem(value: 'bigha', child: Text('bigha')),
                        DropdownMenuItem(value: 'acre', child: Text('acre')),
                        DropdownMenuItem(
                          value: 'decimal',
                          child: Text('decimal'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _landUnit = value ?? 'hectare';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Days old
              Text(
                isBangla
                    ? 'ফসল কত দিন আগে লাগিয়েছেন?'
                    : 'How many days ago was it planted?',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: '0',
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: isBangla ? '০ = আজ লাগিয়েছি' : '0 = planted today',
                  suffixText: isBangla ? 'দিন আগে' : 'days ago',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final days = int.tryParse(value) ?? 0;
                  setState(() {
                    _plantedDate = DateTime.now().subtract(
                      Duration(days: days),
                    );
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                isBangla
                    ? 'রোপণের তারিখ: ${_formatDate(_plantedDate, isBangla)}'
                    : 'Planted on: ${_formatDate(_plantedDate, isBangla)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitCrop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isBangla ? 'ফসল যোগ করুন' : 'Add Crop',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCropName(String raw) {
    return raw
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1) : ''}',
        )
        .join(' ');
  }

  String _formatDate(DateTime date, bool isBangla) {
    final months = isBangla
        ? [
            'জানু',
            'ফেব্রু',
            'মার্চ',
            'এপ্রি',
            'মে',
            'জুন',
            'জুলাই',
            'আগ',
            'সেপ্ট',
            'অক্টো',
            'নভে',
            'ডিসে',
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _submitCrop() {
    if (_loadingCrops) return;
    if (_availableCrops.isEmpty || _selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBangla
                ? 'কোনো ফসল নির্বাচন করা যায়নি'
                : 'No crop available to add',
          ),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final cropInfo = _cropInfoService.getCropInfo(_selectedCrop!);

      final newCrop = MyCrop(
        id: MyCropsProvider.generateId(),
        cropName: _selectedCrop!,
        cropNameBn: cropInfo?.nameBn ?? _formatCropName(_selectedCrop!),
        landArea: _landArea,
        landUnit: _landUnit,
        plantedDate: _plantedDate,
        growthDurationDays: cropInfo?.growthDurationDays ?? 90,
      );

      Provider.of<MyCropsProvider>(context, listen: false).addCrop(newCrop);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBangla
                ? 'ফসল যোগ করা হয়েছে!'
                : 'Crop added successfully!',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}
