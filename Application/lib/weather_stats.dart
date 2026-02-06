import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class WeatherStatsSection extends StatefulWidget {
  final String? farmerLocation; // From farmer profile
  
  const WeatherStatsSection({
    Key? key,
    this.farmerLocation,
  }) : super(key: key);

  @override
  State<WeatherStatsSection> createState() => _WeatherStatsSectionState();
}

class _WeatherStatsSectionState extends State<WeatherStatsSection>
    with TickerProviderStateMixin {
  
  // Google Weather API Configuration
  // ignore: unused_field
  static const String _apiKey = 'AIzaSyAVcz0-ooE0MkmCkpDaigolWtI4By8NSHc'; // Replace with actual Google API key
  // ignore: unused_field
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  
  // Animation Controllers
  late AnimationController _loadingController;
  late AnimationController _cardController;
  late AnimationController _carouselController;
  late AnimationController _statsController;
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  
  // Animations
  late Animation<double> _waveAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _statsSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  
  // State Variables
  WeatherStatsData? _weatherData;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String? _loadingMessage;
  int _currentAdvisoryIndex = 0;
  int _loadingStep = 0;
  PageController _pageController = PageController();
  Timer? _carouselTimer;
  Timer? _loadingTimer;
  List<WeatherAdvisory> _unreadNotifications = [];
  bool _isExpanded = false;
  bool _hasInitialized = false;
  
  // Static cache to persist across widget rebuilds
  static WeatherStatsData? _staticCache;
  static DateTime? _staticCacheTime;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
    _startCarousel();
  }
  
  void _initializeData() {
    // Check if we have static cache first
    if (_staticCache != null && _staticCacheTime != null && !_isCacheExpired(_staticCacheTime!)) {
      setState(() {
        _weatherData = _staticCache;
        _hasInitialized = true;
      });
      // Ensure animations are properly set
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cardController.forward();
        _headerController.forward();
        _statsController.forward();
      });
      return;
    }
    
    // Load data asynchronously
    _loadWeatherDataSafe();
  }
  
  void _loadWeatherDataSafe() async {
    try {
      await _loadWeatherData();
    } catch (e) {
      print('Error loading weather data: $e');
      // Load mock data as fallback
      final mockData = _getMockWeatherData('Default Location');
      setState(() {
        _weatherData = mockData;
        _hasInitialized = true;
        _isLoading = false;
        _error = null;
      });
      _stopAllAnimations();
      _cardController.forward();
      _headerController.forward();
      _statsController.forward();
    }
  }
  
  void _initializeAnimations() {
    // Loading animation
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Card entrance animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Carousel animation
    _carouselController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    // Stats animation
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Header animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Initialize animations
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOutSine,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.4, 1.0, curve: Curves.bounceOut),
    ));
    
    _statsSlideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.elasticOut,
    ));
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeInOut,
    ));
    
  _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05, // Reduced from 1.1 to 1.05 to prevent extreme values
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0, // Reduced from 2.0 to 1.0
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_weatherData?.advisories.isNotEmpty == true && mounted && !_isExpanded) {
        _nextAdvisory();
      }
    });
  }
  
  void _nextAdvisory() {
    if (_weatherData?.advisories.isEmpty == true) return;
    
    setState(() {
      _currentAdvisoryIndex = 
          (_currentAdvisoryIndex + 1) % _weatherData!.advisories.length;
    });
    
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _currentAdvisoryIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }
  
  void _startLoadingSequence() {
    final messages = [
      'Connecting to weather services...',
      'Fetching real-time data...',
      'Analyzing crop conditions...',
      'Generating recommendations...',
      'Almost ready...',
    ];
    
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_loadingStep < messages.length && mounted) {
        setState(() {
          _loadingMessage = messages[_loadingStep];
          _loadingStep++;
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  Future<void> _loadWeatherData({bool isRefresh = false, bool forceNetwork = false}) async {
    try {
      if (isRefresh) {
        setState(() => _isRefreshing = true);
        _pulseController.repeat(reverse: true);
      } else if (!_hasInitialized) {
        setState(() {
          _isLoading = true;
          _error = null;
          _loadingStep = 0;
          _loadingMessage = 'Loading weather data...';
        });
        _loadingController.repeat();
        _shimmerController.repeat();
        _startLoadingSequence();
      }

      // Check cached data first (unless forcing network)
      if (!forceNetwork && !isRefresh && !_hasInitialized) {
        final cachedData = await _getCachedWeatherData();
        if (cachedData != null && !_isCacheExpired(cachedData.timestamp)) {
          _staticCache = cachedData;
          _staticCacheTime = cachedData.timestamp;
          await _displayWeatherData(cachedData);
          return;
        }
      }

      // Get location
      String location;
      try {
        location = widget.farmerLocation ?? await _getCurrentLocation();
      } catch (e) {
        location = 'New Delhi,India'; // Fallback location
      }

      // Fetch weather data
      WeatherStatsData weatherData;
      try {
        weatherData = await _fetchWeatherData(location);
      } catch (e) {
        print('Network fetch failed, using mock data: $e');
        weatherData = _getMockWeatherData(location);
      }

      // Cache the data
      try {
        await _cacheWeatherData(weatherData);
        _staticCache = weatherData;
        _staticCacheTime = weatherData.timestamp;
      } catch (e) {
        print('Failed to cache data: $e');
      }

      await _displayWeatherData(weatherData);
      
    } catch (e) {
      print('Error in _loadWeatherData: $e');
      // Fallback to mock data
      final mockData = _getMockWeatherData('Default Location');
      await _displayWeatherData(mockData);
    }
  }
  
  Future<void> _displayWeatherData(WeatherStatsData data) async {
    if (!mounted) return;
    
    setState(() {
      _weatherData = data;
      _isLoading = false;
      _isRefreshing = false;
      _hasInitialized = true;
      _error = null;
    });
    
    _stopAllAnimations();
    
    // Ensure animations are ready and run them
    try {
      if (!_headerController.isCompleted) {
        await _headerController.forward();
      }
      if (!_cardController.isCompleted) {
        await _cardController.forward();
      }
      if (!_statsController.isCompleted) {
        await _statsController.forward();
      }
    } catch (e) {
      print('Animation error: $e');
      // Reset animation controllers if there's an error
      _headerController.reset();
      _cardController.reset();
      _statsController.reset();
      _headerController.forward();
      _cardController.forward();
      _statsController.forward();
    }
  }
  
  void _stopAllAnimations() {
    _loadingController.stop();
    _loadingController.reset();
    _shimmerController.stop();
    _shimmerController.reset();
    _pulseController.stop();
    _pulseController.reset();
    _loadingTimer?.cancel();
  }
  
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('location')) {
      return 'Unable to access location. Please enable location services.';
    } else if (error.toString().contains('network') || error.toString().contains('http')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
  
  Future<String> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }
      
      Position position = await Geolocator.getCurrentPosition();
      return '${position.latitude},${position.longitude}';
      
    } catch (e) {
      // Fallback to default location
      return 'New Delhi,India';
    }
  }
  
  Future<WeatherStatsData> _fetchWeatherData(String location) async {
    // Parse location if it's coordinates
    List<String> coords = location.split(',');
    String lat = coords.length > 1 ? coords[0] : '28.7041'; // Default to Delhi
    String lng = coords.length > 1 ? coords[1] : '77.1025';
    
    // Use Google Places API with weather data from a weather service
    final weatherUrl = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&appid=aefb1af4d2aef6a4ad25eb01736f19c2&units=metric';
    
    try {
      final response = await http.get(Uri.parse(weatherUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherStatsData.fromJson(data);
      } else {
        // Fallback to mock data if API fails
        return _getMockWeatherData(location);
      }
    } catch (e) {
      // Return mock data on error
      return _getMockWeatherData(location);
    }
  }
  
  WeatherStatsData _getMockWeatherData(String location) {
    // Mock weather data for demonstration
    final conditions = ['sunny', 'cloudy', 'rainy', 'clear'];
    final random = Random();
    
    return WeatherStatsData(
      location: location.contains(',') ? 'Current Location' : location,
      temperature: 25.0 + random.nextDouble() * 15, // 25-40°C
      condition: conditions[random.nextInt(conditions.length)],
      humidity: 40.0 + random.nextDouble() * 40, // 40-80%
      windSpeed: 5.0 + random.nextDouble() * 15, // 5-20 km/h
      advisories: _generateMockAdvisories(),
      timestamp: DateTime.now(),
    );
  }
  
  List<WeatherAdvisory> _generateMockAdvisories() {
    return [
      WeatherAdvisory(
        title: 'Morning Irrigation',
        message: 'Optimal time for watering crops is early morning between 6-8 AM.',
        icon: Icons.water_drop,
        priority: WeatherPriority.medium,
      ),
      WeatherAdvisory(
        title: 'Soil Moisture Check',
        message: 'Monitor soil moisture levels regularly to prevent water stress.',
        icon: Icons.grass,
        priority: WeatherPriority.low,
      ),
      WeatherAdvisory(
        title: 'Fertilizer Application',
        message: 'Current weather conditions are ideal for fertilizer application.',
        icon: Icons.eco,
        priority: WeatherPriority.medium,
      ),
      WeatherAdvisory(
        title: 'Pest Control',
        message: 'Moderate humidity levels - good time for pest management.',
        icon: Icons.pest_control,
        priority: WeatherPriority.high,
      ),
    ];
  }
  
  Future<WeatherStatsData?> _getCachedWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('weather_stats_data');
      
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final data = json.decode(cachedJson);
        return WeatherStatsData.fromCachedJson(data);
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
    return null;
  }
  
  Future<void> _cacheWeatherData(WeatherStatsData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('weather_stats_data', json.encode(data.toJson()));
    } catch (e) {
      print('Error caching data: $e');
    }
  }
  
  bool _isCacheExpired(DateTime timestamp) {
    return DateTime.now().difference(timestamp).inMinutes > 30; // Cache for 30 minutes instead of 1 hour
  }
  
  // Clear static cache when needed
  static void clearCache() {
    _staticCache = null;
    _staticCacheTime = null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _getWeatherGradient(),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getThemeColor().withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
              spreadRadius: -2,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: _buildContent(),
      ),
    );
  }
  
  Widget _buildContent() {
    // Show loading state
    if (_isLoading && !_hasInitialized) {
      return _buildEnhancedLoadingWidget();
    }
    
    // Show error state
    if (_error != null && _weatherData == null) {
      return _buildEnhancedErrorWidget();
    }
    
    // Show weather content (always show if we have data, even with errors)
    if (_weatherData != null) {
      return _buildEnhancedWeatherContent();
    }
    
    // Fallback: show loading
    return _buildEnhancedLoadingWidget();
  }
  
  Widget _buildEnhancedLoadingWidget() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced loading animation
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: EnhancedWavePainter(
                      animationValue: _waveAnimation.value,
                      rings: 4,
                      dotCount: 12,
                    ),
                  ),
                  // Inner pulsing icon
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                      CurvedAnimation(
                        parent: _loadingController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_sync,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Animated loading message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              _loadingMessage ?? 'Loading weather data...',
              key: ValueKey(_loadingMessage),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          // Progress indicator
          Container(
            width: 200,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(200, 4),
                  painter: ShimmerProgressPainter(_shimmerAnimation.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedErrorWidget() {
    return Container(
      height: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated error icon
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_off,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Enhanced retry button
          ElevatedButton.icon(
            onPressed: () => _loadWeatherData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedWeatherContent() {
    if (_weatherData == null) return const SizedBox();
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildEnhancedWeatherHeader(),
              const SizedBox(height: 20),
              _buildEnhancedWeatherStats(),
              const SizedBox(height: 20),
              _buildEnhancedAdvisorySection(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEnhancedWeatherHeader() {
    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                // Animated weather icon
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 0.1,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _getWeatherIcon(),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Weather info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1000),
                            tween: Tween<double>(begin: 0, end: _weatherData!.temperature),
                            builder: (context, value, child) {
                              return Text(
                                '${value.toInt()}°C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Feels like ${(_weatherData!.temperature + 2).toInt()}°',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weatherData!.condition,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _weatherData!.location,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            children: [
              if (_unreadNotifications.isNotEmpty)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseAnimation.value - 1.0).clamp(-0.2, 0.2) * 0.3,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_unreadNotifications.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (_unreadNotifications.isNotEmpty) const SizedBox(width: 8),
              // Refresh button
              GestureDetector(
                onTap: () => _loadWeatherData(isRefresh: true, forceNetwork: true),
                child: AnimatedBuilder(
                  animation: _isRefreshing ? _pulseController : kAlwaysCompleteAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRefreshing ? _pulseAnimation.value : 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: _isRefreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 16,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnhancedWeatherStats() {
    return AnimatedBuilder(
      animation: _statsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _statsSlideAnimation.value),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEnhancedStatItem(
                icon: Icons.thermostat,
                value: '${_weatherData!.temperature.toInt()}°',
                label: 'Temperature',
                color: Colors.orange,
                delay: 0,
              ),
              _buildEnhancedStatItem(
                icon: Icons.water_drop,
                value: '${_weatherData!.humidity.toInt()}%',
                label: 'Humidity',
                color: Colors.blue,
                delay: 100,
              ),
              _buildEnhancedStatItem(
                icon: Icons.air,
                value: '${_weatherData!.windSpeed.toInt()}',
                unit: 'km/h',
                label: 'Wind Speed',
                color: Colors.green,
                delay: 200,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildEnhancedStatItem({
    required IconData icon,
    required String value,
    String unit = '',
    required String label,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.elasticOut,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unit.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          unit,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEnhancedAdvisorySection() {
    return Column(
      children: [
        // Section header with expand/collapse
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tips_and_updates,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Farming Recommendations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_weatherData!.advisories.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: _isExpanded ? 0.5 : 0,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Advisory content
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          height: _isExpanded ? null : 80,
          child: _isExpanded 
              ? _buildExpandedAdvisories()
              : _buildCarouselAdvisories(),
        ),
      ],
    );
  }
  
  Widget _buildCarouselAdvisories() {
    return Container(
      height: 80,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _weatherData!.advisories.length,
        onPageChanged: (index) {
          setState(() {
            _currentAdvisoryIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final advisory = _weatherData!.advisories[index];
          return _buildEnhancedAdvisoryCard(advisory, isCompact: true);
        },
      ),
    );
  }
  
  Widget _buildExpandedAdvisories() {
    return Column(
      children: [
        ...List.generate(_weatherData!.advisories.length, (index) {
          final advisory = _weatherData!.advisories[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.easeOutBack,
              builder: (context, animation, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - animation) * 30),
                  child: Opacity(
                    opacity: animation,
                    child: _buildEnhancedAdvisoryCard(advisory, isCompact: false),
                  ),
                );
              },
            ),
          );
        }),
        const SizedBox(height: 8),
        // Page indicators for collapsed view
        if (!_isExpanded)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _weatherData!.advisories.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentAdvisoryIndex ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentAdvisoryIndex 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildEnhancedAdvisoryCard(WeatherAdvisory advisory, {required bool isCompact}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: advisory.priorityColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: advisory.priorityColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Priority indicator and icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  advisory.priorityColor.withOpacity(0.3),
                  advisory.priorityColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: advisory.priorityColor.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(
              advisory.icon,
              color: Colors.white,
              size: isCompact ? 20 : 24,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        advisory.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 13 : 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: advisory.priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: advisory.priorityColor.withOpacity(0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        advisory.priority.name.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  advisory.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isCompact ? 11 : 13,
                    height: 1.3,
                  ),
                  maxLines: isCompact ? 2 : null,
                  overflow: isCompact ? TextOverflow.ellipsis : null,
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.white.withOpacity(0.7),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Updated ${_getTimeAgo(_weatherData!.timestamp)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
  
  Color _getThemeColor() {
    if (_weatherData == null) return Colors.blue;
    
    switch (_weatherData!.condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Colors.orange;
      case 'rainy':
      case 'rain':
        return Colors.indigo;
      case 'drizzle':
        return Colors.blueGrey;
      case 'cloudy':
      case 'clouds':
        return Colors.grey;
      case 'thunderstorm':
        return Colors.purple;
      case 'snow':
        return Colors.lightBlue;
      case 'mist':
      case 'fog':
      case 'haze':
        return Colors.blueGrey;
      default:
        return Colors.blue;
    }
  }
  
  LinearGradient _getWeatherGradient() {
    final color = _getThemeColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.9),
        color,
        color.withOpacity(0.8),
        color.withOpacity(0.9),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
  }
  
  IconData _getWeatherIcon() {
    if (_weatherData == null) return Icons.wb_sunny;
    
    switch (_weatherData!.condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'rainy':
      case 'rain':
        return Icons.grain;
      case 'drizzle':
        return Icons.grain;
      case 'cloudy':
      case 'clouds':
        return Icons.wb_cloudy;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.foggy;
      default:
        return Icons.wb_sunny;
    }
  }
  
  @override
  void dispose() {
    _loadingController.dispose();
    _cardController.dispose();
    _carouselController.dispose();
    _statsController.dispose();
    _headerController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _pageController.dispose();
    _carouselTimer?.cancel();
    _loadingTimer?.cancel();
    super.dispose();
  }
}

// Enhanced Custom Painters
class EnhancedWavePainter extends CustomPainter {
  final double animationValue;
  final int rings;
  final int dotCount;
  
  EnhancedWavePainter({
    required this.animationValue,
    this.rings = 3,
    this.dotCount = 8,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width / 2;
    
    // Draw multiple concentric dotted circles
    for (int i = 0; i < rings; i++) {
      final ringProgress = (animationValue + (i * 0.2)) % 1.0;
      final radius = (maxRadius / rings) * (i + 1) * ringProgress;
      final opacity = ((1.0 - ringProgress) * (1.0 - (i * 0.2))).clamp(0.0, 1.0);
      
      paint.color = Colors.white.withOpacity((opacity * 0.8).clamp(0.0, 1.0));
      
      // Draw dots around the circle
      for (int j = 0; j < dotCount; j++) {
        final angle = (j * (360 / dotCount)) * (pi / 180);
        final dotAngle = angle + (animationValue * 2 * pi * (i + 1));
        final x = centerX + radius * cos(dotAngle);
        final y = centerY + radius * sin(dotAngle);
        
        // Varying dot sizes
        final dotSize = (2 + (sin(animationValue * 2 * pi + j) * 1.5).abs()).clamp(1.0, 5.0);
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
    
    // Center pulse
    final pulseOpacity = (0.3 + (sin(animationValue * 4 * pi) * 0.2)).clamp(0.0, 1.0);
    paint.color = Colors.white.withOpacity(pulseOpacity);
    canvas.drawCircle(Offset(centerX, centerY), 6, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ShimmerProgressPainter extends CustomPainter {
  final double progress;
  
  ShimmerProgressPainter(this.progress);
  
  @override
  void paint(Canvas canvas, Size size) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(
        Rect.fromLTWH(
          clampedProgress * size.width - size.width * 0.3,
          0,
          size.width * 0.6,
          size.height,
        ),
      );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(2),
      ),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Enhanced Data Models
class WeatherStatsData {
  final String location;
  final double temperature;
  final String condition;
  final double humidity;
  final double windSpeed;
  final List<WeatherAdvisory> advisories;
  final DateTime timestamp;
  
  WeatherStatsData({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.advisories,
    required this.timestamp,
  });
  
  factory WeatherStatsData.fromJson(Map<String, dynamic> json) {
    final location = json['name'] ?? 'Unknown';
    final temp = (json['main']['temp'] as num).toDouble();
    final condition = json['weather'][0]['main'] as String;
    final humidity = (json['main']['humidity'] as num).toDouble();
    final windSpeed = (json['wind']['speed'] as num).toDouble();
    
    return WeatherStatsData(
      location: location,
      temperature: temp,
      condition: condition,
      humidity: humidity,
      windSpeed: windSpeed,
      advisories: _generateWeatherAdvisories(condition, temp, humidity, windSpeed),
      timestamp: DateTime.now(),
    );
  }
  
  // Separate method for cached data
  factory WeatherStatsData.fromCachedJson(Map<String, dynamic> json) {
    try {
      return WeatherStatsData(
        location: json['location'] ?? 'Unknown',
        temperature: (json['temperature'] as num).toDouble(),
        condition: json['condition'] ?? 'clear',
        humidity: (json['humidity'] as num).toDouble(),
        windSpeed: (json['windSpeed'] as num).toDouble(),
        advisories: (json['advisories'] as List?)?.map((a) => WeatherAdvisory.fromJson(a)).toList() ?? [],
        timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      print('Error parsing cached JSON: $e');
      // Return default data if parsing fails
      return WeatherStatsData(
        location: 'Default Location',
        temperature: 25.0,
        condition: 'clear',
        humidity: 60.0,
        windSpeed: 10.0,
        advisories: [],
        timestamp: DateTime.now(),
      );
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'temperature': temperature,
      'condition': condition,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'advisories': advisories.map((a) => a.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  static List<WeatherAdvisory> _generateWeatherAdvisories(
    String condition, 
    double temp, 
    double humidity, 
    double windSpeed
  ) {
    final advisories = <WeatherAdvisory>[];
    
    // Weather-based advisories with enhanced messaging
    switch (condition.toLowerCase()) {
      case 'rain':
      case 'rainy':
      case 'drizzle':
        advisories.addAll([
          WeatherAdvisory(
            title: 'Skip Irrigation Today',
            message: 'Natural rainfall is providing sufficient water. Suspend irrigation to prevent waterlogging and save resources.',
            icon: Icons.water_drop_outlined,
            priority: WeatherPriority.high,
          ),
          WeatherAdvisory(
            title: 'Monitor Field Drainage',
            message: 'Check drainage systems and ensure proper water flow to prevent crop damage from excess moisture.',
            icon: Icons.waves,
            priority: WeatherPriority.medium,
          ),
        ]);
        break;
        
      case 'sunny':
      case 'clear':
        if (temp > 30) {
          advisories.addAll([
            WeatherAdvisory(
              title: 'Increase Water Supply',
              message: 'High temperatures detected. Increase irrigation frequency and consider early morning watering.',
              icon: Icons.wb_sunny,
              priority: WeatherPriority.high,
            ),
            WeatherAdvisory(
              title: 'Heat Stress Protection',
              message: 'Deploy shade nets or protective covers for sensitive crops to prevent heat damage.',
              icon: Icons.umbrella,
              priority: WeatherPriority.medium,
            ),
          ]);
        } else {
          advisories.add(
            WeatherAdvisory(
              title: 'Optimal Field Conditions',
              message: 'Perfect weather for field operations, crop monitoring, and maintenance activities.',
              icon: Icons.wb_sunny,
              priority: WeatherPriority.low,
            ),
          );
        }
        break;
        
      case 'cloudy':
      case 'clouds':
        advisories.addAll([
          WeatherAdvisory(
            title: 'Ideal for Spraying',
            message: 'Overcast conditions reduce evaporation. Perfect time for pesticide and fertilizer application.',
            icon: Icons.pest_control,
            priority: WeatherPriority.medium,
          ),
          WeatherAdvisory(
            title: 'Schedule Field Work',
            message: 'Cool, comfortable conditions for extended outdoor farming activities and inspections.',
            icon: Icons.agriculture,
            priority: WeatherPriority.low,
          ),
        ]);
        break;
        
      case 'thunderstorm':
        advisories.addAll([
          WeatherAdvisory(
            title: 'Safety Alert - Stay Indoor',
            message: 'Severe weather conditions detected. Avoid all outdoor activities until storm passes.',
            icon: Icons.flash_on,
            priority: WeatherPriority.high,
          ),
          WeatherAdvisory(
            title: 'Secure Farm Equipment',
            message: 'Strong winds expected. Secure all loose equipment and protect vulnerable structures.',
            icon: Icons.security,
            priority: WeatherPriority.high,
          ),
        ]);
        break;
    }
    
    // Enhanced condition-based advisories
    if (temp > 35) {
      advisories.add(
        WeatherAdvisory(
          title: 'Heat Wave Emergency',
          message: 'Extreme heat detected (${temp.toInt()}°C). Implement emergency cooling measures and monitor crops hourly.',
          icon: Icons.thermostat,
          priority: WeatherPriority.high,
        ),
      );
    }
    
    if (temp < 10) {
      advisories.add(
        WeatherAdvisory(
          title: 'Frost Risk Alert',
          message: 'Temperature dropping to ${temp.toInt()}°C. Cover sensitive plants and consider frost protection methods.',
          icon: Icons.ac_unit,
          priority: WeatherPriority.high,
        ),
      );
    }
    
    if (humidity > 80) {
      advisories.add(
        WeatherAdvisory(
          title: 'High Humidity - Disease Risk',
          message: 'Humidity at ${humidity.toInt()}% increases fungal disease risk. Monitor plants closely and improve ventilation.',
          icon: Icons.healing,
          priority: WeatherPriority.medium,
        ),
      );
    }
    
    if (windSpeed > 15) {
      advisories.add(
        WeatherAdvisory(
          title: 'Strong Wind Warning',
          message: 'Winds at ${windSpeed.toInt()} km/h. Secure tall crops, postpone spraying, and check structural integrity.',
          icon: Icons.air,
          priority: WeatherPriority.medium,
        ),
      );
    }
    
    // Default advisory with actionable advice
    if (advisories.isEmpty) {
      advisories.add(
        WeatherAdvisory(
          title: 'Regular Crop Monitoring',
          message: 'Stable conditions detected. Conduct routine crop health checks and soil moisture assessments.',
          icon: Icons.visibility,
          priority: WeatherPriority.low,
        ),
      );
    }
    
    return advisories;
  }
}

class WeatherAdvisory {
  final String title;
  final String message;
  final IconData icon;
  final WeatherPriority priority;
  
  WeatherAdvisory({
    required this.title,
    required this.message,
    required this.icon,
    required this.priority,
  });
  
  Color get priorityColor {
    switch (priority) {
      case WeatherPriority.high:
        return Colors.red;
      case WeatherPriority.medium:
        return Colors.orange;
      case WeatherPriority.low:
        return Colors.green;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'icon': icon.codePoint,
      'priority': priority.toString(),
    };
  }
  
  factory WeatherAdvisory.fromJson(Map<String, dynamic> json) {
    return WeatherAdvisory(
      title: json['title'] ?? 'Advisory',
      message: json['message'] ?? 'No message',
      icon: IconData(json['icon'] ?? Icons.info.codePoint, fontFamily: 'MaterialIcons'),
      priority: WeatherPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => WeatherPriority.low,
      ),
    );
  }
}

enum WeatherPriority { high, medium, low }