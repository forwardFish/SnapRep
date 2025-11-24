import 'package:flutter/material.dart';
import '../features/splash/splash_screen.dart';
import '../features/home/screens/home_page.dart';
import '../features/workout_guide/screens/camera_detection_page.dart';
import '../features/workout_guide/screens/workout_mode_selection_page.dart';
import '../features/workout_guide/screens/environment_confirmation_page.dart';
import '../features/workout_guide/screens/workout_guide_step3_page.dart';
import '../features/workout_result/screens/modern_workout_result_page.dart';
import '../features/result_card/screens/result_card_page.dart';
import '../features/profile/screens/my_page.dart';
import '../features/profile/screens/collection_details_page.dart';
import '../features/profile/screens/workout_details_page.dart';
import '../features/profile/screens/workout_calendar_page.dart';
import '../features/profile/screens/achievement_details_page.dart';
import '../features/auth/screens/google_login_page.dart';
import '../features/challenges/screens/challenges_page.dart';
import '../features/exercises/screens/recommended_exercises_page.dart';
import '../features/onboarding/screens/scenario_selection_page.dart';
import '../features/onboarding/screens/equipment_selection_page.dart';
import '../features/onboarding/screens/intent_selection_page.dart';
import '../features/onboarding/screens/muscle_target_page.dart';
import '../features/onboarding/screens/ai_recognition_page.dart';
import '../core/models/exercise.dart';

/// 应用路由配置类
/// 定义所有页面的路由名称和跳转逻辑
class AppRoutes {
  // ========== 基础页面路由 ==========

  /// 启动页 - 应用启动时的第一个页面
  static const String splash = '/';

  /// 首页 - 主界面,包含快速开始、场景推荐、器材选择等入口
  static const String home = '/home';

  // ========== 旧版训练引导流程路由 (逐步被新版替代) ==========

  /// [旧版] Step 1: 相机检测页 - AI识别场景和器材
  /// 功能: 使用相机拍摄环境,AI自动识别场景和可用器材
  /// 跳转来源: 首页点击AI识别按钮
  /// 下一步: workoutModeSelection (运动意图选择)
  static const String cameraDetection = '/camera-detection';

  /// [旧版] Step 2: 运动模式选择页 - 选择运动意图(拉伸/力量/有氧等)
  /// 功能: 根据Step1识别的器材,选择训练意图
  /// 跳转来源: cameraDetection 或 environmentConfirmation
  /// 下一步: workoutGuideStep3 (重点部位选择)
  static const String workoutModeSelection = '/workout-mode-selection';

  /// [旧版] 环境确认页 - 用户手动确认或修改AI识别的场景和器材
  /// 功能: 显示AI识别结果,允许用户调整
  /// 跳转来源: cameraDetection (当用户需要确认时)
  /// 下一步: workoutModeSelection
  static const String environmentConfirmation = '/environment-confirmation';

  /// [旧版] Step 1 别名 - 指向 cameraDetection,保持命名一致性
  static const String workoutGuideStep1 = '/camera-detection';

  /// [旧版] Step 2 别名 - 指向 workoutModeSelection,保持命名一致性
  static const String workoutGuideStep2 = '/workout-mode-selection';

  /// [旧版] Step 3: 重点部位选择页 - 选择想要锻炼的目标肌群
  /// 功能: 选择训练的目标部位(如腿部、腰腹、手臂等)
  /// 跳转来源: workoutModeSelection
  /// 下一步: modernWorkoutResult (训练动作推荐结果)
  static const String workoutGuideStep3 = '/workout-guide-step3';

  // ========== 训练结果和执行页面 ==========

  /// [旧版] 训练结果页 - 已废弃,现在统一使用 modernWorkoutResult
  static const String workoutResult = '/workout-result';

  /// 现代化训练结果页 - 显示AI推荐的训练动作列表
  /// 功能: 展示根据用户选择推荐的训练动作,可以开始训练
  /// 跳转来源:
  ///   - workoutGuideStep3 (完整流程)
  ///   - quickStartWorkout (快速开始)
  ///   - 首页各种快捷入口(场景快选、器材快选等)
  /// 下一步: professionalWorkoutVideo (开始训练视频)
  static const String modernWorkoutResult = '/modern-workout-result';

  /// 训练成果卡页 - 训练完成后的成果展示和分享
  /// 功能: 显示本次训练总结、消耗卡路里、完成度等,可以分享
  /// 跳转来源: professionalWorkoutVideo (训练完成后)
  /// 操作: 可以分享到社交媒体或保存到我的页面
  static const String resultCard = '/result-card';

  /// 专业训练视频页 - 执行训练动作的视频播放页
  /// 功能: 播放训练视频,实时跟随做动作,倒计时提醒
  /// 跳转来源: modernWorkoutResult (点击开始训练)
  /// 下一步: resultCard (完成训练后)
  /// 注意: 使用 MaterialPageRoute 而非命名路由
  static const String professionalWorkoutVideo = '/professional-workout-video';

