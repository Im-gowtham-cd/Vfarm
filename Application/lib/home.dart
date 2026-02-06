import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vfarm/tutorial_overlay.dart';
import 'package:vfarm/Instant_services/FarmWorkers.dart';
import 'package:vfarm/Instant_services/Fertilizers.dart';
import 'package:vfarm/Instant_services/SoilTestingPage.dart';
import 'package:vfarm/chats/chats.dart';
import 'package:vfarm/community/community_service.dart';
import 'package:vfarm/community/create_post.dart';
import 'package:vfarm/models/community_post_model.dart';
import 'package:vfarm/models/notification_model.dart';
import 'package:vfarm/session_manager.dart';
import 'package:vfarm/Instant_services/training_page.dart';
import 'package:vfarm/l10n/app_localizations.dart';
import 'package:vfarm/weather_stats.dart';

class MainWrapper extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const MainWrapper({
    super.key,
    required this.child,
    required this.currentRoute,
    this.scaffoldKey,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  late final GlobalKey<ScaffoldState> _scaffoldKey;

  @override
  void initState() {
    super.initState();
    _scaffoldKey = widget.scaffoldKey ?? GlobalKey<ScaffoldState>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: ModernSideMenu(currentRoute: widget.currentRoute),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          // Notify tutorial that drawer was opened
          TutorialState().notifyDrawerOpened();
        }
      },
      body: widget.child,
      floatingActionButton:
          widget.currentRoute == '/home' ? _buildActivityFAB(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_getPageTitle(widget.currentRoute, context)),
      backgroundColor: const Color(0xFF0A9D88),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      ),
      actions: [
        _buildChatIcon(),
        const SizedBox(width: 8),
        _buildNotificationIcon(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildChatIcon() {
    return IconButton(
      icon: const Icon(Icons.chat_bubble_outline),
      onPressed: () => _navigateToChats(context),
    );
  }

  Widget _buildActivityFAB(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushNamed(context, '/dailyActivity');
      },
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.add_task, size: 24),
      label: Text(
        l10n.addActivity,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      tooltip: l10n.recordFarmActivity,
    );
  }

  void _navigateToChats(BuildContext context) {
    final session = SessionManager.instance;
    final currentUserId = session.getCurrentUserId();
    final currentUsername = session.getUsername();

    if (currentUserId == null || currentUsername == null) {
      // Optional: handle missing session
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sessionExpired)));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CommunityChatsPage(
              currentUserId: currentUserId,
              currentUsername: currentUsername,
            ),
      ),
    );
  }

  void _showNotificationPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.notifications,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A9D88),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _markAllAsRead(context),
                              child: Text(
                                l10n.markAllRead,
                                style: const TextStyle(
                                  color: Color(0xFF0A9D88),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Notifications list
                      Expanded(
                        child: _buildNotificationsList(
                          context,
                          scrollController,
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildNotificationIcon() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => _showNotificationPanel(context),
            ),
            // Notification badge
            if (_getUnreadNotificationCount(context) > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${_getUnreadNotificationCount(context)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Widget _buildNotificationsList(
  BuildContext context,
  ScrollController scrollController,
) {
  final l10n = AppLocalizations.of(context)!;
  final notifications = _getVFarmNotifications(context);

  if (notifications.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l10n.noNotificationsYet,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  return ListView.builder(
    controller: scrollController,
    itemCount: notifications.length,
    itemBuilder: (context, index) {
      final notification = notifications[index];
      return _buildNotificationItem(notification);
    },
  );
}

Widget _buildNotificationItem(VFarmNotification notification) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: notification.isRead ? Colors.white : const Color(0xFFF0F9F7),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color:
            notification.isRead
                ? Colors.grey[200]!
                : const Color(0xFF0A9D88).withOpacity(0.2),
      ),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: _getNotificationColor(notification.type),
        child: Icon(
          _getNotificationIcon(notification.type),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.message,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _formatNotificationTime(notification.timestamp),
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ],
      ),
      onTap: () => _onNotificationTap(notification),
      trailing:
          !notification.isRead
              ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A9D88),
                  shape: BoxShape.circle,
                ),
              )
              : null,
    ),
  );
}

// Helper methods for notifications
int _getUnreadNotificationCount(BuildContext context) {
  return _getVFarmNotifications(context).where((n) => !n.isRead).length;
}

