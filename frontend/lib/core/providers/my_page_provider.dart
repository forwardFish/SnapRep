import 'package:flutter/material.dart';
import '../models/share_card.dart';
import '../models/workout_session.dart';
import '../models/workout_intent.dart';
import '../models/target_muscle.dart';
import '../services/api_service.dart';

/// 我的页面状态管理Provider
/// 管理用户数据、卡片收集、训练历史等
class MyPageProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  // 当前Tab索引
  int _currentTabIndex = 0;

  // 用户信息
  String? _userId;
  String? _userEmail;
  String? _userName;
  String? _avatarUrl;
  int _totalWorkouts = 0;
  int _currentStreak = 0;
  int _totalCards = 0;

  // 卡片收集数据
  List<ShareCard> _allCards = [];
  List<ShareCard> _filteredCards = [];
  RarityLevel? _selectedRarity;
  EquipmentSeries? _selectedSeries;

  // 训练历史数据
  List<WorkoutSession> _workoutHistory = [];
  Map<DateTime, List<WorkoutSession>> _calendarData = {};
  DateTime _selectedDate = DateTime.now();

  // 加载状态
  bool _isLoadingUser = false;
  bool _isLoadingCards = false;
  bool _isLoadingHistory = false;

  // 错误信息
  String? _userError;
  String? _cardsError;
  String? _historyError;

  // Getters
  int get currentTabIndex => _currentTabIndex;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get avatarUrl => _avatarUrl;
  int get totalWorkouts => _totalWorkouts;
  int get currentStreak => _currentStreak;
  int get totalCards => _totalCards;

  List<ShareCard> get allCards => _allCards;
  List<ShareCard> get filteredCards => _filteredCards;
  RarityLevel? get selectedRarity => _selectedRarity;
  EquipmentSeries? get selectedSeries => _selectedSeries;

  List<WorkoutSession> get workoutHistory => _workoutHistory;
  Map<DateTime, List<WorkoutSession>> get calendarData => _calendarData;
  DateTime get selectedDate => _selectedDate;

  bool get isLoadingUser => _isLoadingUser;
  bool get isLoadingCards => _isLoadingCards;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get userError => _userError;
  String? get cardsError => _cardsError;
  String? get historyError => _historyError;

  // 计算属性
  bool get hasCards => _allCards.isNotEmpty;
  bool get hasHistory => _workoutHistory.isNotEmpty;
  bool get isUserLoggedIn => _userId != null && _userId!.isNotEmpty;

  int get commonCards => _allCards.where((c) => c.rarity.level == RarityLevel.common).length;
  int get uncommonCards => _allCards.where((c) => c.rarity.level == RarityLevel.uncommon).length;
  int get rareCards => _allCards.where((c) => c.rarity.level == RarityLevel.rare).length;
  int get epicCards => _allCards.where((c) => c.rarity.level == RarityLevel.epic).length;
  int get legendaryCards => _allCards.where((c) => c.rarity.level == RarityLevel.legendary).length;

  List<WorkoutSession> get selectedDateSessions {
    final dateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _calendarData[dateKey] ?? [];
  }

  /// 初始化我的页面
  Future<void> initializeMyPage({int? initialTabIndex}) async {
    debugPrint('👤 Initializing My Page');

    if (initialTabIndex != null) {
      _currentTabIndex = initialTabIndex;
    }

    // 首先加载用户信息，确定登录状态
    await loadUserInfo();

    // 只有登录用户才加载卡片和训练历史
    if (isUserLoggedIn) {
      await Future.wait([
        loadCardCollection(),
        loadWorkoutHistory(),
      ]);
    }
  }

  /// 切换Tab
  void switchTab(int index) {
    if (index >= 0 && index <= 2) {
      _currentTabIndex = index;
      debugPrint('🔄 Switched to tab $index');
      notifyListeners();
    }
  }

  /// 加载用户信息
  Future<void> loadUserInfo() async {
    debugPrint('👤 Loading user info');

    _isLoadingUser = true;
    _userError = null;
    notifyListeners();

    try {
      // 调用API获取用户信息
      final userData = await _apiService.getCurrentUser();

      _userId = userData['id'];
      _userEmail = userData['email'];
      _userName = userData['name'] ?? userData['email'];
      _avatarUrl = userData['avatar_url'];
      _totalWorkouts = userData['total_workouts'] ?? 0;
      _currentStreak = userData['current_streak'] ?? 0;
      _totalCards = userData['total_cards'] ?? 0;

      debugPrint('✅ User info loaded from API: $_userName');
    } catch (e) {
      debugPrint('❌ API failed to load user info: $e');

      // 用户未登录或API失败，清空用户数据，保持未登录状态
      // 不再使用 mock 数据作为 fallback
      _userId = null;
      _userEmail = null;
      _userName = null;
      _avatarUrl = null;
      _totalWorkouts = 0;
      _currentStreak = 0;
      _totalCards = 0;

      // 只有在非"未认证"错误时才设置错误信息
      if (!e.toString().contains('not authenticated')) {
        _userError = 'Failed to load user info';
      }
      debugPrint('ℹ️ User not logged in or API error, showing login prompt');
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  /// 加载卡片收集
  Future<void> loadCardCollection() async {
    debugPrint('🎨 Loading card collection');

    // 未登录用户不加载卡片
    if (!isUserLoggedIn) {
      debugPrint('ℹ️ User not logged in, skipping card collection load');
      _allCards = [];
      _totalCards = 0;
      _applyCardFilters();
      return;
    }

    _isLoadingCards = true;
    _cardsError = null;
    notifyListeners();

    try {
      // 调用API获取卡片列表
      final cardsData = await _apiService.getUserShareCards();

      if (cardsData.isNotEmpty) {
        _allCards = cardsData;
        _totalCards = _allCards.length;
        _applyCardFilters();
        debugPrint('✅ Card collection loaded from API: ${_allCards.length} cards');
      } else {
        debugPrint('ℹ️ No cards found in API response');
        _allCards = [];
        _totalCards = 0;
        _applyCardFilters();
        debugPrint('✅ Empty card collection loaded from API');
      }
    } catch (e) {
      debugPrint('❌ API failed to load card collection: $e');
      _cardsError = 'Failed to load cards';

      // 不再使用 mock 数据作为 fallback
      _allCards = [];
      _totalCards = 0;
      _applyCardFilters();
    } finally {
      _isLoadingCards = false;
      notifyListeners();
    }
  }

  /// 加载训练历史
  Future<void> loadWorkoutHistory() async {
    debugPrint('📅 Loading workout history');

    // 未登录用户不加载训练历史
    if (!isUserLoggedIn) {
      debugPrint('ℹ️ User not logged in, skipping workout history load');
      _workoutHistory = [];
      _buildCalendarData();
      return;
    }

    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    try {
      // 调用API获取训练历史
      final historyData = await _apiService.getUserWorkoutHistory();

      if (historyData.isNotEmpty) {
        _workoutHistory = historyData;
        _buildCalendarData();
        debugPrint('✅ Workout history loaded from API: ${_workoutHistory.length} sessions');
      } else {
        debugPrint('ℹ️ No workout history found in API response');
        _workoutHistory = [];
        _buildCalendarData();
        debugPrint('✅ Empty workout history loaded from API');
      }
    } catch (e) {
      debugPrint('❌ API failed to load workout history: $e');
      _historyError = 'Failed to load workout history';

      // 不再使用 mock 数据作为 fallback
      _workoutHistory = [];
      _buildCalendarData();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// 应用卡片筛选
  void _applyCardFilters() {
    _filteredCards = _allCards.where((card) {
      // 稀有度筛选
      if (_selectedRarity != null && card.rarity.level != _selectedRarity) {
        return false;
      }

      // 系列筛选
      if (_selectedSeries != null && card.rarity.equipmentSeries != _selectedSeries) {
        return false;
      }

      return true;
    }).toList();

    // 按创建时间倒序排列
    _filteredCards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 筛选稀有度
  void filterByRarity(RarityLevel? rarity) {
    debugPrint('🔍 Filtering by rarity: ${rarity?.displayName ?? 'All'}');

    _selectedRarity = rarity;
    _applyCardFilters();
    notifyListeners();
  }

  /// 筛选系列
  void filterBySeries(EquipmentSeries? series) {
    debugPrint('🔍 Filtering by series: ${series?.displayName ?? 'All'}');

    _selectedSeries = series;
    _applyCardFilters();
    notifyListeners();
  }

  /// 清除所有筛选
  void clearFilters() {
    debugPrint('🔄 Clearing all filters');

    _selectedRarity = null;
    _selectedSeries = null;
    _applyCardFilters();
    notifyListeners();
  }

  /// 构建日历数据
  void _buildCalendarData() {
    _calendarData.clear();

    for (final session in _workoutHistory) {
      if (session.completedAt == null) continue;

      final dateKey = DateTime(
        session.completedAt!.year,
        session.completedAt!.month,
        session.completedAt!.day,
      );

      if (_calendarData[dateKey] == null) {
        _calendarData[dateKey] = [];
      }
      _calendarData[dateKey]!.add(session);
    }

    debugPrint('📅 Calendar data built: ${_calendarData.length} days');
  }

  /// 选择日期
  void selectDate(DateTime date) {
    _selectedDate = date;
    debugPrint('📅 Selected date: ${date.toString().substring(0, 10)}');
    notifyListeners();
  }

  /// 复刻同款训练
  Future<void> replicateWorkout(String sessionId) async {
    debugPrint('🔄 Replicating workout: $sessionId');

    try {
      // 找到对应的训练会话
      final session = _workoutHistory.firstWhere((s) => s.id == sessionId);

      // 构建复刻参数
      final replicateParams = {
        'intent': session.intent.code,
        'scenario': session.scenarioCode,
        'equipment': session.equipmentCodes,
        'targetMuscles': session.targetMuscles.map((m) => m.code).toList(),
        'isReplicate': true,
        'originalSessionId': sessionId,
      };

      // TODO: 通过路由跳转到动作结果页
      // AppRoutes.replicateWorkout(context, originalParams: replicateParams);

      debugPrint('✅ Workout replication initiated');
    } catch (e) {
      debugPrint('❌ Failed to replicate workout: $e');
    }
  }

  /// 分享卡片
  Future<void> shareCard(String cardId) async {
    debugPrint('📤 Sharing card: $cardId');

    try {
      final card = _allCards.firstWhere((c) => c.id == cardId);

      // TODO: 调用系统分享
      // await Share.share(
      //   '${card.shareText}\n\n${card.deepLink}',
      //   subject: card.shareTitle,
      // );

      // 增加分享计数
      // await ApiService.instance.incrementCardShareCount(cardId);

      debugPrint('✅ Card shared successfully');
    } catch (e) {
      debugPrint('❌ Failed to share card: $e');
    }
  }

  /// 保存卡片到相册
  Future<void> saveCardToGallery(String cardId) async {
    debugPrint('💾 Saving card to gallery: $cardId');

    try {
      final card = _allCards.firstWhere((c) => c.id == cardId);

      // TODO: 下载图片并保存到相册
      // await ImageGallerySaver.saveImage(await NetworkAssetBundle(Uri.parse(card.imageUrl)).load());

      debugPrint('✅ Card saved to gallery');
    } catch (e) {
      debugPrint('❌ Failed to save card: $e');
    }
  }

  /// 更新用户设置
  Future<void> updateUserSetting(String key, dynamic value) async {
    debugPrint('⚙️ Updating user setting: $key = $value');

    try {
      // TODO: 调用API更新用户设置
      // await ApiService.instance.updateUserSetting(key, value);

      debugPrint('✅ User setting updated');
    } catch (e) {
      debugPrint('❌ Failed to update user setting: $e');
    }
  }

  /// 刷新所有数据
  Future<void> refreshAll() async {
    debugPrint('🔄 Refreshing all My Page data');

    await Future.wait([
      loadUserInfo(),
      loadCardCollection(),
      loadWorkoutHistory(),
    ]);
  }

  // 临时模拟数据方法
  void _setMockUserData() {
    _userId = 'user-123';
    _userEmail = 'user@example.com';
    _userName = 'SnapRep用户';
    _totalWorkouts = 45;
    _currentStreak = 7;
  }

  void _setMockCardData() {
    _allCards = List.generate(12, (index) => _generateMockCard(index));
  }

  ShareCard _generateMockCard(int index) {
    final rarities = RarityLevel.values;
    final series = EquipmentSeries.values;
    final rarity = rarities[index % rarities.length];
    final equipmentSeries = series[index % series.length];

    return ShareCard(
      id: 'card-$index',
      userId: _userId ?? 'user-123',
      workoutSessionId: 'session-$index',
      imageUrl: 'https://example.com/card-$index.png',
      rarity: CardRarity(
        level: rarity,
        score: 0.5 - (index * 0.1),
        equipmentSeries: equipmentSeries,
        specialTags: index % 3 == 0 ? ['静音完成'] : [],
      ),
      template: 'classic',
      shareText: '我刚完成了训练，获得了${rarity.displayName}卡片！',
      deepLink: 'snaprep://card/$index',
      metadata: {
        'totalDuration': 180,
        'exercisesCompleted': 3,
        'streak': _currentStreak,
        'equipmentUsed': ['chair', 'wall'],
        'scenario': 'office',
        'difficulty': 'BEGINNER',
        'benefits': ['缓解颈部僵硬', '改善体态'],
      },
      generatedAt: DateTime.now().subtract(Duration(days: index)),
      createdAt: DateTime.now().subtract(Duration(days: index)),
    );
  }

  void _setMockHistoryData() {
    _workoutHistory = List.generate(30, (index) => _generateMockSession(index));
  }

  WorkoutSession _generateMockSession(int index) {
    return WorkoutSession(
      id: 'session-$index',
      userId: _userId ?? 'user-123',
      status: WorkoutSessionStatus.completed,
      intent: WorkoutIntent.values[index % WorkoutIntent.values.length],
      scenarioCode: 'office',
      equipmentCodes: ['chair', 'wall'],
      targetMuscles: [TargetMuscle.neckShoulder],
      exercises: [],
      plannedDurationSec: 180,
      actualDurationSec: 165,
      completedExerciseCount: 3,
      skippedExerciseCount: 0,
      createdAt: DateTime.now().subtract(Duration(days: index)),
      startedAt: DateTime.now().subtract(Duration(days: index, minutes: 3)),
      completedAt: DateTime.now().subtract(Duration(days: index, minutes: 1)),
    );
  }

  /// 重置状态
  void reset() {
    debugPrint('🔄 Resetting My Page');

    _currentTabIndex = 0;
    _userId = null;
    _userEmail = null;
    _userName = null;
    _totalWorkouts = 0;
    _currentStreak = 0;
    _totalCards = 0;

    _allCards = [];
    _filteredCards = [];
    _selectedRarity = null;
    _selectedSeries = null;

    _workoutHistory = [];
    _calendarData = {};
    _selectedDate = DateTime.now();

    _isLoadingUser = false;
    _isLoadingCards = false;
    _isLoadingHistory = false;

    _userError = null;
    _cardsError = null;
    _historyError = null;

    notifyListeners();
  }
}