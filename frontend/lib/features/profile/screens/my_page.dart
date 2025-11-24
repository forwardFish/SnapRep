import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/my_page_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../routes/app_routes.dart';
import 'dart:async';

/// 我的页面 - 按照HTML参考文件设计 (07-my-page.html)
/// 包含：Profile Header + Achievement Progress + Calendar + Collection
class MyPage extends StatefulWidget {
  const MyPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final ScrollController _scrollController = ScrollController();
  int _currentNavIndex = 2; // Profile page is index 2
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Load page data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyPageProvider>().initializeMyPage();
    });

    // Listen to auth state changes
    _authSubscription = SupabaseService.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        debugPrint('✅ User signed in, refreshing profile data');
        // Reload user data when signed in
        context.read<MyPageProvider>().refreshAll();
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('ℹ️ User signed out, clearing profile data');
        // Reset provider when signed out
        context.read<MyPageProvider>().reset();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => context.read<MyPageProvider>().refreshAll(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Status Bar
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: false,
              automaticallyImplyLeading:
                  false, // Remove back button as requested
              toolbarHeight: 44,
              flexibleSpace: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getCurrentTime(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      '📶 🔋',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Profile Header
                  _buildProfileHeader(),

                  const SizedBox(height: 32),

                  // Achievement Progress - TEMPORARILY HIDDEN
                  // TODO: Uncomment when needed
                  // _buildAchievementSection(),

                  // const SizedBox(height: 32),

                  // Workout Calendar
                  _buildCalendarSection(),

                  const SizedBox(height: 32),

                  // My Collection
                  _buildCollectionSection(),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  // Navigation handling
  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate to home page
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        // Navigate to camera page (AI equipment recognition)
        debugPrint('Navigate to camera page');
        // For now, navigate to workout guide step 1 as camera is not implemented yet
        AppRoutes.navigateToWorkoutGuideStep1(context);
        break;
      case 2:
        // Already on profile page
        break;
    }
  }

  /// Profile Header - Modern user settings area
  Widget _buildProfileHeader() {
    return Consumer<MyPageProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // 根据登录状态显示不同内容
            if (!provider.isUserLoggedIn) ...[
              // Login prompt banner - 只在未登录时显示
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4A4A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Please login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.googleLogin);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // User profile card - 只在已登录时显示
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar with real user avatar or default
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2C2C2C),
                      ),
                      child: ClipOval(
                        child: provider.avatarUrl != null &&
                                provider.avatarUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: provider.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: Icon(
                                    Icons.person,
                                    color: Color(0xFFFFD700),
                                    size: 32,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Center(
                                  child: Icon(
                                    Icons.person,
                                    color: Color(0xFFFFD700),
                                    size: 32,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xFFFFD700),
                                  size: 32,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // User Info - 显示真实的用户数据
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Name
                          Text(
                            provider.userName ??
                                provider.userEmail?.split('@').first ??
                                'Anonymous User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // User Email or fitness journey info
                          Text(
                            provider.userEmail ??
                                'Day 1 of your fitness journey',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // MVP阶段: 移除红点和箭头，不可点击更改
                    // TODO: MVP后恢复编辑功能
                    // Container(
                    //   width: 8,
                    //   height: 8,
                    //   decoration: BoxDecoration(
                    //     color: Colors.red,
                    //     shape: BoxShape.circle,
                    //   ),
                    // ),
                    // const SizedBox(width: 8),
                    // GestureDetector(
                    //   onTap: () {
                    //     Navigator.pushNamed(context, AppRoutes.profileSettings);
                    //   },
                    //   child: Icon(
                    //     Icons.arrow_forward_ios,
                    //     color: Colors.grey[400],
                    //     size: 16,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ], // <- 添加缺失的关闭方括号
          ],
        );
      },
    );
  }

  /// Achievement Progress - 简化版本，只显示总体进度
  Widget _buildAchievementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with gradient accent and "View Details" button
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD700), Color(0xFFFF8E53)],
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Achievement Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.achievementDetails);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Color(0xFFFFD700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Simplified Achievement Progress Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFFFD700).withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Overall Progress Ring
              _buildOverallProgressRing(),

              const SizedBox(height: 24),

              // Quick Summary Row showing achievement lines at a glance
              _buildAchievementSummaryRow(),
            ],
          ),
        ),
      ],
    );
  }

  /// Quick Achievement Summary Row - 显示成就概览
  Widget _buildAchievementSummaryRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Craftsman Achievement Summary
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B4D8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF00B4D8).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text('🏆', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Safety Master',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          'Level 4 • 78%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF00B4D8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withOpacity(0.2),
          ),

          // Explorer Achievement Summary
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B59FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF9B59FF).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text('🌟', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Space Explorer',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          'Level 2 • 45%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9B59FF),
                          ),
                        ),
                      ],
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

  /// Overall Progress Ring - 显示整体成就进度
  Widget _buildOverallProgressRing() {
    const overallProgress = 0.62; // 整体成就进度 62%

    return Column(
      children: [
        // Progress Ring
        Stack(
          alignment: Alignment.center,
          children: [
            // Background Ring
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                  width: 8,
                ),
              ),
            ),
            // Progress Ring
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: overallProgress,
                strokeWidth: 8,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFFFFD700),
                ),
                strokeCap: StrokeCap.round,
              ),
            ),
            // Center Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(overallProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C3E50),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF90A4AE),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Achievement Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('12', 'Badges', Icons.military_tech),
            Container(
              width: 1,
              height: 32,
              color: Colors.grey.withOpacity(0.2),
            ),
            _buildStatItem('3', 'Streaks', Icons.local_fire_department),
            Container(
              width: 1,
              height: 32,
              color: Colors.grey.withOpacity(0.2),
            ),
            _buildStatItem('42', 'Workouts', Icons.fitness_center),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFFD700),
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF90A4AE),
          ),
        ),
      ],
    );
  }

  /// Modern Achievement Badge - 现代化成就徽章设计
  Widget _buildModernAchievementBadge({
    required String icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required double progress,
    required String progressText,
    required String currentLevel,
    required String nextReward,
    required Color color,
    required bool isMainAchievement,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isMainAchievement
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.05),
                  color.withOpacity(0.02),
                ],
              )
            : null,
        color: isMainAchievement ? null : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMainAchievement
              ? color.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: isMainAchievement
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Top Row: Icon, Title and Level Badge
          Row(
            children: [
              // Icon with background
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: iconBg.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3E50),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            currentLevel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF90A4AE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Section
          Row(
            children: [
              // Progress Text and Next Reward
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${(progress * 100).toInt()}% to ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF90A4AE),
                          ),
                        ),
                        Text(
                          progressText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Next: $nextReward',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF90A4AE),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Indicator
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background Circle
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withOpacity(0.1),
                            width: 3,
                          ),
                        ),
                      ),
                      // Progress Circle
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Progress Percentage
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calendar Section - Weekly view centered on today
  Widget _buildCalendarSection() {
    final today = DateTime.now();
    final startOfWeek =
        today.subtract(Duration(days: 3)); // 3 days before today

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Workout Calendar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.workoutCalendar);
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFD700),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Calendar Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Calendar Header - showing current week range
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_formatWeekRange(startOfWeek)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Weekly Calendar Grid
              _buildWeeklyCalendarGrid(startOfWeek, today),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendarGrid(DateTime startOfWeek, DateTime today) {
    // Day abbreviations
    final dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Generate 7 days starting from startOfWeek
    final weekDays =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    // Sample workout days (you can replace this with actual data from provider)
    final workoutDays = {
      DateTime(today.year, today.month, today.day - 2),
      DateTime(today.year, today.month, today.day - 1),
      DateTime(today.year, today.month, today.day),
      DateTime(today.year, today.month, today.day + 1),
    };

    return Column(
      children: [
        // Day headers based on actual dates
        Row(
          children: weekDays.map((date) {
            final dayName = _getDayName(date.weekday);
            return Expanded(
              child: Center(
                child: Text(
                  dayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF90A4AE),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 8),

        // Calendar days row
        Row(
          children: weekDays.map((date) {
            final isToday = _isSameDay(date, today);
            final hasWorkout =
                workoutDays.any((workoutDate) => _isSameDay(date, workoutDate));

            return Expanded(
              child: GestureDetector(
                onTap: hasWorkout
                    ? () {
                        // Navigate to workout details for this date
                        Navigator.pushNamed(context, '/workout-details',
                            arguments: {'date': date, 'isToday': isToday});
                      }
                    : null,
                child: _buildWeeklyCalendarDay(date.day, hasWorkout, isToday),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendarDay(int day, bool hasWorkout, bool isToday) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFFFFD700).withOpacity(0.2)
            : (hasWorkout ? const Color(0xFFFFD700).withOpacity(0.1) : null),
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: const Color(0xFFFFD700), width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
              color:
                  isToday ? const Color(0xFFFFD700) : const Color(0xFF2C3E50),
            ),
          ),
          if (hasWorkout && !isToday) ...[
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
          ],
          if (isToday) ...[
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods
  String _formatWeekRange(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    final startMonth = _getMonthName(startOfWeek.month);
    final endMonth = _getMonthName(endOfWeek.month);

    if (startOfWeek.month == endOfWeek.month) {
      return '$startMonth ${startOfWeek.day}-${endOfWeek.day}';
    } else {
      return '$startMonth ${startOfWeek.day} - $endMonth ${endOfWeek.day}';
    }
  }

  String _formatDate(DateTime date) {
    final month = _getMonthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      '',
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
      'Dec'
    ];
    return months[month];
  }

  String _getDayName(int weekday) {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// My Collection Section - 只显示3个卡片，可点击查看更多
  Widget _buildCollectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Collection (12 Cards)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.collectionDetails);
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFD700),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 只显示3个卡片
        SizedBox(
          height: 160, // 固定高度
          child: Row(
            children: [
              Expanded(
                child: _buildCollectionCard('Chair Squats', 'FINE',
                    'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCollectionCard('Push-ups', 'COMMON',
                    'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCollectionCard('Bag Lifts', 'RARE',
                    'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(String title, String rarity, String imageUrl) {
    final rarityColors = {
      'COMMON': {
        'bg': const Color(0xFFE8F5E8),
        'text': const Color(0xFF2E7D32)
      },
      'FINE': {'bg': const Color(0xFFE3F2FD), 'text': const Color(0xFF1565C0)},
      'RARE': {'bg': const Color(0xFFF3E5F5), 'text': const Color(0xFF7B1FA2)},
      'EPIC': {'bg': const Color(0xFFFFF3E0), 'text': const Color(0xFFF57C00)},
    };

    final colors = rarityColors[rarity] ?? rarityColors['COMMON']!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Image Area (70%)
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Rarity Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors['bg'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          rarity,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colors['text'],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title Area (30%)
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }
}
