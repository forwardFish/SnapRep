import 'dart:async';
import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';

/// 训练执行状态
enum WorkoutExecutionState {
  ready,      // 准备开始
  countdown,  // 倒计时
  exercising, // 进行动作
  resting,    // 组间休息
  paused,     // 暂停
  completed,  // 完成
  cancelled,  // 取消
}

/// 训练执行Provider
/// 管理训练过程中的计时、进度、状态等
class WorkoutExecutionProvider with ChangeNotifier {
  // 工作会话数据
  WorkoutSession? _workoutSession;

  // 执行状态
  WorkoutExecutionState _state = WorkoutExecutionState.ready;

  // 当前动作索引
  int _currentExerciseIndex = 0;

  // 当前组数
  int _currentSet = 1;

  // 当前倒计时秒数
  int _currentCountdown = 0;

  // 总开始时间
  DateTime? _sessionStartTime;

  // 当前动作开始时间
  DateTime? _exerciseStartTime;

  // 暂停累计时间
  Duration _totalPausedTime = Duration.zero;

  // 暂停开始时间
  DateTime? _pauseStartTime;

  // 计时器
  Timer? _timer;

  // 动作完成记录
  final Map<int, bool> _exerciseCompletionStatus = {};

  // Getters
  WorkoutSession? get workoutSession => _workoutSession;
  WorkoutExecutionState get state => _state;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get currentSet => _currentSet;
  int get currentCountdown => _currentCountdown;
  DateTime? get sessionStartTime => _sessionStartTime;
  Duration get totalPausedTime => _totalPausedTime;

  /// 当前动作
  Exercise? get currentExercise {
    if (_workoutSession == null ||
        _currentExerciseIndex >= _workoutSession!.exercises.length) {
      return null;
    }
    return _workoutSession!.exercises[_currentExerciseIndex];
  }

  /// 总动作数
  int get totalExercises => _workoutSession?.exercises.length ?? 0;

  /// 已完成动作数
  int get completedExercises => _exerciseCompletionStatus.values.where((v) => v).length;

  /// 完成进度 (0.0 - 1.0)
  double get completionProgress {
    if (totalExercises == 0) return 0.0;
    return completedExercises / totalExercises;
  }

  /// 总耗时
  Duration get totalElapsedTime {
    if (_sessionStartTime == null) return Duration.zero;

    final now = DateTime.now();
    final rawElapsed = now.difference(_sessionStartTime!);

    // 减去暂停时间
    Duration currentPause = Duration.zero;
    if (_state == WorkoutExecutionState.paused && _pauseStartTime != null) {
      currentPause = now.difference(_pauseStartTime!);
    }

    return rawElapsed - _totalPausedTime - currentPause;
  }

  /// 当前动作耗时
  Duration get currentExerciseElapsedTime {
    if (_exerciseStartTime == null) return Duration.zero;

    final now = DateTime.now();
    return now.difference(_exerciseStartTime!);
  }

  /// 当前动作剩余时间
  int get currentExerciseRemainingSeconds {
    final exercise = currentExercise;
    if (exercise == null) return 0;

    final elapsed = currentExerciseElapsedTime.inSeconds;
    final total = exercise.durationSeconds;
    return (total - elapsed).clamp(0, total);
  }

  /// 是否可以暂停
  bool get canPause => _state == WorkoutExecutionState.exercising ||
                      _state == WorkoutExecutionState.resting;

  /// 是否可以恢复
  bool get canResume => _state == WorkoutExecutionState.paused;

  /// 是否可以跳过
  bool get canSkip => _state == WorkoutExecutionState.exercising ||
                     _state == WorkoutExecutionState.resting;

  /// 初始化训练会话
  void initializeWorkout(WorkoutSession session) {
    debugPrint('🏋️ Initializing workout: ${session.id}');

    _workoutSession = session.copyWith(
      status: WorkoutSessionStatus.pending,
      startedAt: null,
    );

    _state = WorkoutExecutionState.ready;
    _currentExerciseIndex = 0;
    _currentSet = 1;
    _currentCountdown = 0;
    _sessionStartTime = null;
    _exerciseStartTime = null;
    _totalPausedTime = Duration.zero;
    _pauseStartTime = null;
    _exerciseCompletionStatus.clear();

    // 初始化完成状态
    for (int i = 0; i < session.exercises.length; i++) {
      _exerciseCompletionStatus[i] = false;
    }

    _stopTimer();
    notifyListeners();
  }

  /// 开始训练
  void startWorkout() {
    if (_workoutSession == null || _state != WorkoutExecutionState.ready) {
      return;
    }

    debugPrint('🚀 Starting workout session');

    _sessionStartTime = DateTime.now();
    _workoutSession = _workoutSession!.copyWith(
      status: WorkoutSessionStatus.inProgress,
      startedAt: _sessionStartTime,
    );

    // 开始倒计时
    _startCountdown(3, () => _startFirstExercise());
  }

