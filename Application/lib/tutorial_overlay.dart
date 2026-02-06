import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:vfarm/l10n/app_localizations.dart';

// Global tutorial state manager
class TutorialState {
  static final TutorialState _instance = TutorialState._internal();
  factory TutorialState() => _instance;
  TutorialState._internal();

  VoidCallback? _onDrawerOpened;
  VoidCallback? _onVaultOpened;

  void registerDrawerCallback(VoidCallback callback) {
    _onDrawerOpened = callback;
  }

  void registerVaultCallback(VoidCallback callback) {
    _onVaultOpened = callback;
  }

  void notifyDrawerOpened() {
    _onDrawerOpened?.call();
  }

  void notifyVaultOpened() {
    _onVaultOpened?.call();
  }

  void clear() {
    _onDrawerOpened = null;
    _onVaultOpened = null;
  }
}

class TutorialManager {
  static const String _tutorialCompleteKey = 'tutorial_completed';

  static Future<bool> hasCompletedTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompleteKey) ?? false;
  }

  static Future<void> markTutorialComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompleteKey, true);
  }

  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialCompleteKey);
  }
}

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final GlobalKey drawerKey;
  final VoidCallback onOpenDrawer;
  final VoidCallback onNavigateToVault;
  final VoidCallback onNavigateToProfile;
  final int initialStep;

  const TutorialOverlay({
    Key? key,
    required this.onComplete,
    required this.drawerKey,
    required this.onOpenDrawer,
    required this.onNavigateToVault,
    required this.onNavigateToProfile,
    this.initialStep = 0,
  }) : super(key: key);

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late int _currentStep;
  bool _isVisible = true;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    TutorialState().clear();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep(int stepsLength) {
    if (_currentStep < stepsLength - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeTutorial();
    }
  }

  void _skipTutorial() {
    _completeTutorial();
  }

  Future<void> _completeTutorial() async {
    await TutorialManager.markTutorialComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Build localized steps
    final steps = [
      TutorialStep(
        title: localizations.tutorialWelcomeTitle,
        description: localizations.tutorialWelcomeDescription,
        targetType: TargetType.menuButton,
        arrowDirection: ArrowDirection.topLeft,
      ),
      TutorialStep(
        title: localizations.tutorialVaultTitle,
        description: localizations.tutorialVaultDescription,
        targetType: TargetType.vaultMenuItem,
        arrowDirection: ArrowDirection.left,
      ),
      TutorialStep(
        title: localizations.tutorialProfileTitle,
        description: localizations.tutorialProfileDescription,
        targetType: TargetType.profileIcon,
        arrowDirection: ArrowDirection.topRight,
      ),
    ];

    final step = steps[_currentStep];

    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Block all background interactions
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // Prevent taps on overlay
              },
              child: Container(color: Colors.transparent),
            ),
          ),

          // Tutorial content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated arrow pointing to target
                _buildArrow(step.arrowDirection),

                const SizedBox(height: 40),

                // Tutorial card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF149D80),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Progress indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          steps.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == _currentStep ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color:
                                  index == _currentStep
                                      ? const Color(0xFF149D80)
                                      : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _skipTutorial,
                            child: Text(
                              localizations.tutorialSkip,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (_currentStep == 0) {
                                // Call parent to open drawer
                                widget.onOpenDrawer();
                                // Move to next step after drawer opens
                                Future.delayed(
                                  const Duration(milliseconds: 400),
                                  () {
                                    if (mounted) {
                                      setState(() {
                                        _currentStep = 1;
                                      });
                                    }
                                  },
                                );
                              } else if (_currentStep == 1) {
                                // Call parent to navigate to My Vault
                                widget.onNavigateToVault();
                                // Move to next step after navigation
                                Future.delayed(
                                  const Duration(milliseconds: 800),
                                  () {
                                    if (mounted) {
                                      setState(() {
                                        _currentStep = 2;
                                      });
                                    }
                                  },
                                );
                              } else if (_currentStep == 2) {
                                // Navigate to edit profile page
                                widget.onNavigateToProfile();
                                // Complete tutorial after navigation
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                  () {
                                    _completeTutorial();
                                  },
                                );
                              } else {
                                _nextStep(steps.length);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF149D80),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              _currentStep == steps.length - 1
                                  ? localizations.tutorialGotIt
                                  : localizations.tutorialNext,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
          ),

          // Highlight target area based on step
          _buildHighlight(step.targetType),
        ],
      ),
    );
  }

  Widget _buildArrow(ArrowDirection direction) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: _getArrowRotation(direction),
            child: const Icon(
              Icons.arrow_upward,
              size: 60,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  double _getArrowRotation(ArrowDirection direction) {
    switch (direction) {
      case ArrowDirection.top:
        return 0;
      case ArrowDirection.right:
        return math.pi / 2;
      case ArrowDirection.bottom:
        return math.pi;
      case ArrowDirection.left:
        return -math.pi / 2;
      case ArrowDirection.topLeft:
        return -math.pi / 4;
      case ArrowDirection.topRight:
        return math.pi / 4;
    }
  }

  Widget _buildHighlight(TargetType targetType) {
    // This creates a spotlight effect on specific UI elements
    switch (targetType) {
      case TargetType.menuButton:
        return Positioned(top: 40, left: 16, child: _buildSpotlight(60, 60));
      case TargetType.vaultMenuItem:
        return const SizedBox.shrink(); // Drawer items highlighted separately
      case TargetType.profileIcon:
        // Highlight profile icon in app bar (top right)
        return Positioned(top: 40, right: 16, child: _buildSpotlight(60, 60));
    }
  }

  Widget _buildSpotlight(double width, double height) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 20 * _pulseAnimation.value,
                spreadRadius: 5 * _pulseAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final TargetType targetType;
  final ArrowDirection arrowDirection;

  TutorialStep({
    required this.title,
    required this.description,
    required this.targetType,
    required this.arrowDirection,
  });
}

