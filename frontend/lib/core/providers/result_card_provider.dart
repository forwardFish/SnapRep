import 'package:flutter/material.dart';
import '../models/share_card.dart';
import '../models/workout_session.dart';
import '../services/api_service.dart';

/// 成果卡片页状态管理Provider
/// 管理卡片生成、加载、分享等功能
class ResultCardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  // 当前卡片数据
  ShareCard? _currentCard;

  // 关联的训练会话数据
  WorkoutSession? _workoutSession;

  // 训练统计数据
  Duration? _actualDuration;
  int? _caloriesBurned;
  int? _exercisesCompleted;
  DateTime? _completionDate;

  // 加载状态
  bool _isLoading = false;
  bool _isGeneratingCard = false;
  bool _isSharing = false;

  // 错误信息
  String? _error;

  // Getters
  ShareCard? get currentCard => _currentCard;
  WorkoutSession? get workoutSession => _workoutSession;
  Duration? get actualDuration => _actualDuration;
  int? get caloriesBurned => _caloriesBurned;
  int? get exercisesCompleted => _exercisesCompleted;
  DateTime? get completionDate => _completionDate;
  bool get isLoading => _isLoading;
  bool get isGeneratingCard => _isGeneratingCard;
  bool get isSharing => _isSharing;
  String? get error => _error;

  // 计算属性
  bool get hasCardData => _currentCard != null;
  bool get hasWorkoutData => _workoutSession != null;
  String get cardTitle => _currentCard?.shareText ?? 'Workout Complete!';
  String get cardSubtitle => _currentCard?.rarity.description ?? "Amazing job! You've earned a new achievement card";

  /// 加载卡片数据
  /// 支持两种模式：
  /// 1. 生成模式：提供sessionId，生成新卡片
  /// 2. 查看模式：提供cardId，加载已有卡片
  Future<void> loadCardData({
    String? sessionId,
    String? cardId,
  }) async {
    debugPrint('🎨 Loading card data - sessionId: $sessionId, cardId: $cardId');

    _setLoading(true);
    _clearError();

    try {
      if (cardId != null) {
        // 查看模式：加载已有卡片
        await _loadExistingCard(cardId);
      } else if (sessionId != null) {
        // 生成模式：创建新卡片
        await _generateNewCard(sessionId);
      } else {
        throw Exception('需要提供sessionId或cardId');
      }

      debugPrint('✅ Card data loaded successfully');
    } catch (e) {
      _setError('加载卡片失败: ${e.toString()}');
      debugPrint('❌ Failed to load card data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载已有卡片
  Future<void> _loadExistingCard(String cardId) async {
    debugPrint('📋 Loading existing card: $cardId');

    try {
      _currentCard = await _apiService.getShareCard(cardId);

      // 尝试加载关联的训练会话数据
      if (_currentCard!.workoutSessionId.isNotEmpty) {
        await _loadWorkoutSessionData(_currentCard!.workoutSessionId);
      }

      debugPrint('✅ Existing card loaded successfully');
    } catch (e) {
      debugPrint('❌ API failed to load existing card: $e');
      final errorMsg = 'Failed to load card: ${e.toString().split(':').first}';
      _setError(errorMsg);

      // 如果API失败，使用基础数据创建fallback卡片
      debugPrint('⚠️ Creating fallback card as emergency measure');
      _createFallbackCard(cardId: cardId);
    }
  }

  /// 生成新卡片
  Future<void> _generateNewCard(String sessionId) async {
    debugPrint('🎨 Generating new card for session: $sessionId');

    _setGeneratingCard(true);

    try {
      // 首先加载训练会话数据
      await _loadWorkoutSessionData(sessionId);

      // 生成新卡片
      _currentCard = await _apiService.generateResultCard(
        sessionId: sessionId,
        template: 'classic',
      );

      debugPrint('✅ New card generated successfully: ${_currentCard!.id}');
    } catch (e) {
      debugPrint('❌ API failed to generate new card: $e');
      final errorMsg = 'Failed to generate card: ${e.toString().split(':').first}';
      _setError(errorMsg);

      // 如果API失败，创建fallback卡片
      debugPrint('⚠️ Creating fallback card as emergency measure');
      _createFallbackCard(sessionId: sessionId);
    } finally {
      _setGeneratingCard(false);
    }
  }

  /// 加载训练会话数据
  Future<void> _loadWorkoutSessionData(String sessionId) async {
    debugPrint('📊 Loading workout session data: $sessionId');

    try {
      _workoutSession = await _apiService.getWorkoutSession(sessionId);

      // 从会话中提取统计数据
      _actualDuration = _workoutSession!.actualDurationSec != null
          ? Duration(seconds: _workoutSession!.actualDurationSec!)
          : Duration(seconds: _workoutSession!.plannedDurationSec);

      _caloriesBurned = _workoutSession!.actualCalories ??
                      _workoutSession!.estimatedCalories ?? 100;

      _exercisesCompleted = _workoutSession!.completedExerciseCount ??
                          _workoutSession!.exercises.length;

      _completionDate = _workoutSession!.completedAt ?? DateTime.now();

      debugPrint('✅ Workout session data loaded');
    } catch (e) {
      debugPrint('❌ Failed to load workout session data: $e');
      final errorMsg = 'Failed to load workout data: ${e.toString().split(':').first}';
      _setError(errorMsg);

      // 使用默认统计数据作为emergency fallback
      debugPrint('⚠️ Using default workout stats as emergency measure');
      _actualDuration = const Duration(minutes: 5);
      _caloriesBurned = 50;
      _exercisesCompleted = 3;
      _completionDate = DateTime.now();
    }
  }

  /// 分享卡片
  Future<void> shareCard() async {
    if (_currentCard == null) {
      _setError('没有可分享的卡片');
      return;
    }

    debugPrint('📤 Sharing card: ${_currentCard!.id}');

    _setSharing(true);
    _clearError();

    try {
      // 增加分享计数
      await _apiService.incrementCardShareCount(_currentCard!.id);

      // 这里可以添加实际的分享逻辑，比如调用系统分享
      debugPrint('✅ Card shared successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to increment share count: $e');
      // 即使API失败，分享功能仍然可以继续
    } finally {
      _setSharing(false);
    }
  }

  /// 创建fallback卡片（当API失败时）
  void _createFallbackCard({String? sessionId, String? cardId}) {
    debugPrint('🔄 Creating fallback card');

    final fallbackId = cardId ?? 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    _currentCard = ShareCard(
      id: fallbackId,
      userId: 'fallback_user',
      workoutSessionId: sessionId ?? '',
      imageUrl: '',
      rarity: const CardRarity(
        level: RarityLevel.common,
        score: 0.5,
        equipmentSeries: EquipmentSeries.bodyweight,
        specialTags: ['Beginner Friendly'],
      ),
      template: 'classic',
      shareText: 'Workout Complete!',
      deepLink: '',
      metadata: const {
        'timeCompleted': '5:00',
        'caloriesBurned': 50,
        'exercisesCompleted': 3,
      },
      isPublic: false,
      shareCount: 0,
      favoriteCount: 0,
      generatedAt: now,
      createdAt: now,
    );

    // 设置默认统计数据
    _actualDuration = const Duration(minutes: 5);
    _caloriesBurned = 50;
    _exercisesCompleted = 3;
    _completionDate = DateTime.now();

    debugPrint('✅ Fallback card created');
  }

  // 私有辅助方法
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setGeneratingCard(bool generating) {
    _isGeneratingCard = generating;
    notifyListeners();
  }

  void _setSharing(bool sharing) {
    _isSharing = sharing;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// 重置状态
  void reset() {
    debugPrint('🔄 Resetting result card state');

    _currentCard = null;
    _workoutSession = null;
    _actualDuration = null;
    _caloriesBurned = null;
    _exercisesCompleted = null;
    _completionDate = null;
    _isLoading = false;
    _isGeneratingCard = false;
    _isSharing = false;
    _error = null;

    notifyListeners();
  }
}