List<VFarmNotification> _getVFarmNotifications(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  // Replace this with your actual notification data source
  return [
    VFarmNotification(
      id: '1',
      type: NotificationType.cropAlert,
      title: l10n.cropHealthAlert,
      message: l10n.cropAlertMessage,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    VFarmNotification(
      id: '2',
      type: NotificationType.weather,
      title: l10n.weatherUpdate,
      message: l10n.weatherUpdateMessage,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: false,
    ),
    VFarmNotification(
      id: '3',
      type: NotificationType.harvest,
      title: l10n.harvestReminder,
      message: l10n.harvestReminderMessage,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    VFarmNotification(
      id: '4',
      type: NotificationType.market,
      title: l10n.marketPriceUpdate,
      message: l10n.marketPriceMessage,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];
}

IconData _getNotificationIcon(NotificationType type) {
  switch (type) {
    case NotificationType.cropAlert:
      return Icons.warning;
    case NotificationType.weather:
      return Icons.cloud;
    case NotificationType.harvest:
      return Icons.agriculture;
    case NotificationType.market:
      return Icons.trending_up;
    case NotificationType.system:
      return Icons.info;
  }
}

Color _getNotificationColor(NotificationType type) {
  switch (type) {
    case NotificationType.cropAlert:
      return Colors.orange;
    case NotificationType.weather:
      return Colors.blue;
    case NotificationType.harvest:
      return Colors.green;
    case NotificationType.market:
      return Colors.purple;
    case NotificationType.system:
      return Colors.grey;
  }
}

String _formatNotificationTime(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else {
    return '${difference.inDays}d ago';
  }
}

void _onNotificationTap(VFarmNotification notification) {
  // Mark as read and handle navigation based on notification type
  notification.isRead = true;

  // Add your navigation logic here based on notification type
  switch (notification.type) {
    case NotificationType.cropAlert:
      // Navigate to crop management screen
      break;
    case NotificationType.weather:
      // Navigate to weather screen
      break;
    case NotificationType.harvest:
      // Navigate to harvest screen
      break;
    case NotificationType.market:
      // Navigate to market prices screen
      break;
    case NotificationType.system:
      // Handle system notifications
      break;
  }
}

void _markAllAsRead(BuildContext context) {
  final notifications = _getVFarmNotifications(context);
  for (var notification in notifications) {
    notification.isRead = true;
  }
  // Update your data source here
}

String _getPageTitle(String route, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  switch (route) {
    case '/home':
      return l10n.weAreYourFarmingPartner;
    case '/govtSchemes':
      return l10n.governmentSchemes;
    case '/searchSchemes':
      return l10n.searchSchemes;
    case '/bookService':
      return l10n.bookService;
    case '/markets':
      return l10n.markets;
    case '/askExpert':
      return l10n.askExpert;
    case '/myVault':
      return l10n.myVault;
    case '/settings':
      return l10n.settings;
    default:
      return l10n.appTitle;
  }
}

// ========== MODERN SIDE MENU ==========
class ModernSideMenu extends StatefulWidget {
  final String currentRoute;

  const ModernSideMenu({super.key, required this.currentRoute});

  @override
  State<ModernSideMenu> createState() => _ModernSideMenuState();
}

class _ModernSideMenuState extends State<ModernSideMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showTutorialHighlight = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final hasCompleted = await TutorialManager.hasCompletedTutorial();
    if (mounted) {
      setState(() {
        _showTutorialHighlight = !hasCompleted;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A9D88), Color(0xFF149D80)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildMenuItems(context)),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userProfile = SessionManager.instance.getCurrentUserProfile();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.white, Colors.green.shade50],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: ClipOval(
                // child: imageUrl != null && imageUrl.isNotEmpty
                //     ? Image.network(
                //         imageUrl,
                //         width: 60,
                //         height: 60,
                //         fit: BoxFit.cover,
                //         errorBuilder: (context, error, stackTrace) =>
                //             Image.asset('assets/finallogo.png', width: 60, height: 60),
                //       )
                child: Image.asset(
                  'assets/finallogo.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.vfarm,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            l10n.smartFarmingSolutions,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<MenuItemData> menuItems = [
      MenuItemData(Icons.dashboard_rounded, l10n.dashboard, '/home'),
      MenuItemData(
        Icons.account_balance,
        l10n.governmentSchemes,
        '/govtSchemes',
      ),
      MenuItemData(Icons.build_rounded, l10n.bookService, '/bookService'),
      MenuItemData(Icons.storefront_rounded, l10n.markets, '/markets'),
      MenuItemData(Icons.support_agent, l10n.askExpert, '/askExpert'),
      MenuItemData(Icons.folder_rounded, l10n.myVault, '/myVault'),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final isVaultItem = item.route == '/myVault';
        return Stack(
          children: [
            _buildMenuItem(
              context,
              icon: item.icon,
              title: item.title,
              route: item.route,
              isSelected: widget.currentRoute == item.route,
            ),
            // Tutorial highlight for My Vault
            if (isVaultItem && _showTutorialHighlight)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.yellowAccent.withOpacity(0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellowAccent.withOpacity(0.4),
                            blurRadius: 15 * _pulseAnimation.value,
                            spreadRadius: 3 * _pulseAnimation.value,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => _navigateToPage(context, route),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const Divider(color: Colors.white30, thickness: 0.5),
        _buildMenuItem(
          context,
          icon: Icons.settings_rounded,
          title: l10n.settings,
          route: '/settings',
          isSelected: widget.currentRoute == '/settings',
        ),
        ListTile(
          leading: const Icon(
            Icons.logout_rounded,
            color: Colors.white70,
            size: 22,
          ),
          title: Text(
            l10n.logout,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          onTap: () => _showLogoutDialog(context),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _navigateToPage(BuildContext context, String route) {
    Navigator.of(context).pop();
    if (widget.currentRoute != route) {
      // Notify tutorial if navigating to My Vault
      if (route == '/myVault') {
        TutorialState().notifyVaultOpened();
      }
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(l10n.logout),
            content: Text(l10n.logoutConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  try {
                    await SessionManager.instance.clearSession();
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  } catch (e) {
                    debugPrint('Logout error: $e');
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.logout),
              ),
            ],
          ),
    );
  }
}

class MenuItemData {
  final IconData icon;
  final String title;
  final String route;

  MenuItemData(this.icon, this.title, this.route);
}

// ========== HOME SCREEN ==========
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showTutorial = false;
  bool _isCheckingTutorial = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final hasCompleted = await TutorialManager.hasCompletedTutorial();
    setState(() {
      _showTutorial = !hasCompleted;
      _isCheckingTutorial = false;
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _navigateToVault() {
    // Close drawer first
    Navigator.of(context).pop();
    // Then navigate to vault
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.of(context).pushReplacementNamed('/myVault');
    });
  }

  void _navigateToProfile() {
    // Navigate to profile edit screen
    Navigator.of(context).pushNamed('/profileEdit');
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingTutorial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return TutorialWrapper(
      showTutorial: _showTutorial,
      onTutorialComplete: () {
        setState(() {
          _showTutorial = false;
        });
      },
      onOpenDrawer: _openDrawer,
      onNavigateToVault: _navigateToVault,
      onNavigateToProfile: _navigateToProfile,
      child: MainWrapper(
        currentRoute: '/home',
        scaffoldKey: _scaffoldKey,
        child: const VFarmHomeContent(),
      ),
    );
  }
}

// ========== HOME CONTENT ==========
class VFarmHomeContent extends StatefulWidget {
  const VFarmHomeContent({super.key});

  @override
  State<VFarmHomeContent> createState() => _VFarmHomeContentState();
}

class _VFarmHomeContentState extends State<VFarmHomeContent>
    with TickerProviderStateMixin {
  // Controllers
  late PageController _pageController;
  late ScrollController _scrollController;
  late AnimationController _typingController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  bool _isRefreshing = false;
  bool _isInitialLoading = true;
  StreamController<List<CommunityPost>>? _postsStreamController;
  Stream<List<CommunityPost>>? _postsStream;

  // Cache for posts to prevent reloading
  List<CommunityPost>? _cachedPosts;
  bool _hasLoadedOnce = false;

  // Timers
  Timer? _autoScrollTimer;
  Timer? _typingTimer;

  // State variables
  int _currentCarouselIndex = 0;
  int _typingIndex = 0;
  String _currentTypingText = '';
  bool _isSearchFocused = false;
  bool _isDisposed = false;

  // Dynamic data based on context
  List<String> get _typingTexts {
    if (!mounted) return [];
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.smartFarmingSolutions,
      l10n.governmentSchemesAvailable,
      l10n.expertConsultationReady,
      l10n.marketIntelligenceHere,
      l10n.cropManagementTools,
      l10n.weatherForecastUpdates,
      l10n.aiPoweredInsights,
      l10n.modernEquipmentAccess,
    ];
  }

  List<CarouselItemData> get _carouselItems {
    if (!mounted) return [];
    final l10n = AppLocalizations.of(context)!;
    return [
      CarouselItemData(
        title: l10n.smartFarming,
        subtitle: l10n.aiPoweredCropManagement,
        description: l10n.monitorSoilWeatherCrop,
        gradient: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        icon: Icons.psychology,
        route: '/smartFarming',
      ),
      CarouselItemData(
        title: l10n.governmentSchemes,
        subtitle: l10n.financialSupportSubsidies,
        description: l10n.accessSchemesEasyApplication,
        gradient: const [Color(0xFF2196F3), Color(0xFF1565C0)],
        icon: Icons.account_balance,
        route: '/govtSchemes',
      ),
      CarouselItemData(
        title: l10n.expertConsultation,
        subtitle: l10n.professionalFarmingAdvice,
        description: l10n.connectWithVerifiedExperts,
        gradient: const [Color(0xFFFF9800), Color(0xFFE65100)],
        icon: Icons.support_agent,
        route: '/askExpert',
      ),
      CarouselItemData(
        title: l10n.myVault,
        subtitle: l10n.secureDigitalFarmingRecords,
        description: l10n.storeDocumentsDataSafely,
        gradient: const [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
        icon: Icons.security,
        route: '/myVault',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _startAnimations();
    _initializePostsStream();
  }

  void _initializePostsStream() {
    _postsStreamController = StreamController<List<CommunityPost>>.broadcast();
    _postsStream = _postsStreamController!.stream;

    // Load posts with caching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPostsWithCache();
    });
  }

  Future<void> _loadPostsWithCache() async {
    // If we have cached posts and haven't been explicitly refreshed, use cache
    if (_cachedPosts != null && _hasLoadedOnce && !_isRefreshing) {
      if (!_postsStreamController!.isClosed) {
        _postsStreamController!.add(_cachedPosts!);
      }
      setState(() {
        _isInitialLoading = false;
      });
      return;
    }

    try {
      print('Loading posts from server...');
      final posts = await CommunityService.getPostsOnce();
      print('Loaded ${posts.length} posts');

      // Cache the posts
      _cachedPosts = posts;
      _hasLoadedOnce = true;

      if (!_postsStreamController!.isClosed) {
        _postsStreamController!.add(posts);
      }

      setState(() {
        _isInitialLoading = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _isInitialLoading = false;
      });
      if (!_postsStreamController!.isClosed) {
        _postsStreamController!.addError(e);
      }
    }
  }

  Future<void> _refreshPosts() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Add a small delay to show refresh animation
      await Future.delayed(const Duration(milliseconds: 300));

      // Force reload from server
      final posts = await CommunityService.getPostsOnce();

      // Update cache
      _cachedPosts = posts;

      if (!_postsStreamController!.isClosed) {
        _postsStreamController!.add(posts);
      }
    } catch (e) {
      print('Error refreshing posts: $e');
      if (!_postsStreamController!.isClosed) {
        _postsStreamController!.addError(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoScrollTimer?.cancel();
    _typingTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _postsStreamController?.close();
    super.dispose();
  }

  void _initializeControllers() {
    _pageController = PageController(viewportFraction: 0.85);
    _scrollController = ScrollController();

    _typingController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  void _startAnimations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _startCarouselAutoScroll();
        _startTypingAnimation();
      }
    });
  }

  void _startCarouselAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isDisposed || !_pageController.hasClients) return;

      _currentCarouselIndex =
          (_currentCarouselIndex + 1) % _carouselItems.length;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentCarouselIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _startTypingAnimation() {
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isDisposed) return;

      setState(() {
        final currentText = _typingTexts[_typingIndex];
        if (_currentTypingText.length < currentText.length) {
          _currentTypingText = currentText.substring(
            0,
            _currentTypingText.length + 1,
          );
        } else {
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (!_isDisposed) {
              setState(() {
                _currentTypingText = '';
                _typingIndex = (_typingIndex + 1) % _typingTexts.length;
              });
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FFF8), Color(0xFFE8F5E8), Colors.white],
        ),
      ),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(), // Smooth 60fps scrolling
        slivers: [
          _buildSearchAppBar(),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildWelcomeHeader(),
              _buildImageCarousel(),
              buildStatsSection(context),
              _buildQuickServicesGrid(context),
              _buildTrendingSection(context),
              _buildInstantServices(context),
              _buildNewsletterSection(),
              const SizedBox(height: 30),
            ]),
          ),
        ],
      ),
    );
  }

  // ========== UI COMPONENTS ==========

  Widget _buildSearchAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color:
                      _isSearchFocused
                          ? const Color(0xFF0A9D88).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                  spreadRadius: _isSearchFocused ? 3 : 1,
                  blurRadius: _isSearchFocused ? 12 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder:
                      (context, child) => Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.05),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF0A9D88),
                          size: 24,
                        ),
                      ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    onTap: () => setState(() => _isSearchFocused = true),
                    onEditingComplete:
                        () => setState(() => _isSearchFocused = false),
                    decoration: InputDecoration(
                      hintText: "Search farming solutions...",
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A9D88).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_rounded,
                    color: Color(0xFF0A9D88),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    // Get profile synchronously from cache
    final userProfile = SessionManager.instance.getCurrentUserProfile();
    final displayName =
        userProfile?.name.isNotEmpty == true
            ? userProfile!.name
            : SessionManager.instance.getUsername() ?? "Welcome User";

    return Container(
      margin: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _floatingController,
        builder:
            (context, child) => Transform.translate(
              offset: Offset(
                0,
                math.sin(_floatingController.value * 2 * math.pi) * 2,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0A9D88),
                      Color(0xFF149D80),
                      Color(0xFF1DB584),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A9D88).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Fixed profile image container
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            (userProfile?.profileImageUrl?.isNotEmpty == true)
                                ? Image.network(
                                  userProfile!.profileImageUrl!,
                                  width: 60,
                                  height: 60,
                                  fit:
                                      BoxFit
                                          .cover, // This ensures the image covers the entire circle
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF0A9D88),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/finallogo.png',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/finallogo.png',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "PRO",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _currentTypingText,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AnimatedOpacity(
                                opacity:
                                    _currentTypingText.isNotEmpty ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: Container(
                                  width: 2,
                                  height: 16,
                                  color: Colors.greenAccent,
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
            ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final carouselHeight = screenHeight > 800 ? 240.0 : 200.0;

        // Use a large number to simulate infinite scrolling
        const int infiniteScrollCount = 1000000;

        return SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged:
                (index) => setState(() {
                  _currentCarouselIndex = index % _carouselItems.length;
                }),
            itemCount: infiniteScrollCount,
            itemBuilder: (context, index) {
              final actualIndex = index % _carouselItems.length;
              final item = _carouselItems[actualIndex];

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }

                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * carouselHeight,
                      child: child,
                    ),
                  );
                },
                child: CarouselCard(
                  item: item,
                  height: carouselHeight,
                  onTap: () {
                    Navigator.pushNamed(context, item.route);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget buildStatsSection(BuildContext context) {
    return WeatherStatsSection();
  }

  Widget _buildQuickServicesGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final services = [
      ServiceData(
        icon: Icons.account_balance_wallet,
        title: l10n.governmentSchemes,
        color: const Color(0xFF4CAF50),
        route: '/govtSchemes',
        badge: l10n.activeSchemes,
      ),
      ServiceData(
        icon: Icons.handyman,
        title: l10n.bookAService,
        color: const Color(0xFF2196F3),
        route: '/bookService',
        badge: l10n.available,
      ),
      ServiceData(
        icon: Icons.psychology,
        title: l10n.askExpert,
        color: const Color(0xFFFF9800),
        route: '/askExpert',
        badge: l10n.liveSupport,
      ),
      ServiceData(
        icon: Icons.lock_person,
        title: l10n.myVault,
        color: const Color(0xFF9C27B0),
        route: '/myVault',
        badge: l10n.secure,
      ),
    ];

    return Stack(
      children: [
        // Background decorative elements
        Positioned(
          top: -50,
          right: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0A9D88).withOpacity(0.05),
                  const Color(0xFF0A9D88).withOpacity(0.01),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.orange.withOpacity(0.08),
                  Colors.orange.withOpacity(0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Main content
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50, Colors.white],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 12),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: const Color(0xFF0A9D88).withOpacity(0.05),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: -10,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0A9D88).withOpacity(0.15),
                          const Color(0xFF0A9D88).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A9D88).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.dashboard_customize_rounded,
                      size: 22,
                      color: const Color(0xFF0A9D88),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    "Quick Services",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D29),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade100, Colors.orange.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Most Used",
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey.shade50.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0, // Much more height for content
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: services.length,
                  itemBuilder:
                      (context, index) => ServiceCard(
                        data: services[index],
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              services[index].route,
                            ),
                        onVoiceIconTap: () {},
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // const Icon(Icons.trending_up, color: Colors.orange, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.trendingNow,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A9D88),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(l10n.viewAll, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                TrendingCard(
                  title: "Wheat Price Up",
                  subtitle: "Rs.2,850/quintal",
                  color: Colors.green,
                ),
                TrendingCard(
                  title: "Monsoon Alert",
                  subtitle: "Expected in 3 days",
                  color: Colors.blue,
                ),
                TrendingCard(
                  title: "New Subsidy",
                  subtitle: "Rs.15,000 available",
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstantServices(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final services = [
      InstantServiceData(
        icon: Icons.flash_on,
        title: l10n.training,
        color: const Color(0xFF2196F3),
        subtitle: l10n.freeWorkshops,
        page: const TrainingPage(),
      ),
      InstantServiceData(
        icon: Icons.local_florist,
        title: l10n.qualityFertilizer,
        color: const Color(0xFF4CAF50),
        subtitle: l10n.discountToday,
        page: const Fertilizers(),
      ),
      InstantServiceData(
        icon: Icons.science,
        title: l10n.soilTesting,
        color: const Color(0xFFFF9800),
        subtitle: l10n.resultsInHours,
        page: const SoilTestingPage(),
      ),
      InstantServiceData(
        icon: Icons.people_alt,
        title: l10n.farmWorkers,
        color: const Color(0xFF9C27B0),
        subtitle: l10n.verifiedSkilled,
        page: const FarmWorkersPage(),
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                // child: const Icon(
                //   Icons.flash_on,
                //   color: Colors.orange,
                //   size: 18,
                // ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.instantServices,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A9D88),
                ),
              ),
              const Spacer(),
              Text(
                l10n.availableNow,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InstantServiceRow(services: services),
        ],
      ),
    );
  }

  Widget _buildNewsletterSection() {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey[50]!, Colors.white],
            ),
          ),
          child: Column(
            children: [
              // Section Header with Refresh Button
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community Posts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          Text(
                            'Share your insights',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // Refresh Button
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _isRefreshing ? null : _refreshPosts,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child:
                                _isRefreshing
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0A9D88),
                                      ),
                                    )
                                    : const Icon(
                                      Icons.refresh,
                                      color: Color(0xFF0A9D88),
                                      size: 20,
                                    ),
                          ),
                        ),
                      ),
                    ),
                    // Create Post Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A9D88), Color(0xFF149D80)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A9D88).withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25),
                          onTap: _showCreatePostDialog,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Create Post',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Posts Feed
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshPosts,
                  color: const Color(0xFF0A9D88),
                  child: StreamBuilder<List<CommunityPost>>(
                    stream: _postsStream,
                    builder: (context, snapshot) {
                      if (_isInitialLoading ||
                          (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              _cachedPosts == null)) {
                        return _buildSkeletonLoader();
                      }

                      if (snapshot.hasError && _cachedPosts == null) {
                        return _buildErrorState(context);
                      }

                      final posts = snapshot.data ?? _cachedPosts ?? [];

                      if (posts.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        cacheExtent: 1000, // Cache posts for smooth scrolling
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final currentUserId =
                              SessionManager.instance.getCurrentUserId();
                          final isLikedByCurrentUser =
                              currentUserId != null &&
                              post.likedBy.contains(currentUserId);

                          final updatedPost = CommunityPost(
                            id: post.id,
                            userId: post.userId,
                            username: post.username,
                            userProfileImage: post.userProfileImage,
                            userLocation: post.userLocation,
                            content: post.content,
                            imageUrls: post.imageUrls,
                            videoUrls: post.videoUrls,
                            createdAt: post.createdAt,
                            updatedAt: post.updatedAt,
                            likesCount: post.likesCount,
                            commentsCount: post.commentsCount,
                            likedBy: post.likedBy,
                            isLikedByCurrentUser: isLikedByCurrentUser,
                          );

                          return _buildPostCard(updatedPost);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildSkeletonPostCard(),
    );
  }

  Widget _buildSkeletonPostCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildShimmerContainer(48, 48, BorderRadius.circular(24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerContainer(120, 16, BorderRadius.circular(8)),
                      const SizedBox(height: 8),
                      _buildShimmerContainer(80, 12, BorderRadius.circular(6)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(
                  double.infinity,
                  16,
                  BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                _buildShimmerContainer(200, 16, BorderRadius.circular(8)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Image skeleton
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildShimmerContainer(
              double.infinity,
              200,
              BorderRadius.circular(12),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildShimmerContainer(60, 32, BorderRadius.circular(16)),
                const SizedBox(width: 16),
                _buildShimmerContainer(80, 32, BorderRadius.circular(16)),
                const SizedBox(width: 16),
                _buildShimmerContainer(60, 32, BorderRadius.circular(16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer(
    double width,
    double height,
    BorderRadius borderRadius,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: const _ShimmerWidget(),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.connectionError,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.checkInternetConnection,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshPosts,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.tryAgain),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A9D88),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noPostsYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.beFirstToShare,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.tapCreatePost,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _refreshPosts,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.refresh),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A9D88),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Updated create post dialog method
  void _showCreatePostDialog() {
    final currentUserId = SessionManager.instance.getCurrentUserId();
    final currentUsername = SessionManager.instance.getUsername();
    final currentUserProfile = SessionManager.instance.getCurrentUserProfile();

    if (currentUserId == null || currentUsername == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseLoginToCreatePost)));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => CreatePostDialog(
            userId: currentUserId,
            username: currentUsername,
            userProfileImage: currentUserProfile?.profileImageUrl,
            userLocation: currentUserProfile?.farmLocation,
            onPostCreated: () {
              // Invalidate cache and refresh posts after creating a new post
              _cachedPosts = null;
              _hasLoadedOnce = false;
              Future.delayed(const Duration(milliseconds: 500), () {
                _loadPostsWithCache();
              });
            },
          ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF0A9D88),
                  child:
                      post.userProfileImage != null &&
                              post.userProfileImage!.isNotEmpty
                          ? ClipOval(
                            child: Image.network(
                              post.userProfileImage!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to initial letter if image fails to load
                                return Text(
                                  post.username.isNotEmpty
                                      ? post.username[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                );
                              },
                            ),
                          )
                          : Text(
                            post.username.isNotEmpty
                                ? post.username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          if (post.userLocation != null) ...[
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post.userLocation!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                          Text(
                            _getTimeAgo(post.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Show more options
                  },
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Post content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),

          const SizedBox(height: 12),

          // Images with optimized loading
          if (post.imageUrls.isNotEmpty)
            SizedBox(
              height: post.imageUrls.length == 1 ? 250 : 180,
              child: PageView.builder(
                itemCount: post.imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        post.imageUrls[index],
                        fit: BoxFit.cover,
                        cacheWidth: 400, // Optimize image caching
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0A9D88),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 50,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // Engagement stats
          if (post.likesCount > 0 || post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (post.likesCount > 0) ...[
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                  const Spacer(),
                  if (post.commentsCount > 0)
                    Text(
                      '${post.commentsCount} comments',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _toggleLike(post),
                    icon: Icon(
                      post.isLikedByCurrentUser
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          post.isLikedByCurrentUser
                              ? Colors.red
                              : Colors.grey[600],
                      size: 20,
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.like,
                      style: TextStyle(
                        color:
                            post.isLikedByCurrentUser
                                ? Colors.red
                                : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // Show comments
                    },
                    icon: Icon(
                      Icons.comment_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.comment,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // Share post
                    },
                    icon: Icon(
                      Icons.share_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.share,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLike(CommunityPost post) async {
    final currentUserId = SessionManager.instance.getCurrentUserId();
    if (currentUserId == null) return;

    try {
      // Optimistic update for immediate UI response
      final updatedPosts =
          _cachedPosts?.map((p) {
            if (p.id == post.id) {
              final isCurrentlyLiked = p.likedBy.contains(currentUserId);
              final newLikedBy = List<String>.from(p.likedBy);

              if (isCurrentlyLiked) {
                newLikedBy.remove(currentUserId);
              } else {
                newLikedBy.add(currentUserId);
              }

              return CommunityPost(
                id: p.id,
                userId: p.userId,
                username: p.username,
                userProfileImage: p.userProfileImage,
                userLocation: p.userLocation,
                content: p.content,
                imageUrls: p.imageUrls,
                videoUrls: p.videoUrls,
                createdAt: p.createdAt,
                updatedAt: p.updatedAt,
                likesCount: newLikedBy.length,
                commentsCount: p.commentsCount,
                likedBy: newLikedBy,
                isLikedByCurrentUser: !isCurrentlyLiked,
              );
            }
            return p;
          }).toList();

      if (updatedPosts != null) {
        _cachedPosts = updatedPosts;
        if (!_postsStreamController!.isClosed) {
          _postsStreamController!.add(updatedPosts);
        }
      }

      // Then make the actual API call
      await CommunityService.toggleLike(post.id, currentUserId);
    } catch (e) {
      // Revert optimistic update on error
      await _loadPostsWithCache();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdateLike(e.toString()))),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Shimmer animation widget
class _ShimmerWidget extends StatefulWidget {
  const _ShimmerWidget();

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset((_animationController.value * 2 - 1) * 100, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
// ======== DATA MODELS ==========

class CarouselItemData {
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;
  final IconData icon;
  final String route;

  const CarouselItemData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.icon,
    required this.route,
  });
}

class StatsData {
  final IconData icon;
  final String value;
  final String label;

  const StatsData({
    required this.icon,
    required this.value,
    required this.label,
  });
}

class ServiceData {
  final IconData icon;
  final String title;
  final Color color;
  final String route;
  final String badge;

  ServiceData({
    required this.icon,
    required this.title,
    required this.color,
    required this.route,
    required this.badge,
  });
}

class InstantServiceData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget page;

  const InstantServiceData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.page,
  });
}

class CarouselCard extends StatelessWidget {
  final CarouselItemData item;
  final double height;
  final VoidCallback onTap;
  const CarouselCard({
    super.key,
    required this.item,
    this.height = 240,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: item.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: item.gradient[0].withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: PatternPainter())),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 16),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "NEW",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 21,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (height > 220) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        onTap, // <--- Make sure this is passed from parent
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: item.gradient[0],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: height > 220 ? 10 : 8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Explore Now",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatsItem extends StatelessWidget {
  final StatsData data;

  const StatsItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(data.icon, color: const Color(0xFF0A9D88), size: 24),
        const SizedBox(height: 6),
        Text(
          data.value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A9D88),
          ),
        ),
        Text(
          data.label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final ServiceData data;
  final VoidCallback onTap;
  final VoidCallback onVoiceIconTap;

  const ServiceCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onVoiceIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.12),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: data.color.withOpacity(0.08), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: data.color.withOpacity(0.1),
          highlightColor: data.color.withOpacity(0.05),
          onTap: onTap,
          child: Stack(
            children: [
              // Background decorative circle
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        data.color.withOpacity(0.03),
                        data.color.withOpacity(0.01),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon container with enhanced styling
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            data.color.withOpacity(0.15),
                            data.color.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: data.color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ],
                        border: Border.all(
                          color: data.color.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Icon(data.icon, size: 26, color: data.color),
                    ),
                    const SizedBox(height: 12),
                    // Title with better typography
                    Flexible(
                      child: Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                          height: 1.2,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Enhanced badge
              // Enhanced badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [data.color, data.color.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(6), // ✅ added
                  ),
                  child: Text(
                    data.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              // Voice icon at bottom right corner
              Positioned(
                bottom: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onVoiceIconTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
              // Subtle shine effect
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.6),
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrendingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const TrendingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      width: 140,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class InstantServiceRow extends StatelessWidget {
  final List<InstantServiceData> services;

  const InstantServiceRow({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Row(
      children:
          services.map((service) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => service.page),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: service.color.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIcon(service, isSmallScreen),
                      const SizedBox(height: 6),
                      _buildTitle(service.title, isSmallScreen),
                      const SizedBox(height: 4),
                      _buildSubtitle(service.subtitle, isSmallScreen),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildIcon(InstantServiceData service, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 6 : 10),
      decoration: BoxDecoration(
        color: service.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(service.icon, size: isSmall ? 18 : 22, color: service.color),
    );
  }

  Widget _buildTitle(String title, bool isSmall) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: isSmall ? 9 : 11,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSubtitle(String subtitle, bool isSmall) {
    return Text(
      subtitle,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: isSmall ? 7 : 9, color: Colors.grey[600]),
    );
  }
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.fill;

    // Draw floating circles
    for (int i = 0; i < 4; i++) {
      final double radius = (i % 2 + 1) * 6.0;
      final double x = size.width * (0.3 + (i * 0.2) % 0.4);
      final double y = size.height * (0.2 + (i * 0.3) % 0.5);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw curved line
    final linePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.1,
      size.width * 0.8,
      size.height * 0.3,
    );
    canvas.drawPath(path, linePaint);

    // Draw geometric shapes
    final shapePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..style = PaintingStyle.fill;

    // Small rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.8, size.height * 0.7, 20, 8),
        const Radius.circular(2),
      ),
      shapePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppMenuState extends State<_AppMenuWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _showCard(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text('$title card content - Add your details here'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ScaleTransition(
      scale: _expandAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Menu Items (shown when expanded)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _isExpanded ? 140 : 0,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildMenuItem(
                  Icons.settings,
                  'Settings',
                  () => _showCard('Settings'),
                ),
                _buildMenuItem(
                  Icons.notifications,
                  'Notifications',
                  () => _showCard('Notifications'),
                ),
                _buildMenuItem(Icons.help, 'Help', () => _showCard('Help')),
              ],
            ),
          ),
        ),
        // Main Menu Button
        IconButton(
          icon: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0.0, // 45 degree rotation
            duration: const Duration(milliseconds: 200),
            child: Icon(_isExpanded ? Icons.close : Icons.apps),
          ),
          onPressed: _toggleMenu,
        ),
      ],
    );
  }
}

class _AppMenuWidget extends StatefulWidget {
  @override
  _AppMenuState createState() => _AppMenuState();
}