  // ========== 个人中心相关页面 ==========

  /// 我的页面 - 个人中心主页
  /// 功能: 显示个人信息、训练历史、收藏、成就等
  /// 标签页: 收藏、历史、成就
  /// 跳转来源: 首页底部导航栏、训练完成后
  static const String myPage = '/my-page';

  /// 收藏详情页 - 查看收藏的训练动作详情
  /// 功能: 显示收藏的动作详细信息和历史记录
  /// 跳转来源: myPage 收藏标签页
  static const String collectionDetails = '/collection-details';

  /// 训练详情页 - 查看某次历史训练的详细信息
  /// 功能: 显示某次训练的动作列表、完成情况、时间等
  /// 跳转来源: myPage 历史标签页
  /// 操作: 可以点击"一键同款"复刻相同训练
  static const String workoutDetails = '/workout-details';

  /// 训练日历页 - 月历视图展示训练记录
  /// 功能: 日历形式显示每天的训练情况,点击日期查看当天训练
  /// 跳转来源: myPage 历史标签页
  static const String workoutCalendar = '/workout-calendar';

  /// 成就详情页 - 查看获得的成就徽章和进度
  /// 功能: 显示已解锁和未解锁的成就,查看成就条件
  /// 跳转来源: myPage 成就标签页
  static const String achievementDetails = '/achievement-details';

  // ========== 社交和挑战页面 ==========

  /// 挑战页面 - 物品挑战列表和参与页面
  /// 功能: 显示各种器材挑战活动,可以参与挑战
  /// 跳转来源: 首页挑战入口、底部导航栏
  /// 操作: 点击挑战卡片可以快速加入对应训练
  static const String challenges = '/challenges';

  /// 推荐动作页面 - 根据用户历史推荐适合的训练动作
  /// 功能: AI分析用户训练习惯,推荐个性化动作
  /// 跳转来源: 首页推荐入口
  static const String recommendedExercises = '/recommended-exercises';

  // ========== 认证相关页面 ==========

  /// Google登录页 - 使用Google账号登录
  /// 功能: Google OAuth登录流程
  /// 跳转来源: 首次启动或需要登录时
  static const String googleLogin = '/google-login';

  // ========== 新版引导流程路由 (推荐使用) ==========

  /// [新版] Step 1: 场景选择页 - 选择训练场景(办公室/家里/公园/健身房等)
  /// 功能: 用户选择当前所在场景,系统会推荐该场景下常见器材
  /// 跳转来源: 首页"开始引导流程"、首次使用引导
  /// 下一步: equipmentSelection (器材选择)
  static const String scenarioSelection = '/scenario-selection';

  /// [新版] Step 2: 器材选择页 - 根据场景选择可用的训练器材
  /// 功能: 显示当前场景下的常见器材,可多选
  /// 参数: scenarioCode (从scenarioSelection传入)
  /// 跳转来源: scenarioSelection
  /// 下一步: intentSelection (运动意图选择)
  static const String equipmentSelection = '/equipment-selection';

  /// [新版] Step 3: 运动意图选择页 - 选择训练目标(拉伸/力量/有氧/放松等)
  /// 功能: 选择本次训练的主要意图和目标
  /// 跳转来源: equipmentSelection
  /// 下一步: muscleSelection (目标肌群选择)
  static const String intentSelection = '/intent-selection';

  /// [新版] Step 4: 目标肌群选择页 - 选择想要重点锻炼的身体部位
  /// 功能: 选择训练的目标部位(全身/上肢/下肢/核心等)
  /// 跳转来源: intentSelection
  /// 下一步: modernWorkoutResult (生成训练推荐)
  static const String muscleSelection = '/muscle-selection';