enum TargetType { menuButton, vaultMenuItem, profileIcon }

enum ArrowDirection { top, right, bottom, left, topLeft, topRight }

// Widget to show tutorial on home screen
class TutorialWrapper extends StatefulWidget {
  final Widget child;
  final bool showTutorial;
  final VoidCallback? onTutorialComplete;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onNavigateToVault;
  final VoidCallback? onNavigateToProfile;
  final int initialStep;

  const TutorialWrapper({
    Key? key,
    required this.child,
    this.showTutorial = false,
    this.onTutorialComplete,
    this.onOpenDrawer,
    this.onNavigateToVault,
    this.onNavigateToProfile,
    this.initialStep = 0,
  }) : super(key: key);

  @override
  State<TutorialWrapper> createState() => _TutorialWrapperState();
}

class _TutorialWrapperState extends State<TutorialWrapper> {
  bool _showingTutorial = false;
  final GlobalKey _drawerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.showTutorial) {
      // Show tutorial after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showingTutorial = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showingTutorial)
          TutorialOverlay(
            drawerKey: _drawerKey,
            initialStep: widget.initialStep,
            onComplete: () {
              setState(() {
                _showingTutorial = false;
              });
              widget.onTutorialComplete?.call();
            },
            onOpenDrawer: () {
              widget.onOpenDrawer?.call();
            },
            onNavigateToVault: () {
              widget.onNavigateToVault?.call();
            },
            onNavigateToProfile: () {
              widget.onNavigateToProfile?.call();
            },
          ),
      ],
    );
  }
}

// Animated highlight for profile icon in MyVault
class TutorialProfileHighlight extends StatefulWidget {
  const TutorialProfileHighlight({Key? key}) : super(key: key);

  @override
  State<TutorialProfileHighlight> createState() =>
      _TutorialProfileHighlightState();
}

class _TutorialProfileHighlightState extends State<TutorialProfileHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.yellowAccent.withOpacity(0.8),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.yellowAccent.withOpacity(0.5),
                blurRadius: 15 * _animation.value,
                spreadRadius: 5 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
