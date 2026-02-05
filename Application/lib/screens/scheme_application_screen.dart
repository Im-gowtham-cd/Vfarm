import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vfarm/models/govt_scheme_model.dart';
import 'package:vfarm/models/user_profile_model.dart';
import 'package:vfarm/scheme_service.dart';
import 'package:vfarm/session_manager.dart';

// Model for survey data
class SurveyData {
  final String district;
  final String town;
  final String village;
  final String surveyNumber;
  final double areaInCents;

  SurveyData({
    required this.district,
    required this.town,
    required this.village,
    required this.surveyNumber,
    required this.areaInCents,
  });

  String get fullAddress => '$village, $town, $district';

  factory SurveyData.fromCsvRow(List<dynamic> row) {
    return SurveyData(
      district: row[0].toString(),
      town: row[1].toString(),
      village: row[2].toString(),
      surveyNumber: row[3].toString(),
      areaInCents: double.tryParse(row[4].toString()) ?? 0.0,
    );
  }
}

class SchemeApplicationScreen extends StatefulWidget {
  final GovtSchemeModel scheme;
  final UserProfileModel userProfile;
  final VoidCallback onApplicationSubmitted;

  const SchemeApplicationScreen({
    super.key,
    required this.scheme,
    required this.userProfile,
    required this.onApplicationSubmitted,
  });

  @override
  State<SchemeApplicationScreen> createState() =>
      _SchemeApplicationScreenState();
}

