import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SellProduce extends StatefulWidget {
  const SellProduce({super.key});

  @override
  State<SellProduce> createState() => _SellProduceState();
}

class _SellProduceState extends State<SellProduce>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();
  
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _submitController;
  late AnimationController _progressController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _submitAnimation;
  late Animation<double> _progressAnimation;
  
  // Form controllers
  final _productNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  
  // Form focus nodes
  final _productNameFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _contactFocus = FocusNode();
  
  String _selectedCategory = 'Vegetables';
  String _selectedUnit = 'kg';
  String _selectedCondition = 'Fresh';
  String _selectedDelivery = 'Pickup Only';
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isImageLoading = false;
  bool _organicCertified = false;
  bool _bulkDiscountAvailable = false;
  int _currentStep = 0;
  double _uploadProgress = 0.0;
  
  final PageController _pageController = PageController();
  
  final List<String> _categories = [
    'Vegetables', 'Fruits', 'Grains', 'Seeds', 'Herbs', 'Dairy', 
    'Spices', 'Nuts', 'Legumes', 'Other'
  ];
  
  final List<String> _units = [
    'kg', 'grams', 'tons', 'pieces', 'bunches', 'bags', 'liters', 'dozens'
  ];
  
  final List<String> _conditions = [
    'Fresh', 'Organic', 'Premium', 'Standard', 'Bulk'
  ];
  
  final List<String> _deliveryOptions = [
    'Pickup Only', 'Local Delivery', 'Shipping Available', 'Both Pickup & Delivery'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _setupFormListeners();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _submitController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3), 
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _submitAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _submitController, curve: Curves.easeInOut),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }
  
  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }
  
  void _setupFormListeners() {
    _productNameController.addListener(_updateFormProgress);
    _priceController.addListener(_updateFormProgress);
    _quantityController.addListener(_updateFormProgress);
    _descriptionController.addListener(_updateFormProgress);
    _locationController.addListener(_updateFormProgress);
  }
  
  void _updateFormProgress() {
    setState(() {
      // Update progress based on filled fields
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _submitController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    
    _productNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    
    _productNameFocus.dispose();
    _priceFocus.dispose();
    _quantityFocus.dispose();
    _descriptionFocus.dispose();
    _locationFocus.dispose();
    _contactFocus.dispose();
    
    super.dispose();
  }
  
  double get _formCompletionPercentage {
    int filledFields = 0;
    int totalFields = 6;
    
    if (_productNameController.text.isNotEmpty) filledFields++;
    if (_priceController.text.isNotEmpty) filledFields++;
    if (_quantityController.text.isNotEmpty) filledFields++;
    if (_descriptionController.text.isNotEmpty) filledFields++;
    if (_locationController.text.isNotEmpty) filledFields++;
    if (_selectedImages.isNotEmpty) filledFields++;
    
    return filledFields / totalFields;
  }
  
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      _showSnackBar('Maximum 5 images allowed', isError: true);
      return;
    }
    
    setState(() {
      _isImageLoading = true;
    });
    
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        List<File> newImages = [];
        for (XFile image in images.take(5 - _selectedImages.length)) {
          newImages.add(File(image.path));
        }
        
        // Simulate upload progress
        for (int i = 0; i <= 100; i += 10) {
          await Future.delayed(const Duration(milliseconds: 50));
          setState(() {
            _uploadProgress = i / 100.0;
          });
        }
        
        setState(() {
          _selectedImages.addAll(newImages);
          _uploadProgress = 0.0;
        });
        
        HapticFeedback.lightImpact();
        _showSnackBar('${newImages.length} image(s) added successfully!');
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e', isError: true);
    } finally {
      setState(() {
        _isImageLoading = false;
      });
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    HapticFeedback.selectionClick();
  }
  
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }
    
    if (_selectedImages.isEmpty) {
      _showSnackBar('Please add at least one product image', isError: true);
      return;
    }
    
    _submitController.forward().then((_) {
      _submitController.reverse();
    });
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate submission progress
    _progressController.forward();
    
    try {
      // Simulate network delay with progress updates
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _uploadProgress = i / 100.0;
          });
        }
      }
      
      // Create product data
      final productData = {
        'name': _productNameController.text.trim(),
        'category': _selectedCategory,
        'condition': _selectedCondition,
        'price': double.parse(_priceController.text),
        'quantity': double.parse(_quantityController.text),
        'unit': _selectedUnit,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'contactInfo': _contactController.text.trim(),
        'deliveryOptions': _selectedDelivery,
        'organicCertified': _organicCertified,
        'bulkDiscountAvailable': _bulkDiscountAvailable,
        'sellerId': 'current_user_id',
        'sellerName': 'Farm Class Seeds Ltd.',
        'imageCount': _selectedImages.length,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'available',
        'views': 0,
        'likes': 0,
        'featured': false,
        'averageRating': 0.0,
        'totalReviews': 0,
      };
      
      // Add to Firestore
      await _firestore.collection('products').add(productData);
      
      HapticFeedback.heavyImpact();
      _showSuccessDialog();
      
    } catch (e) {
      _showSnackBar('Error listing product: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0.0;
      });
      _progressController.reset();
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A9D88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF0A9D88),
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your product has been listed successfully! Buyers in your area will now be able to see and purchase your produce.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A5568),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _clearForm();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0A9D88)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add Another',
                        style: TextStyle(color: Color(0xFF0A9D88)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacementNamed(context, '/markets');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A9D88),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Markets',
                        style: TextStyle(color: Colors.white),
                      ),
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
  
  void _clearForm() {
    _productNameController.clear();
    _priceController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _contactController.clear();
    
    setState(() {
      _selectedImages.clear();
      _selectedCategory = 'Vegetables';
      _selectedUnit = 'kg';
      _selectedCondition = 'Fresh';
      _selectedDelivery = 'Pickup Only';
      _organicCertified = false;
      _bulkDiscountAvailable = false;
      _currentStep = 0;
    });
    
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : const Color(0xFF0A9D88),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white70,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildProgressIndicator(),
                    _buildFormContent(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0A9D88),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Sell Your Produce',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A9D88),
                const Color(0xFF0A9D88).withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 40,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                right: 40,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: _showHelpDialog,
        ),
        IconButton(
          icon: const Icon(Icons.preview, color: Colors.white),
          onPressed: _showPreview,
        ),
      ],
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Form Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                '${(_formCompletionPercentage * 100).round()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A9D88),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _formCompletionPercentage,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A9D88)),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFormContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildProductDetailsSection(),
            const SizedBox(height: 20),
            _buildPricingSection(),
            const SizedBox(height: 20),
            _buildLocationSection(),
            const SizedBox(height: 20),
            _buildAdditionalOptionsSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageSection() {
    return _buildAnimatedCard(
      title: '📸 Product Photos',
      subtitle: 'Add up to 5 high-quality images',
      child: Column(
        children: [
          if (_isImageLoading) ...[
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A9D88)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Processing images...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (_uploadProgress > 0) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A9D88)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return _buildAddImageCard();
                    }
                    return _buildImageCard(_selectedImages[index], index);
                  },
                ),
              ),
            ] else ...[
              _buildAddImagePlaceholder(),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildImageCard(File image, int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0A9D88), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                image,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A9D88),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Main',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAddImageCard() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF0A9D88).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF0A9D88),
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: Color(0xFF0A9D88),
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                color: Color(0xFF0A9D88),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddImagePlaceholder() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A9D88).withOpacity(0.1),
                const Color(0xFF0A9D88).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0A9D88),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: Color(0xFF0A9D88),
              ),
              SizedBox(height: 12),
              Text(
                'Tap to add product photos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A9D88),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Add multiple angles and close-ups',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A5568),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProductDetailsSection() {
    return _buildAnimatedCard(
      title: '🌱 Product Details',
      subtitle: 'Tell buyers about your produce',
      child: Column(
        children: [
          _buildEnhancedTextField(
            controller: _productNameController,
            focusNode: _productNameFocus,
            label: 'Product Name',
            hint: 'e.g., Fresh Organic Tomatoes',
            prefixIcon: Icons.local_florist,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter product name';
              }
              if (value.trim().length < 3) {
                return 'Name must be at least 3 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildEnhancedDropdown(
                      label: 'Category',
                      value: _selectedCategory,
                      items: _categories,
                      prefixIcon: Icons.category,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue!;
                        });
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEnhancedDropdown(
                      label: 'Condition',
                      value: _selectedCondition,
                      items: _conditions,
                      prefixIcon: Icons.grade,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCondition = newValue!;
                        });
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildEnhancedTextField(
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            label: 'Description',
            hint: 'Describe quality, variety, farming methods, etc.',
            prefixIcon: Icons.description,
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter product description';
              }
              if (value.trim().length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildCertificationToggles(),
        ],
      ),
    );
  }
  
  Widget _buildCertificationToggles() {
    return Column(
      children: [
        _buildToggleOption(
          title: 'Organic Certified',
          subtitle: 'Product has organic certification',
          value: _organicCertified,
          icon: Icons.eco,
          onChanged: (bool value) {
            setState(() {
              _organicCertified = value;
            });
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 12),
        _buildToggleOption(
          title: 'Bulk Discount Available',
          subtitle: 'Offer discounts for large orders',
          value: _bulkDiscountAvailable,
          icon: Icons.local_offer,
          onChanged: (bool value) {
            setState(() {
              _bulkDiscountAvailable = value;
            });
            HapticFeedback.selectionClick();
          },
        ),
      ],
    );
  }
  
  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? const Color(0xFF0A9D88).withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFF0A9D88) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? const Color(0xFF0A9D88) : Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value ? const Color(0xFF0A9D88) : const Color(0xFF2D3748),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0A9D88),
            activeTrackColor: const Color(0xFF0A9D88).withOpacity(0.3),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPricingSection() {
    return _buildAnimatedCard(
      title: '💰 Pricing & Quantity',
      subtitle: 'Set competitive prices',
      child: Column(
        children: [
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildEnhancedTextField(
                      controller: _quantityController,
                      focusNode: _quantityFocus,
                      label: 'Quantity Available',
                      hint: '100',
                      prefixIcon: Icons.inventory,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter quantity';
                        }
                        final num = double.tryParse(value);
                        if (num == null || num <= 0) {
                          return 'Invalid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEnhancedDropdown(
                      label: 'Unit',
                      value: _selectedUnit,
                      items: _units,
                      prefixIcon: Icons.straighten,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedUnit = newValue!;
                        });
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildEnhancedTextField(
            controller: _priceController,
            focusNode: _priceFocus,
            label: 'Price per $_selectedUnit (\$)',
            hint: '25.00',
            prefixIcon: Icons.attach_money,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter price';
              }
              final price = double.tryParse(value);
              if (price == null || price <= 0) {
                return 'Please enter valid price';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          if (_priceController.text.isNotEmpty && _quantityController.text.isNotEmpty)
            _buildPriceSummary(),
        ],
      ),
    );
  }
  
  Widget _buildPriceSummary() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final total = price * quantity;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A9D88).withOpacity(0.1),
            const Color(0xFF0A9D88).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0A9D88).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              Icon(
                Icons.calculate,
                color: const Color(0xFF0A9D88),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Per $_selectedUnit:', style: TextStyle(color: Colors.grey[600])),
              Text('\${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Quantity:', style: TextStyle(color: Colors.grey[600])),
              Text('${quantity.toStringAsFixed(0)} $_selectedUnit', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Value:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                '\${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A9D88),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationSection() {
    return _buildAnimatedCard(
      title: '📍 Location & Contact',
      subtitle: 'Where buyers can find you',
      child: Column(
        children: [
          _buildEnhancedTextField(
            controller: _locationController,
            focusNode: _locationFocus,
            label: 'Farm/Pickup Location',
            hint: 'City, State or detailed address',
            prefixIcon: Icons.location_on,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter location';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildEnhancedTextField(
            controller: _contactController,
            focusNode: _contactFocus,
            label: 'Contact Information',
            hint: 'Phone number or email',
            prefixIcon: Icons.contact_phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter contact info';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildEnhancedDropdown(
            label: 'Delivery Options',
            value: _selectedDelivery,
            items: _deliveryOptions,
            prefixIcon: Icons.local_shipping,
            onChanged: (String? newValue) {
              setState(() {
                _selectedDelivery = newValue!;
              });
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdditionalOptionsSection() {
    return _buildAnimatedCard(
      title: '⚙️ Additional Options',
      subtitle: 'Extra details for buyers',
      child: Column(
        children: [
          _buildInfoCard(
            'Listing Tips',
            [
              'Use natural lighting for photos',
              'Show different angles of your produce',
              'Include harvest date if recent',
              'Mention any unique growing methods',
              'Be responsive to buyer inquiries',
            ],
            Icons.lightbulb_outline,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Safety Guidelines',
            [
              'Meet in safe, public locations',
              'Verify buyer identity when possible',
              'Keep records of transactions',
              'Follow local food safety regulations',
            ],
            Icons.security,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, List<String> tips, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          iconColor: const Color(0xFF0A9D88),
          collapsedIconColor: Colors.grey[400],
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [child],
        ),
      ),
    );
  }
  
  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF0A9D88)),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0A9D88), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onTap: () {
            HapticFeedback.selectionClick();
          },
        ),
      ],
    );
  }
  
  Widget _buildEnhancedDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData prefixIcon,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF0A9D88)),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0A9D88), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Uploading...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          '${(_uploadProgress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A9D88),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A9D88)),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
            ],
            ScaleTransition(
              scale: _submitAnimation,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A9D88),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _isLoading ? 0 : 4,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Publishing...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.publish,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Publish Listing',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A9D88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Color(0xFF0A9D88),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selling Tips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 16),
               Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HelpTip(
                    icon: Icons.photo_camera,
                    title: 'High-Quality Photos',
                    description: 'Use natural lighting and show multiple angles',
                  ),
                  _HelpTip(
                    icon: Icons.description,
                    title: 'Detailed Descriptions',
                    description: 'Include variety, quality, and farming methods',
                  ),
                  _HelpTip(
                    icon: Icons.price_check,
                    title: 'Competitive Pricing',
                    description: 'Research market prices in your area',
                  ),
                  _HelpTip(
                    icon: Icons.schedule,
                    title: 'Quick Responses',
                    description: 'Reply to buyer inquiries within 24 hours',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A9D88),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showPreview() {
    if (_productNameController.text.isEmpty) {
      _showSnackBar('Please enter product name to preview', isError: true);
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: _buildPreviewCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPreviewCard() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Image
          if (_selectedImages.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.file(
                _selectedImages.first,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('No image added', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name & Category
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _productNameController.text.isEmpty 
                            ? 'Product Name' 
                            : _productNameController.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A9D88).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedCategory,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0A9D88),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Price & Quantity
                Row(
                  children: [
                    Text(
                      '\${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A9D88),
                      ),
                    ),
                    Text(
                      ' per $_selectedUnit',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${quantity.toStringAsFixed(0)} $_selectedUnit available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Condition & Certifications
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedCondition,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_organicCertified) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const _HelpTip(
                          icon: Icons.eco,
                          title: 'Organic Certified',
                          description: 'Product has organic certification',
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  _descriptionController.text.isEmpty
                      ? 'Product Description'
                      : _descriptionController.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),

                const SizedBox(height: 12),

                // Location & Contact
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red[400], size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _locationController.text.isEmpty
                            ? 'Location not specified'
                            : _locationController.text,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.contact_phone, color: Colors.blue[400], size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _contactController.text.isEmpty
                            ? 'Contact info not specified'
                            : _contactController.text,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.orange[400], size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _selectedDelivery,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _HelpTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpTip({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: description,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.green[700],
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
    