  /// 开始倒计时
  void _startCountdown(int seconds, VoidCallback onComplete) {
    _state = WorkoutExecutionState.countdown;
    _currentCountdown = seconds;

    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentCountdown--;
      notifyListeners();

      if (_currentCountdown <= 0) {
        timer.cancel();
        onComplete();
      }
    });

    notifyListeners();
  }

  /// 开始第一个动作
  void _startFirstExercise() {
    _startCurrentExercise();
  }

  /// 开始当前动作
  void _startCurrentExercise() {
    final exercise = currentExercise;
    if (exercise == null) {
      _completeWorkout();
      return;
    }

    debugPrint('🎯 Starting exercise: ${exercise.name} (${_currentExerciseIndex + 1}/$totalExercises)');

    _state = WorkoutExecutionState.exercising;
    _exerciseStartTime = DateTime.now();

    // 开始动作计时
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();

      // 检查是否完成当前动作
      if (currentExerciseRemainingSeconds <= 0) {
        timer.cancel();
        _completeCurrentExercise();
      }
    });

    notifyListeners();
  }

  /// 完成当前动作
  void _completeCurrentExercise() {
    debugPrint('✅ Exercise completed: ${currentExercise?.name}');

    _exerciseCompletionStatus[_currentExerciseIndex] = true;

    // 检查是否还有更多组数
    final exercise = currentExercise;
    if (exercise != null && _currentSet < exercise.sets) {
      _currentSet++;
      _startRestPeriod();
    } else {
      // 动作完全完成，进入下一个动作
      _currentSet = 1;
      _currentExerciseIndex++;

      if (_currentExerciseIndex >= totalExercises) {
        _completeWorkout();
      } else {
        _startRestPeriod();
      }
    }
  }

  /// 开始休息时间
  void _startRestPeriod() {
    debugPrint('⏸️ Starting rest period');

    _state = WorkoutExecutionState.resting;

    // 组间休息10秒
    _startCountdown(10, () => _startCurrentExercise());
  }

  /// 暂停训练
  void pauseWorkout() {
    if (!canPause) return;

    debugPrint('⏸️ Pausing workout');

    _state = WorkoutExecutionState.paused;
    _pauseStartTime = DateTime.now();
    _stopTimer();

    notifyListeners();
  }

  /// 恢复训练
  void resumeWorkout() {
    if (!canResume) return;

    debugPrint('▶️ Resuming workout');

    // 累计暂停时间
    if (_pauseStartTime != null) {
      _totalPausedTime += DateTime.now().difference(_pauseStartTime!);
      _pauseStartTime = null;
    }

    // 恢复之前的状态
    if (_currentCountdown > 0) {
      // 如果在倒计时中暂停，继续倒计时
      _startCountdown(_currentCountdown, () => _startCurrentExercise());
    } else {
      // 继续当前动作
      _startCurrentExercise();
    }
  }

  /// 跳过当前动作
  void skipCurrentExercise() {
    if (!canSkip) return;

    debugPrint('⏭️ Skipping exercise: ${currentExercise?.name}');

    _stopTimer();
    _completeCurrentExercise();
  }

  /// 完成训练
  void _completeWorkout() {
    debugPrint('🎉 Workout completed!');

    _state = WorkoutExecutionState.completed;
    _stopTimer();

    final completedAt = DateTime.now();
    _workoutSession = _workoutSession!.copyWith(
      status: WorkoutSessionStatus.completed,
      completedAt: completedAt,
      actualDurationSec: totalElapsedTime.inSeconds,
      completedExerciseCount: completedExercises,
      skippedExerciseCount: totalExercises - completedExercises,
    );

    notifyListeners();
  }

  /// 取消训练
  void cancelWorkout() {
    debugPrint('❌ Cancelling workout');

    _state = WorkoutExecutionState.cancelled;
    _stopTimer();

    if (_workoutSession != null) {
      _workoutSession = _workoutSession!.copyWith(
        status: WorkoutSessionStatus.cancelled,
        cancelledAt: DateTime.now(),
        actualDurationSec: totalElapsedTime.inSeconds,
        completedExerciseCount: completedExercises,
        skippedExerciseCount: totalExercises - completedExercises,
      );
    }

    notifyListeners();
  }

  /// 重置训练
  void resetWorkout() {
    debugPrint('🔄 Resetting workout');

    _stopTimer();

    _state = WorkoutExecutionState.ready;
    _currentExerciseIndex = 0;
    _currentSet = 1;
    _currentCountdown = 0;
    _sessionStartTime = null;
    _exerciseStartTime = null;
    _totalPausedTime = Duration.zero;
    _pauseStartTime = null;
    _exerciseCompletionStatus.clear();

    if (_workoutSession != null) {
      // 重新初始化完成状态
      for (int i = 0; i < _workoutSession!.exercises.length; i++) {
        _exerciseCompletionStatus[i] = false;
      }

      _workoutSession = _workoutSession!.copyWith(
        status: WorkoutSessionStatus.pending,
        startedAt: null,
        completedAt: null,
        cancelledAt: null,
        actualDurationSec: null,
        completedExerciseCount: null,
        skippedExerciseCount: null,
      );
    }

    notifyListeners();
  }

  /// 停止计时器
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 获取格式化时间字符串
  String getFormattedTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 获取当前动作进度文本
  String getCurrentExerciseProgressText() {
    return '${_currentExerciseIndex + 1} / $totalExercises';
  }

  /// 获取当前组数进度文本
  String getCurrentSetProgressText() {
    final exercise = currentExercise;
    if (exercise == null) return '1 / 1';
    return '$_currentSet / ${exercise.sets}';
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}