  /// [新版] AI识别页 - 使用相机AI识别场景和器材,自动填充选择
  /// 功能: 拍照后AI自动识别并填充场景和器材信息
  /// 跳转来源: 场景选择页或器材选择页的"AI识别"按钮
  /// 下一步: 返回到调用页面并填充识别结果
  static const String aiRecognition = '/ai-recognition';

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
        return EnvironmentConfirmationPage(guideData: args); // Environment Confirmation
      },
      workoutGuideStep3: (context) => const WorkoutGuideStep3Page(), // Step 3: Target Muscle Selection
      workoutResult: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ModernWorkoutResultPage(recommendationParams: args?['recommendationParams']);
      },
      modernWorkoutResult: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ModernWorkoutResultPage(recommendationParams: args?['recommendationParams']);
      },
      resultCard: (context) => const ResultCardPage(),
      myPage: (context) => const MyPage(),
      collectionDetails: (context) => const CollectionDetailsPage(),
      workoutDetails: (context) => const WorkoutDetailsPage(),
      workoutCalendar: (context) => const WorkoutCalendarPage(),
      achievementDetails: (context) => const AchievementDetailsPage(),
      googleLogin: (context) => const GoogleLoginPage(),
      challenges: (context) => const ChallengesPage(),
      recommendedExercises: (context) => const RecommendedExercisesPage(),

      // New onboarding flow routes
      scenarioSelection: (context) => const ScenarioSelectionPage(),
      equipmentSelection: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return EquipmentSelectionPage(
          scenarioCode: args?['scenarioCode'],
        );
      },
      intentSelection: (context) => const IntentSelectionPage(),
      muscleSelection: (context) => const MuscleTargetPage(),
      aiRecognition: (context) => const AIRecognitionPage(),
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
        builder: (context) => ModernWorkoutResultPage(
          exercise: exercise,
          exercises: exercises,
          currentExerciseIndex: currentExerciseIndex,
        ),
      ),
    );
  }

  // New onboarding flow navigation methods

  /// 启动完整引导流程（场景选择开始）
  static Future<T?> startCompleteOnboardingFlow<T>(BuildContext context) {
    return navigateTo<T>(context, scenarioSelection);
  }

  /// 启动AI识别流程
  static Future<T?> startAIRecognitionFlow<T>(BuildContext context) {
    return navigateTo<T>(context, aiRecognition);
  }

  /// 从场景选择导航到器材选择
  static Future<T?> navigateToEquipmentSelection<T>(
    BuildContext context, {
    String? scenarioCode,
  }) {
    return navigateTo<T>(
      context,
      equipmentSelection,
      arguments: {'scenarioCode': scenarioCode},
    );
  }

  /// 从器材选择导航到意图选择
  static Future<T?> navigateToIntentSelection<T>(BuildContext context) {
    return navigateTo<T>(context, intentSelection);
  }

  /// 从意图选择导航到肌肉目标选择
  static Future<T?> navigateToMuscleSelection<T>(BuildContext context) {
    return navigateTo<T>(context, muscleSelection);
  }

  // === 业务流程导航方法 (Business Flow Navigation) ===

  /// 路径1: 最快路径 - "给我60秒"
  static Future<void> quickStart60Seconds(BuildContext context) async {
    await navigateToWorkoutResult(
      context,
      recommendationParams: {
        'intent': 'STRETCH',
        'equipment': ['hands_free'],
        'duration': 60,
        'isQuickStart': true,
      },
    );
  }

  /// 路径2: 完整引导路径 - Step1 → Step2 → Step3
  static Future<T?> startCompleteGuidedFlow<T>(BuildContext context) {
    return navigateTo<T>(context, workoutGuideStep1); // 开始Step1: 场景选择和物品选择
  }

  /// 路径3: AI识别路径 - 拍照 → Step1 → Step2 → Step3
  static Future<T?> startAIFlow<T>(BuildContext context) {
    return navigateTo<T>(context, workoutGuideStep1, arguments: {'mode': 'ai_camera'});
  }

  /// 路径4: 点击物品直接跳转动作结果页
  static Future<void> equipmentQuickSelect(
    BuildContext context, {
    required String equipmentCode,
  }) async {
    // 根据物品获取预设配置直接生成推荐
    final equipmentPresets = _getEquipmentPresets(equipmentCode);
    await navigateToWorkoutResult(
      context,
      recommendationParams: equipmentPresets,
    );
  }

  /// 路径5: 物品挑战路径
  static Future<void> challengeQuickJoin(
    BuildContext context, {
    required String challengeId,
    required String equipmentCode,
  }) async {
    // 物品挑战直接生成推荐
    await navigateToWorkoutResult(
      context,
      recommendationParams: {
        'equipment': [equipmentCode],
        'challengeId': challengeId,
        'isChallenge': true,
      },
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

  /// 获取器材预设配置
  static Map<String, dynamic> _getEquipmentPresets(String equipmentCode) {
    switch (equipmentCode) {
      case 'chair':
        return {
          'equipment': ['chair'],
          'intent': 'STRETCH',
          'scenario': 'office',
          'tags': ['silent', 'sitting'],
        };
      case 'wall':
        return {
          'equipment': ['wall'],
          'intent': 'STRETCH',
          'scenario': 'office',
          'tags': ['standing', 'silent'],
        };
      case 'sofa':
        return {
          'equipment': ['sofa'],
          'intent': 'RELAX',
          'scenario': 'living_room',
          'tags': ['comfortable'],
        };
      case 'bottle':
        return {
          'equipment': ['bottle'],
          'intent': 'STRENGTH',
          'scenario': 'office',
          'tags': ['lightweight'],
        };
      case 'stairs':
        return {
          'equipment': ['stairs'],
          'intent': 'LIGHT_CARDIO',
          'scenario': 'outdoor',
          'tags': ['cardio'],
        };
      case 'hands_free':
      default:
        return {
          'equipment': ['hands_free'],
          'intent': 'STRETCH',
          'scenario': 'home',
          'tags': ['bodyweight'],
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
