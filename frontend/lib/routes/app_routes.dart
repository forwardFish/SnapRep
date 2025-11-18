import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';
import '../features/home/screens/home_page.dart';
import '../features/workout_guide/screens/camera_detection_page.dart';
import '../features/workout_guide/screens/workout_mode_selection_page.dart';
import '../features/workout_guide/screens/environment_confirmation_page.dart';
import '../features/workout_guide/screens/workout_guide_step3_page.dart';
import '../features/workout_result/screens/workout_result_page.dart';
import '../features/workout_result/screens/modern_workout_result_page.dart';
import '../features/workout_execution/screens/professional_workout_video_page_v2.dart';
import '../features/result_card/screens/result_card_page.dart';
import '../features/profile/screens/my_page.dart';
import '../features/profile/screens/collection_details_page.dart';
import '../features/profile/screens/workout_details_page.dart';
import '../features/profile/screens/workout_calendar_page.dart';
import '../features/profile/screens/achievement_details_page.dart';
import '../features/auth/screens/google_login_page.dart';
import '../core/models/exercise.dart';

/// 应用路由配置类
/// 定义所有页面的路由名称和跳转逻辑
class AppRoutes {
  // 路由名称常量
  static const String splash = '/';
  static const String home = '/home';
  static const String cameraDetection = '/camera-detection'; // New Step 1
  static const String workoutModeSelection = '/workout-mode-selection'; // New Step 2
  static const String environmentConfirmation = '/environment-confirmation'; // New Step 3
  static const String workoutGuideStep1 = '/camera-detection'; // Alias for backward compatibility
  static const String workoutGuideStep2 = '/workout-mode-selection'; // Alias for backward compatibility
  static const String workoutGuideStep3 = '/environment-confirmation'; // Alias for backward compatibility
  static const String workoutResult = '/workout-result';
  static const String modernWorkoutResult = '/modern-workout-result';
  static const String resultCard = '/result-card';
  static const String myPage = '/my-page';
  static const String collectionDetails = '/collection-details';
  static const String workoutDetails = '/workout-details';
  static const String workoutCalendar = '/workout-calendar';
  static const String achievementDetails = '/achievement-details';
  static const String googleLogin = '/google-login';
  static const String professionalWorkoutVideo = '/professional-workout-video';