class _SchemeApplicationScreenState extends State<SchemeApplicationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final SchemeService _schemeService = SchemeService();
  final ImagePicker _imagePicker = ImagePicker();

  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Existing controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _farmLocationController;
  late TextEditingController _farmSizeController;
  late TextEditingController _cropTypesController;
  late TextEditingController _bankAccountController;
  late TextEditingController _ifscController;
  late TextEditingController _aadharController;
  late TextEditingController _surveyNumberController;
  late TextEditingController _addressController;

  final List<File> _selectedDocuments = [];
  final List<File> _landProofImages = [];
  bool _isSubmitting = false;
  double _submissionProgress = 0.0;
  String _submissionStatus = '';
  
  // Survey validation
  List<SurveyData> _allSurveyData = [];
  List<SurveyData> _filteredSurveyData = [];
  bool _isSurveyNumberValid = false;
  bool _isLoadingCsv = false;
  String? _surveyValidationMessage;
  SurveyData? _selectedSurveyData;

  // Form completion tracking
  final Map<String, bool> _sectionCompletion = {
    'personal': false,
    'land': false,
    'bank': false,
    'documents': false,
    'landProof': false,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
    _loadSurveyData();
    _trackFormCompletion();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.userProfile.name);
    _emailController = TextEditingController(text: widget.userProfile.email);
    _phoneController = TextEditingController(
      text: widget.userProfile.phone ?? '',
    );
    _farmLocationController = TextEditingController(
      text: widget.userProfile.farmLocation ?? '',
    );
    _farmSizeController = TextEditingController(
      text: widget.userProfile.farmSize?.toString() ?? '',
    );
    _cropTypesController = TextEditingController(
      text: widget.userProfile.cropTypes.join(', '),
    );
    _bankAccountController = TextEditingController();
    _ifscController = TextEditingController();
    _aadharController = TextEditingController();
    _surveyNumberController = TextEditingController();
    _addressController = TextEditingController();

    _surveyNumberController.addListener(_validateSurveyNumber);
  }

  void _trackFormCompletion() {
    _nameController.addListener(() => _updateSectionCompletion('personal'));
    _emailController.addListener(() => _updateSectionCompletion('personal'));
    _phoneController.addListener(() => _updateSectionCompletion('personal'));
    
    _surveyNumberController.addListener(() => _updateSectionCompletion('land'));
    _farmSizeController.addListener(() => _updateSectionCompletion('land'));
    _cropTypesController.addListener(() => _updateSectionCompletion('land'));
    
    _bankAccountController.addListener(() => _updateSectionCompletion('bank'));
    _ifscController.addListener(() => _updateSectionCompletion('bank'));
    _aadharController.addListener(() => _updateSectionCompletion('bank'));
  }

  void _updateSectionCompletion(String section) {
    setState(() {
      switch (section) {
        case 'personal':
          _sectionCompletion['personal'] = _nameController.text.isNotEmpty &&
              _emailController.text.isNotEmpty &&
              _phoneController.text.isNotEmpty;
          break;
        case 'land':
          _sectionCompletion['land'] = _surveyNumberController.text.isNotEmpty &&
              _farmSizeController.text.isNotEmpty &&
              _cropTypesController.text.isNotEmpty &&
              _isSurveyNumberValid;
          break;
        case 'bank':
          _sectionCompletion['bank'] = _bankAccountController.text.isNotEmpty &&
              _ifscController.text.isNotEmpty &&
              _aadharController.text.isNotEmpty;
          break;
        case 'documents':
          _sectionCompletion['documents'] = _selectedDocuments.isNotEmpty;
          break;
        case 'landProof':
          _sectionCompletion['landProof'] = _landProofImages.isNotEmpty;
          break;
      }
    });
    _updateProgressBar();
  }

  void _updateProgressBar() {
    final completedSections = _sectionCompletion.values.where((v) => v).length;
    final progress = completedSections / _sectionCompletion.length;
    _progressController.animateTo(progress);
  }

  Future<void> _loadSurveyData() async {
    setState(() => _isLoadingCsv = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Smooth loading
      final String csvString = await rootBundle.loadString('assets/kerala_land_records_enhanced.csv');
      List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      
      if (csvData.isNotEmpty) {
        csvData.removeAt(0);
        _allSurveyData = csvData.map((row) => SurveyData.fromCsvRow(row)).toList();
      }
    } catch (e) {
      print('Error loading CSV: $e');
      if (mounted) {
        _showErrorSnackBar('Error loading survey data. Please try again later.');
      }
    } finally {
      setState(() => _isLoadingCsv = false);
    }
  }

  void _validateSurveyNumber() {
    final query = _surveyNumberController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _isSurveyNumberValid = false;
        _surveyValidationMessage = null;
        _selectedSurveyData = null;
        _addressController.clear();
        _filteredSurveyData.clear();
      });
      _updateSectionCompletion('land');
      return;
    }

    _filteredSurveyData = _allSurveyData
        .where((survey) => 
            survey.surveyNumber.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    final exactMatch = _allSurveyData.firstWhere(
      (survey) => survey.surveyNumber.toLowerCase() == query.toLowerCase(),
      orElse: () => SurveyData(
        district: '',
        town: '',
        village: '',
        surveyNumber: '',
        areaInCents: 0.0,
      ),
    );

    setState(() {
      if (exactMatch.surveyNumber.isNotEmpty) {
        _isSurveyNumberValid = true;
        _selectedSurveyData = exactMatch;
        _addressController.text = exactMatch.fullAddress;
        _surveyValidationMessage = 'Valid survey number found';
        _filteredSurveyData.clear();
      } else {
        _isSurveyNumberValid = false;
        _selectedSurveyData = null;
        _addressController.clear();
        _surveyValidationMessage = _filteredSurveyData.isEmpty 
            ? 'No matching survey number found'
            : 'Select from suggestions or enter exact survey number';
      }
    });
    _updateSectionCompletion('land');
  }

  void _selectSurveyFromSuggestion(SurveyData survey) {
    _surveyNumberController.text = survey.surveyNumber;
    _addressController.text = survey.fullAddress;
    setState(() {
      _isSurveyNumberValid = true;
      _selectedSurveyData = survey;
      _surveyValidationMessage = 'Valid survey number selected';
      _filteredSurveyData.clear();
    });
    _updateSectionCompletion('land');
  }

  Future<void> _pickLandProofImages() async {
    try {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1920,
                          maxHeight: 1080,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setState(() {
                            _landProofImages.add(File(image.path));
                          });
                          _updateSectionCompletion('landProof');
                          _showSuccessMessage('Image added successfully');
                        }
                      },
                    ),
                    _buildImageSourceButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        final List<XFile> images = await _imagePicker.pickMultiImage(
                          maxWidth: 1920,
                          maxHeight: 1080,
                          imageQuality: 85,
                        );
                        if (images.isNotEmpty) {
                          setState(() {
                            _landProofImages.addAll(
                              images.map((image) => File(image.path)).toList(),
                            );
                          });
                          _updateSectionCompletion('landProof');
                          _showSuccessMessage('${images.length} image(s) added successfully');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    } catch (e) {
      _showErrorSnackBar('Error picking images: $e');
    }
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0A9D88).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF0A9D88).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFF0A9D88),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0A9D88),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeLandProofImage(int index) {
    setState(() {
      _landProofImages.removeAt(index);
    });
    _updateSectionCompletion('landProof');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAnimatedSection('Personal Information', _buildPersonalInfo()),
                        _buildAnimatedSection('Land Information', _buildLandInfo()),
                        _buildAnimatedSection('Bank Details', _buildBankDetails()),
                        _buildAnimatedSection('Land Proof Images', _buildLandProofSection()),
                        _buildAnimatedSection('Required Documents', _buildDocumentsSection()),
                        const SizedBox(height: 100), // Space for floating button
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildSubmitButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF0A9D88),
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apply for ${widget.scheme.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Complete all sections to proceed',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      color: const Color(0xFF0A9D88),
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          final completedSections = _sectionCompletion.values.where((v) => v).length;
          return Row(
            children: [
              Expanded(
                child: Text(
                  'Progress: $completedSections of ${_sectionCompletion.length} sections completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${(_progressAnimation.value * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedSection(String title, Widget content) {
    final isCompleted = _getSectionCompletion(title);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isCompleted ? const Color(0xFF0A9D88).withOpacity(0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? const Color(0xFF0A9D88).withOpacity(0.1)
                  : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF0A9D88) : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? const Color(0xFF0A9D88) : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: content,
          ),
        ],
      ),
    );
  }

  bool _getSectionCompletion(String title) {
    switch (title) {
      case 'Personal Information':
        return _sectionCompletion['personal'] ?? false;
      case 'Land Information':
        return _sectionCompletion['land'] ?? false;
      case 'Bank Details':
        return _sectionCompletion['bank'] ?? false;
      case 'Land Proof Images':
        return _sectionCompletion['landProof'] ?? false;
      case 'Required Documents':
        return _sectionCompletion['documents'] ?? false;
      default:
        return false;
    }
  }

  Widget _buildPersonalInfo() {
    return Column(
      children: [
        _buildEnhancedTextField(
          'Full Name',
          _nameController,
          Icons.person,
          required: true,
        ),
        _buildEnhancedTextField(
          'Email',
          _emailController,
          Icons.email,
          required: true,
        ),
        _buildEnhancedTextField(
          'Phone Number',
          _phoneController,
          Icons.phone,
          required: true,
        ),
      ],
    );
  }

  Widget _buildLandInfo() {
    return Column(
      children: [
        _buildSurveyNumberField(),
        _buildAddressField(),
        _buildEnhancedTextField(
          'Farm Size (in acres)',
          _farmSizeController,
          Icons.agriculture,
          required: true,
        ),
        _buildEnhancedTextField(
          'Crop Types',
          _cropTypesController,
          Icons.eco,
          required: true,
        ),
      ],
    );
  }

  Widget _buildBankDetails() {
    return Column(
      children: [
        _buildEnhancedTextField(
          'Bank Account Number',
          _bankAccountController,
          Icons.account_balance,
          required: true,
        ),
        _buildEnhancedTextField(
          'IFSC Code',
          _ifscController,
          Icons.code,
          required: true,
        ),
        _buildEnhancedTextField(
          'Aadhaar Number',
          _aadharController,
          Icons.credit_card,
          required: true,
        ),
      ],
    );
  }

  Widget _buildEnhancedTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          prefixIcon: Icon(icon, color: const Color(0xFF0A9D88)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0A9D88), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: required
            ? (value) => value?.isEmpty == true ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _buildSurveyNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              TextFormField(
                controller: _surveyNumberController,
                decoration: InputDecoration(
                  labelText: 'Survey Number *',
                  hintText: 'Survey number(e.g:SUR-THI-NEY-KAN-1234)',
                  prefixIcon: const Icon(Icons.map, color: Color(0xFF0A9D88)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0A9D88), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixIcon: _isLoadingCsv
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _isSurveyNumberValid
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : _surveyNumberController.text.isNotEmpty
                              ? const Icon(Icons.error, color: Colors.red)
                              : null,
                ),
                validator: (value) {
                  if (value?.isEmpty == true) {
                    return 'Survey number is required';
                  }
                  if (!_isSurveyNumberValid) {
                    return 'Please enter a valid survey number';
                  }
                  return null;
                },
              ),
              if (_surveyValidationMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSurveyNumberValid 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isSurveyNumberValid ? Colors.green : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSurveyNumberValid ? Icons.check_circle : Icons.info,
                          size: 16,
                          color: _isSurveyNumberValid ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _surveyValidationMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _isSurveyNumberValid ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        if (_filteredSurveyData.isNotEmpty)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF0A9D88).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A9D88).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, 
                                 color: Color(0xFF0A9D88), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Suggestions:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                ...(_filteredSurveyData.take(3).map((survey) => 
                  InkWell(
                    onTap: () => _selectSurveyFromSuggestion(survey),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A9D88).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF0A9D88),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  survey.surveyNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0A9D88),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  survey.fullAddress,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'Area: ${survey.areaInCents} cents',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddressField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: _addressController,
        decoration: InputDecoration(
          labelText: 'Land Address',
          hintText: 'Address will be auto-filled based on survey number',
          prefixIcon: const Icon(Icons.location_city, color: Color(0xFF0A9D88)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0A9D88), width: 2),
          ),
          filled: true,
          fillColor: _selectedSurveyData != null 
              ? const Color(0xFF0A9D88).withOpacity(0.05)
              : Colors.grey[100],
        ),
        readOnly: true,
        style: TextStyle(
          color: _selectedSurveyData != null ? Colors.black : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLandProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload images of your land as proof:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: _pickLandProofImages,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: _landProofImages.isEmpty
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF0A9D88).withOpacity(0.05),
                        const Color(0xFF0A9D88).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.05),
                        Colors.green.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(
                color: _landProofImages.isEmpty
                    ? const Color(0xFF0A9D88).withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _landProofImages.isEmpty ? Icons.add_photo_alternate : Icons.check_circle,
                    key: ValueKey(_landProofImages.isEmpty),
                    size: 48,
                    color: _landProofImages.isEmpty
                        ? const Color(0xFF0A9D88)
                        : Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _landProofImages.isEmpty
                      ? 'Land Proof Images'
                      : '${_landProofImages.length} Image(s) Added',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _landProofImages.isEmpty
                        ? Colors.grey[700]
                        : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A9D88),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A9D88).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _landProofImages.isEmpty ? 'Add Land Images' : 'Add More Images',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        if (_landProofImages.isNotEmpty) ...[
          const Text(
            'Selected Land Images:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _landProofImages.length,
              itemBuilder: (context, index) {
                final image = _landProofImages[index];
                return Hero(
                  tag: 'land_image_$index',
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            image,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeLandProofImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Image ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Please upload the following documents:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: widget.scheme.requiredDocuments.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0A9D88),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ),
        ),

        const SizedBox(height: 20),

        GestureDetector(
          onTap: _pickDocuments,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: _selectedDocuments.isEmpty
                  ? LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.05),
                        Colors.blue.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.05),
                        Colors.green.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(
                color: _selectedDocuments.isEmpty
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _selectedDocuments.isEmpty ? Icons.cloud_upload : Icons.check_circle,
                    key: ValueKey(_selectedDocuments.isEmpty),
                    size: 48,
                    color: _selectedDocuments.isEmpty ? Colors.blue : Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedDocuments.isEmpty
                      ? 'Upload Documents'
                      : '${_selectedDocuments.length} Document(s) Added',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedDocuments.isEmpty
                        ? Colors.grey[700]
                        : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _selectedDocuments.isEmpty ? 'Choose Files' : 'Add More Files',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        if (_selectedDocuments.isNotEmpty) ...[
          const Text(
            'Selected Documents:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedDocuments.length,
              itemBuilder: (context, index) {
                final file = _selectedDocuments[index];
                final fileName = file.path.split('/').last;
                final fileSize = (file.lengthSync() / 1024).toStringAsFixed(1);
                final fileExtension = fileName.split('.').last.toUpperCase();

                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0A9D88).withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getFileTypeColor(fileExtension).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getFileTypeIcon(fileExtension),
                            color: _getFileTypeColor(fileExtension),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getFileTypeColor(fileExtension),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      fileExtension,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$fileSize KB',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _removeDocument(index),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Color _getFileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }

  Widget _buildSubmitButton() {
    final allCompleted = _sectionCompletion.values.every((v) => v);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: MediaQuery.of(context).size.width - 32,
      height: _isSubmitting ? 60 : 56,
      child: _isSubmitting ? _buildSubmissionProgress() : _buildNormalButton(allCompleted),
    );
  }

  Widget _buildNormalButton(bool allCompleted) {
    return ElevatedButton(
      onPressed: allCompleted && !_isSubmitting ? _submitApplication : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: allCompleted ? const Color(0xFF0A9D88) : Colors.grey[400],
        foregroundColor: Colors.white,
        elevation: allCompleted ? 8 : 0,
        shadowColor: const Color(0xFF0A9D88).withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            allCompleted ? Icons.send : Icons.incomplete_circle,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            allCompleted ? 'SUBMIT APPLICATION' : 'COMPLETE ALL SECTIONS',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionProgress() {
    return Container(
      constraints: BoxConstraints(
        minHeight: 60,
        maxHeight: 80,
        maxWidth: MediaQuery.of(context).size.width - 32,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A9D88),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A9D88).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: _submissionProgress,
              strokeWidth: 3,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(_submissionProgress * 100).toInt()}% Complete',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _submissionStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDocuments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _selectedDocuments.addAll(
            result.paths.map((path) => File(path!)).toList(),
          );
        });
        _updateSectionCompletion('documents');
        _showSuccessMessage('${result.files.length} document(s) added successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Error picking files: $e');
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _selectedDocuments.removeAt(index);
    });
    _updateSectionCompletion('documents');
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDocuments.isEmpty) {
      _showErrorSnackBar('Please upload at least one document');
      return;
    }

    if (_landProofImages.isEmpty) {
      _showErrorSnackBar('Please upload at least one land proof image');
      return;
    }

    if (!_isSurveyNumberValid) {
      _showErrorSnackBar('Please enter a valid survey number');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionProgress = 0.0;
      _submissionStatus = 'Preparing application...';
    });

    try {
      // Simulate progress steps
      await _updateProgress(0.1, 'Validating information...');
      await Future.delayed(const Duration(milliseconds: 800));

      await _updateProgress(0.3, 'Uploading documents...');
      await Future.delayed(const Duration(milliseconds: 1000));

      await _updateProgress(0.6, 'Uploading land proof images...');
      await Future.delayed(const Duration(milliseconds: 800));

      await _updateProgress(0.8, 'Submitting to authorities...');

      final applicationData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'surveyNumber': _surveyNumberController.text,
        'landAddress': _addressController.text,
        'farmSize': _farmSizeController.text,
        'cropTypes': _cropTypesController.text,
        'bankAccount': _bankAccountController.text,
        'ifscCode': _ifscController.text,
        'aadharNumber': _aadharController.text,
        'submittedAt': DateTime.now().toIso8601String(),
        'surveyData': _selectedSurveyData != null ? {
          'district': _selectedSurveyData!.district,
          'town': _selectedSurveyData!.town,
          'village': _selectedSurveyData!.village,
          'areaInCents': _selectedSurveyData!.areaInCents,
        } : null,
      };

      final userId = SessionManager.instance.getCurrentUserId()!;

      await _schemeService.submitApplication(
        userId: userId,
        schemeId: widget.scheme.id,
        schemeName: widget.scheme.name,
        applicationData: applicationData,
        documents: _selectedDocuments,
        landProofImages: _landProofImages,
      );

      await _updateProgress(1.0, 'Application submitted successfully!');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildSuccessDialog(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionProgress = 0.0;
          _submissionStatus = '';
        });
        _showErrorSnackBar('Error submitting application: $e');
      }
    }
  }

  Future<void> _updateProgress(double progress, String status) async {
    if (mounted) {
      setState(() {
        _submissionProgress = progress;
        _submissionStatus = status;
      });
    }
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Application Submitted!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your application for ${widget.scheme.name} has been submitted successfully. You will receive updates on your registered email.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onApplicationSubmitted();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF0A9D88)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Applications',
                      style: TextStyle(
                        color: Color(0xFF0A9D88),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onApplicationSubmitted();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A9D88),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _farmLocationController.dispose();
    _farmSizeController.dispose();
    _cropTypesController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _aadharController.dispose();
    _surveyNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}