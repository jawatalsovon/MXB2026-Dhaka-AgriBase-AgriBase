import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/localization_provider.dart';
import '../services/disease_service.dart';
import '../providers/disease_detection_provider.dart';
import 'assistant_screen.dart';

class DiseaseScannerScreen extends StatefulWidget {
  const DiseaseScannerScreen({super.key});

  @override
  State<DiseaseScannerScreen> createState() => _DiseaseScannerScreenState();
}

class _DiseaseScannerScreenState extends State<DiseaseScannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        if (mounted) {
          context.read<DiseaseDetectionProvider>().setImagePath(
            pickedFile.path,
          );
          _analyzeImage(pickedFile.path);
        }
      }
    } catch (e) {
      if (mounted) {
        context.read<DiseaseDetectionProvider>().setError(
          'Error picking image: $e',
        );
      }
    }
  }

  Future<void> _analyzeImage(String imagePath) async {
    try {
      final provider = context.read<DiseaseDetectionProvider>();
      provider.setLoading(true);

      // TODO: Integrate TFLite model for actual inference
      // For now, using mock identification
      await Future.delayed(const Duration(seconds: 2));

      // Mock result - replace with actual model inference
      final detectedKey = DiseaseIdentificationService.identifyDisease(
        imagePath,
        0.95,
      );

      if (mounted) {
        provider.setDetectionResult(detectedKey, 0.95);
        provider.setLoading(false);
      }
    } catch (e) {
      if (mounted) {
        context.read<DiseaseDetectionProvider>().setLoading(false);
        context.read<DiseaseDetectionProvider>().setError(
          'Error analyzing image: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<LocalizationProvider, DiseaseDetectionProvider>(
      builder: (context, localizationProvider, provider, _) {
        final locale = localizationProvider.locale;
        final isBangla = locale.languageCode == 'bn';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.colorScheme.primary,
            title: Text(isBangla ? '🔬 রোগ স্ক্যানার' : '🔬 Disease Scanner'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBangla ? 'কিভাবে ব্যবহার করবেন:' : 'How to use:',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isBangla
                              ? '১. প্রভাবিত পাতার পরিষ্কার ছবি তুলুন\n২. ভাল আলো নিশ্চিত করুন\n৩. রোগের লক্ষণগুলিতে ফোকাস করুন\n৪. বিশ্লেষণের জন্য ছবি আপলোড করুন'
                              : '1. Take a clear photo of the affected leaf\n2. Ensure good lighting\n3. Focus on the disease symptoms\n4. Upload the image for analysis',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image Picker Buttons
                  if (provider.selectedImagePath == null) ...[
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(isBangla ? 'ছবি তুলুন' : 'Take a Photo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: Text(
                        isBangla
                            ? 'গ্যালারি থেকে নির্বাচন করুন'
                            : 'Choose from Gallery',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else ...[
                    // Selected Image Display
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(provider.selectedImagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Loading State
                    if (provider.isLoading) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              isBangla
                                  ? 'ছবি বিশ্লেষণ করা হচ্ছে...'
                                  : 'Analyzing image...',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ] else if (provider.errorMessage != null) ...[
                      // Error State
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          provider.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red[900],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => provider.reset(),
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          isBangla ? 'আবার চেষ্টা করুন' : 'Try Again',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ] else if (provider.detectedDisease != null) ...[
                      // Result State
                      _buildDiseaseResult(
                        context,
                        provider.detectedDisease!,
                        provider.confidence,
                        theme,
                        isBangla,
                      ),
                      const SizedBox(height: 16),

                      // Ask AI Bridge Button
                      _buildAskAIBridgeButton(
                        context,
                        provider.detectedDisease!,
                        theme,
                        isBangla,
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: () => provider.reset(),
                        icon: const Icon(Icons.add_a_photo),
                        label: Text(
                          isBangla
                              ? 'অন্য ছবি স্ক্যান করুন'
                              : 'Scan Another Image',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ] else ...[
                      // Initial state after image selection
                      ElevatedButton.icon(
                        onPressed: () =>
                            _analyzeImage(provider.selectedImagePath!),
                        icon: const Icon(Icons.search),
                        label: Text(
                          isBangla ? 'ছবি বিশ্লেষণ করুন' : 'Analyze Image',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiseaseResult(
    BuildContext context,
    String diseaseKey,
    double confidence,
    ThemeData theme,
    bool isBangla,
  ) {
    final disease = DiseaseDatabase.getDiseaseInfo(diseaseKey);

    if (disease == null) {
      return Center(
        child: Text(
          isBangla
              ? 'রোগের তথ্য পাওয়া যায়নি'
              : 'Disease information not found',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    // Determine severity color
    Color severityColor;
    switch (disease.severity.toLowerCase()) {
      case 'high':
        severityColor = Colors.red;
        break;
      case 'medium':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.green;
    }

    final diseaseName = isBangla ? disease.diseaseNameBn : disease.diseaseName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Disease Result Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.withValues(alpha: 0.05),
                Colors.orange.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with AI badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isBangla ? 'এআই নির্ণয়' : 'AI Diagnosis',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Severity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: severityColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          disease.severity.toLowerCase() == 'high'
                              ? Icons.warning
                              : disease.severity.toLowerCase() == 'medium'
                              ? Icons.info
                              : Icons.check_circle,
                          color: severityColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          disease.severity,
                          style: TextStyle(
                            color: severityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Disease Name
              Text(
                diseaseName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
              ),
              const SizedBox(height: 12),

              // Confidence Score with Visual Indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isBangla ? 'আত্মবিশ্বাসের স্কোর' : 'Confidence Score',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: confidence > 0.8
                                ? Colors.green[700]
                                : confidence > 0.6
                                ? Colors.orange[700]
                                : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: confidence,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          confidence > 0.8
                              ? Colors.green
                              : confidence > 0.6
                              ? Colors.orange
                              : Colors.red,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      confidence > 0.8
                          ? (isBangla
                                ? 'উচ্চ আত্মবিশ্বাস - সম্ভবত সঠিক'
                                : 'High confidence - Likely accurate')
                          : confidence > 0.6
                          ? (isBangla
                                ? 'মাঝারি আত্মবিশ্বাস - যাচাইয়ের প্রয়োজন হতে পারে'
                                : 'Medium confidence - May need verification')
                          : (isBangla
                                ? 'কম আত্মবিশ্বাস - বিশেষজ্ঞের পরামর্শ বিবেচনা করুন'
                                : 'Low confidence - Consider expert consultation'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Disease Details
        _buildDetailSection(
          isBangla ? '📋 লক্ষণ' : '📋 Symptoms',
          disease.symptoms,
          Colors.orange,
          theme,
        ),
        const SizedBox(height: 12),

        _buildDetailSection(
          isBangla ? '💊 চিকিৎসা বিকল্প' : '💊 Treatment Options',
          disease.treatments,
          Colors.green,
          theme,
        ),
        const SizedBox(height: 12),

        _buildDetailSection(
          isBangla ? '🛡️ প্রতিরোধ পদ্ধতি' : '🛡️ Prevention Methods',
          disease.prevention,
          Colors.blue,
          theme,
        ),
      ],
    );
  }

  Widget _buildAskAIBridgeButton(
    BuildContext context,
    String diseaseKey,
    ThemeData theme,
    bool isBangla,
  ) {
    final disease = DiseaseDatabase.getDiseaseInfo(diseaseKey);
    final diseaseName = isBangla
        ? (disease?.diseaseNameBn ?? diseaseKey)
        : (disease?.diseaseName ?? diseaseKey);

    return GestureDetector(
      onTap: () {
        final query = isBangla
            ? 'আমি আমার ফসলে $diseaseName খুঁজে পেয়েছি। আমি এটি কীভাবে চিকিৎসা করব?'
            : 'I found $diseaseName on my crop. How do I treat it?';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssistantScreen(initialQuery: query),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF311B92)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A237E).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ask AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get detailed treatment advice for $diseaseName',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Color(0xFF1A237E),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    List<String> items,
    Color accentColor,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•', style: TextStyle(color: accentColor, fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item, style: theme.textTheme.labelSmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