  /// 生成路由配置
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      home: (context) => const HomePage(),
      cameraDetection: (context) => const CameraDetectionPage(), // New Step 1: Camera AI Detection
      workoutModeSelection: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return WorkoutModeSelectionPage(guideData: args); // New Step 2: Mode Selection
      },
      environmentConfirmation: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return EnvironmentConfirmationPage(guideData: args); // New Step 3: Environment Confirmation
      },
      workoutResult: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ModernWorkoutResultPage(recommendationParams: args);
      },
      modernWorkoutResult: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ModernWorkoutResultPage(recommendationParams: args);
      },
      resultCard: (context) => const ResultCardPage(),
      myPage: (context) => const MyPage(),
      collectionDetails: (context) => const CollectionDetailsPage(),
      workoutDetails: (context) => const WorkoutDetailsPage(),
      workoutCalendar: (context) => const WorkoutCalendarPage(),
      achievementDetails: (context) => const AchievementDetailsPage(),
      googleLogin: (context) => const GoogleLoginPage(),
    };
  }

  /// 路由导航辅助方法
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) {
    if (replace) {
      return Navigator.pushReplacementNamed<T, dynamic>(
        context,
        routeName,
        arguments: arguments,
      );
    } else {
      return Navigator.pushNamed<T>(
        context,
        routeName,
        arguments: arguments,
      );
    }
  }

  /// 返回上一页
  static void goBack<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }

  /// 导航到首页（清除所有堆栈）
  static Future<T?> navigateToHome<T>(BuildContext context) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      home,
      (route) => false,
    );
  }

  /// 导航到引导页Step1（开始新的训练流程）
  static Future<T?> navigateToWorkoutGuideStep1<T>(
    BuildContext context, {
    Map<String, dynamic>? preSelectedData,
  }) {
    return navigateTo<T>(
      context,
      workoutGuideStep1,
      arguments: preSelectedData,
    );
  }

  /// 导航到引导页Step2（从Step1传递数据）
  static Future<T?> navigateToWorkoutGuideStep2<T>(
    BuildContext context, {
    required Map<String, dynamic> guideData,
  }) {
    return navigateTo<T>(
      context,
      workoutGuideStep2,
      arguments: guideData,
    );
  }

  /// Push to workout guide step 2 (alias for compatibility)
  static Future<T?> pushToWorkoutGuideStep2<T>(BuildContext context) {
    return navigateTo<T>(
      context,
      workoutGuideStep2,
    );
  }

  /// 导航到引导页Step3（从Step2传递数据）
  static Future<T?> navigateToWorkoutGuideStep3<T>(
    BuildContext context, {
    required Map<String, dynamic> guideData,
  }) {
    return navigateTo<T>(
      context,
      workoutGuideStep3,
      arguments: guideData,
    );
  }

  /// Push to workout guide step 3 (alias for compatibility)
  static Future<T?> pushToWorkoutGuideStep3<T>(BuildContext context) {
    return navigateTo<T>(
      context,
      workoutGuideStep3,
    );
  }

  /// Push to workout result (alias for compatibility)
  static Future<T?> pushToWorkoutResult<T>(
    BuildContext context, {
    Map<String, dynamic>? recommendationParams,
    String? sessionId,
  }) {
    return navigateToWorkoutResult<T>(
      context,
      recommendationParams: recommendationParams,
      sessionId: sessionId,
    );
  }

  /// 导航到动作结果页（从引导页或首页快速推荐）
  static Future<T?> navigateToWorkoutResult<T>(
    BuildContext context, {
    Map<String, dynamic>? recommendationParams,
    String? sessionId,
    bool replace = false,
  }) {
    return navigateTo<T>(
      context,
      modernWorkoutResult, // Use the new modern page
      arguments: {
        'recommendationParams': recommendationParams,
        'sessionId': sessionId,
      },
      replace: replace,
    );
  }

  /// 导航到成果卡页（从训练完成页面）
  static Future<T?> navigateToResultCard<T>(
    BuildContext context, {
    required String sessionId,
  }) {
    return navigateTo<T>(
      context,
      resultCard,
      arguments: {'sessionId': sessionId},
    );
  }

  /// 导航到我的页面
  static Future<T?> navigateToMyPage<T>(
    BuildContext context, {
    int? initialTabIndex,
  }) {
    return navigateTo<T>(
      context,
      myPage,
      arguments: {'initialTabIndex': initialTabIndex},
    );
  }

  /// 快速开始流程（首页"给我60秒"按钮）
  /// 直接生成推荐，跳过引导页
  static Future<void> quickStartWorkout(BuildContext context) async {
    // 使用默认参数生成快速推荐
    await navigateToWorkoutResult(
      context,
      recommendationParams: {
        'intent': 'STRETCH', // 默认：舒展筋骨
        'equipment': ['hands_free'], // 默认：空手
        'duration': 60, // 默认：60秒
        'isQuickStart': true,
      },
    );
  }

  /// 场景快选流程（首页点击场景Chip）
  /// 使用场景预设直接生成推荐
  static Future<void> scenarioQuickSelect(
    BuildContext context, {
    required String scenarioCode,
  }) async {
    // 根据场景获取预设配置
    final scenarioPresets = _getScenarioPresets(scenarioCode);

    await navigateToWorkoutResult(
      context,
      recommendationParams: scenarioPresets,
    );
  }

  /// 物品选择流程（首页点击器材Tile）
  /// 跳转到引导页Step2，物品已预选
  static Future<void> equipmentPreselect(
    BuildContext context, {
    required String equipmentCode,
  }) async {
    await navigateToWorkoutGuideStep1(
      context,
      preSelectedData: {
        'preSelectedEquipment': [equipmentCode],
      },
    );
  }

  /// 主题周快速加入（首页点击主题周"一键加入"）
  static Future<void> themeWeekQuickJoin(
    BuildContext context, {
    required String themeWeekId,
    required String equipmentCode,
  }) async {
    await navigateToWorkoutResult(
      context,
      recommendationParams: {
        'equipment': [equipmentCode],
        'themeWeekId': themeWeekId,
        'isThemeWeek': true,
      },
    );
  }

  /// 一键同款流程（我的页面点击卡片/历史）
  /// 复刻相同条件生成新推荐
  static Future<void> replicateWorkout(
    BuildContext context, {
    required Map<String, dynamic> originalParams,
  }) async {
    await navigateToWorkoutResult(
      context,
      recommendationParams: originalParams,
    );
  }

  /// 导航到专业训练视频页面
  static Future<T?> navigateToProfessionalWorkoutVideo<T>(
    BuildContext context, {
    required Exercise exercise,
    required List<Exercise> exercises,
    int currentExerciseIndex = 0,
  }) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalWorkoutVideoPageV2(
          exercise: exercise,
          exercises: exercises,
          currentExerciseIndex: currentExerciseIndex,
        ),
      ),
    );
  }

  /// 获取场景预设配置
  static Map<String, dynamic> _getScenarioPresets(String scenarioCode) {
    switch (scenarioCode) {
      case 'office':
        return {
          'equipment': ['chair', 'wall'],
          'intent': 'STRETCH',
          'scenario': 'office',
          'tags': ['silent', 'small_space'],
        };
      case 'living_room':
      case 'home':
        return {
          'equipment': ['sofa', 'hands_free'],
          'intent': 'RELAX',
          'scenario': 'living_room',
        };
      case 'park':
        return {
          'equipment': ['bench', 'hands_free'],
          'intent': 'LIGHT_CARDIO',
          'scenario': 'park',
        };
      case 'gym':
        return {
          'equipment': ['hands_free'],
          'intent': 'STRENGTH',
          'scenario': 'gym',
        };
      default:
        return {
          'equipment': ['hands_free'],
          'intent': 'STRETCH',
          'scenario': scenarioCode,
        };
    }
  }

  /// 解析路由参数
  static T? getArgument<T>(BuildContext context, String key) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      return args[key] as T?;
    }
    return null;
  }

  /// 获取所有路由参数
  static Map<String, dynamic>? getAllArguments(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      return args;
    }
    return null;
  }
}

/// 路由观察器（用于调试和分析）
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('📍 Route Pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('📍 Route Popped: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint('📍 Route Replaced: ${oldRoute?.settings.name} → ${newRoute?.settings.name}');
  }
}
