import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const SnapRepApp());
}

class SnapRepApp extends StatelessWidget {
  const SnapRepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SnapRep',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cyan,
          brightness: Brightness.dark,
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppColors {
  static const bg = Color(0xFF02070C);
  static const bg2 = Color(0xFF07111A);
  static const card = Color(0xFF0B1721);
  static const card2 = Color(0xFF111D29);
  static const border = Color(0xFF21313D);
  static const cyan = Color(0xFF28E6FF);
  static const cyan2 = Color(0xFF3DCAFF);
  static const purple = Color(0xFF8E5CFF);
  static const orange = Color(0xFFFFA12B);
  static const red = Color(0xFFFF4D65);
  static const green = Color(0xFF52EA7E);
  static const muted = Color(0xFF8EA0AD);
  static const white = Color(0xFFF7FAFF);
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onTab: (v) => setState(() => index = v)),
      const CameraScreen(),
      ProfileScreen(onHistory: () {
        Navigator.of(context).push(pageRoute(const HistoryScreen()));
      }),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[index],
      bottomNavigationBar: NeonBottomNav(
        index: index,
        onChanged: (v) => setState(() => index = v),
      ),
    );
  }
}

PageRouteBuilder<T> pageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.04, 0.02), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class NeonBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const NeonBottomNav({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xE50A1118),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.08),
                  blurRadius: 28,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: '首页', active: index == 0, onTap: () => onChanged(0)),
                _NavItem(icon: Icons.camera_alt_outlined, label: '相机', active: index == 1, onTap: () => onChanged(1)),
                _NavItem(icon: Icons.person_outline_rounded, label: '我的', active: index == 2, onTap: () => onChanged(2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 27, color: active ? AppColors.cyan : Colors.white.withOpacity(0.62)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.cyan : Colors.white.withOpacity(0.62),
                fontSize: 13,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onTab;
  const HomeScreen({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return AppPageFrame(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 112),
        children: [
          const SizedBox(height: 28),
          Row(
            children: [
              const SnapLogo(size: 29),
              const Spacer(),
              _StreakPill(days: 7),
            ],
          ),
          const SizedBox(height: 20),
          HomeHeroCard(
            onStart: () => Navigator.of(context).push(pageRoute(const WorkoutResultScreen())),
          ),
          SectionHeader(
            title: '场景',
            action: '查看全部',
            onTap: () => Navigator.of(context).push(pageRoute(const GuideStep2Screen())),
          ),
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: sceneItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SceneCard(item: sceneItems[i], compact: false),
            ),
          ),
          SectionHeader(
            title: '物品',
            action: '拍照识别',
            icon: Icons.photo_camera_outlined,
            onTap: () => onTab(1),
          ),
          SizedBox(
            height: 142,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: objectItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => ObjectCard(item: objectItems[i]),
            ),
          ),
          const SectionHeader(title: '主题周'),
          const ThemeWeekBlock(),
          const SizedBox(height: 20),
          const ChallengeBanner(),
        ],
      ),
    );
  }
}

class HomeHeroCard extends StatelessWidget {
  final VoidCallback onStart;
  const HomeHeroCard({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      height: 222,
      radius: 28,
      padding: const EdgeInsets.all(22),
      gradient: const LinearGradient(
        colors: [Color(0xFF08121D), Color(0xFF03070D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Stack(
        children: [
          Positioned(right: -10, top: -18, bottom: -18, width: 180, child: const HeroAthleteVisual()),
          Positioned(left: 0, top: 18, child: Icon(Icons.flash_on_rounded, color: AppColors.cyan, size: 30)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1.8, height: 1.05),
                  children: [
                    TextSpan(text: '给我', style: TextStyle(color: Colors.white)),
                    TextSpan(text: '60', style: TextStyle(color: AppColors.cyan)),
                    TextSpan(text: '秒', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('随时随地，3个动作开启训练', style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              NeonButton(label: '给我60秒', icon: Icons.flash_on_rounded, width: 170, onTap: onStart),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, color: Colors.white.withOpacity(0.58), size: 18),
                  const SizedBox(width: 6),
                  Text('30秒内获得专属方案', style: TextStyle(color: Colors.white.withOpacity(0.56), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HeroAthleteVisual extends StatelessWidget {
  const HeroAthleteVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AthletePainter(),
    );
  }
}

class AthletePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..shader = const SweepGradient(colors: [AppColors.cyan, AppColors.purple, AppColors.cyan]).createShader(Rect.fromCircle(center: Offset(size.width * .55, size.height * .48), radius: 76));
    canvas.drawCircle(Offset(size.width * .55, size.height * .48), 76, ringPaint);

    final body = Paint()..color = Colors.white.withOpacity(.9);
    final cyan = Paint()..color = AppColors.cyan.withOpacity(.72);
    final shadow = Paint()..color = Colors.black.withOpacity(.6);

    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .55, size.height * .28), width: 30, height: 36), body);
    final torso = Path()
      ..moveTo(size.width * .45, size.height * .35)
      ..lineTo(size.width * .66, size.height * .34)
      ..lineTo(size.width * .75, size.height * .58)
      ..lineTo(size.width * .47, size.height * .60)
      ..close();
    canvas.drawPath(torso, shadow);
    canvas.drawLine(Offset(size.width * .50, size.height * .42), Offset(size.width * .24, size.height * .70), Paint()..color = Colors.white.withOpacity(.82)..strokeWidth = 10..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(size.width * .71, size.height * .45), Offset(size.width * .92, size.height * .72), Paint()..color = Colors.white.withOpacity(.82)..strokeWidth = 10..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(size.width * .54, size.height * .58), Offset(size.width * .20, size.height * .82), Paint()..color = AppColors.cyan.withOpacity(.9)..strokeWidth = 12..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(size.width * .70, size.height * .58), Offset(size.width * .98, size.height * .78), Paint()..color = Colors.white.withOpacity(.72)..strokeWidth = 12..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(size.width * .51, size.height * .43), 8, cyan);
    canvas.drawCircle(Offset(size.width * .68, size.height * .44), 8, cyan);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GuideStep1Screen extends StatelessWidget {
  const GuideStep1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageFrame(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          child: Column(
            children: [
              const TopBar(title: 'SnapRep', trailing: '跳过'),
              const SizedBox(height: 40),
              const ProgressPill(text: '1 / 3', icon: Icons.flash_on_rounded),
              const SizedBox(height: 26),
              const BigTitle(before: '今天想', highlight: '怎么动', after: '？', subtitle: '不纠结，先选感觉'),
              const SizedBox(height: 34),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: .88,
                  children: const [
                    IntentCard(title: '放松', desc: '降紧张 / 舒缓身心', icon: Icons.nightlight_round, selected: false),
                    IntentCard(title: '舒展筋骨', desc: '拉伸与活动度', icon: Icons.self_improvement_rounded, selected: true),
                    IntentCard(title: '适当运动', desc: '轻汗 / 微心率', icon: Icons.directions_run_rounded, selected: false),
                    IntentCard(title: '主体锻炼', desc: '轻力量 / 稳定性', icon: Icons.fitness_center_rounded, selected: false),
                  ],
                ),
              ),
              QuickStartStrip(),
              const SizedBox(height: 18),
              NeonButton(label: '下一步：选择场景', height: 60, onTap: () => Navigator.of(context).push(pageRoute(const GuideStep2Screen()))),
            ],
          ),
        ),
      ),
    );
  }
}

class GuideStep2Screen extends StatelessWidget {
  const GuideStep2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageFrame(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(title: 'SnapRep', trailing: '跳过'),
              const SizedBox(height: 34),
              const BigTitle(before: '你在哪里', highlight: '练', after: '？有啥东西？', subtitle: '没有也能练'),
              const SizedBox(height: 26),
              const StepLabel(num: 1, text: '选择场景'),
              const SizedBox(height: 14),
              SizedBox(
                height: 142,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sceneItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SelectSceneCard(item: sceneItems[i], selected: i == 0),
                ),
              ),
              const SizedBox(height: 24),
              const StepLabel(num: 2, text: '选择物品（可多选）'),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: .78,
                  children: objectItems.take(8).map((e) => SelectObjectCard(item: e, selected: e.title == '椅子')).toList(),
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(pageRoute(const CameraScreen(showBack: true))),
                  icon: const Icon(Icons.help_outline_rounded, color: AppColors.cyan),
                  label: Text('不知道？稍后拍摄识别  ›', style: TextStyle(color: AppColors.cyan.withOpacity(.95), fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              NeonButton(label: '下一步：选择重点部位', icon: Icons.flash_on_rounded, height: 60, onTap: () => Navigator.of(context).push(pageRoute(const GuideStep3Screen()))),
            ],
          ),
        ),
      ),
    );
  }
}

class GuideStep3Screen extends StatelessWidget {
  const GuideStep3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageFrame(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          child: Column(
            children: [
              const TopBar(title: 'SnapRep'),
              const SizedBox(height: 18),
              const BigTitle(before: '想', highlight: '重点', after: '练哪里？', subtitle: '可多选（最多2个）'),
              const SizedBox(height: 20),
              Expanded(child: BodyTargetVisual()),
              SizedBox(
                height: 126,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: bodyTargets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => TargetCard(item: bodyTargets[i], selected: i == 1),
                ),
              ),
              const SizedBox(height: 22),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.muted),
                  children: [
                    TextSpan(text: '已选 '),
                    TextSpan(text: '1', style: TextStyle(color: AppColors.cyan, fontSize: 26, fontWeight: FontWeight.w900)),
                    TextSpan(text: ' / 2'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              NeonButton(label: '生成我的3个动作', height: 60, onTap: () => Navigator.of(context).push(pageRoute(const WorkoutResultScreen()))),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutResultScreen extends StatelessWidget {
  const WorkoutResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageFrame(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: TopBar(title: '为你推荐'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 102),
                children: [
                  Row(
                    children: const [
                      InfoCapsule(icon: Icons.chair_alt_rounded, label: '物品：椅子'),
                      SizedBox(width: 10),
                      InfoCapsule(icon: Icons.work_rounded, label: '场景：办公室'),
                      SizedBox(width: 10),
                      InfoCapsule(icon: Icons.bar_chart_rounded, label: '难度：初级'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...workoutCards.asMap().entries.map((entry) => WorkoutCard(index: entry.key + 1, data: entry.value)),
                  const SizedBox(height: 10),
                  Text('替换单卡', style: sectionTitleStyle()),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: alternatives.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => MiniExerciseCard(data: alternatives[i]),
                    ),
                  ),
                ],
              ),
            ),
            BottomActionBar(
              leftText: '换一批',
              centerText: '开始跟练',
              rightText: '成果卡',
              onLeft: () {},
              onCenter: () {},
              onRight: () => Navigator.of(context).push(pageRoute(const ResultCardScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultCardScreen extends StatelessWidget {
  const ResultCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageFrame(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          children: [
            const TopBar(title: ''),
            const SizedBox(height: 16),
            const SnapLogo(size: 36),
            const SizedBox(height: 24),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 43, fontWeight: FontWeight.w900, height: 1.08, letterSpacing: -1.2),
                children: [
                  TextSpan(text: '椅子日', style: TextStyle(color: AppColors.cyan)),
                  TextSpan(text: '挑战完成！', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('2024.07.20', style: TextStyle(color: Colors.white.withOpacity(.45), fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 22),
            NeonCard(
              height: 350,
              radius: 34,
              padding: EdgeInsets.zero,
              child: Stack(
                children: const [
                  Positioned.fill(child: ChairPosterVisual()),
                  Positioned(left: 24, bottom: 24, child: AchievementBadge()),
                ],
              ),
            ),
            const SizedBox(height: 22),
            NeonCard(
              radius: 24,
              padding: const EdgeInsets.all(22),
              child: Column(
                children: const [
                  StatLine(icon: Icons.flash_on_rounded, label: '完成动作', value: '3 个'),
                  Divider(color: AppColors.border, height: 28),
                  StatLine(icon: Icons.schedule_rounded, label: '训练总长', value: '1 分钟'),
                  Divider(color: AppColors.border, height: 28),
                  StatLine(icon: Icons.chair_alt_rounded, label: '训练场景', value: '办公室'),
                  Divider(color: AppColors.border, height: 28),
                  StatLine(icon: Icons.bar_chart_rounded, label: '难度等级', value: '初级'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Text('坚持运动，遇见更好的自己！', style: TextStyle(color: Colors.white.withOpacity(.92), fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: GhostButton(label: '保存到相册', icon: Icons.download_rounded, onTap: () {})),
                const SizedBox(width: 12),
                Expanded(child: NeonButton(label: '立即分享', icon: Icons.ios_share_rounded, onTap: () {})),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final VoidCallback onHistory;
  const ProfileScreen({super.key, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return AppPageFrame(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 42, 18, 112),
        children: [
          Center(child: Text('我的', style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w900))),
          const SizedBox(height: 24),
          NeonCard(
            radius: 30,
            padding: const EdgeInsets.all(20),
            gradient: const LinearGradient(colors: [Color(0xFF0B1A26), Color(0xFF071018)]),
            child: Column(
              children: [
                Row(
                  children: [
                    const AvatarRing(),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Hi，健身达人 👋', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
                          SizedBox(height: 8),
                          Text('连续运动 12 天', style: TextStyle(color: AppColors.muted, fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: const [
                    ProfileStat(value: '36', label: '收藏卡片'),
                    ProfileStat(value: '28', label: '训练次数'),
                    ProfileStat(value: '12', label: '连续天数'),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader(title: '卡片收藏', action: '训练记录', onTapLabel: true),
          Row(
            children: objectItems.take(4).map((e) => Expanded(child: CollectionSeriesCard(item: e))).toList(),
          ),
          SectionHeader(title: '最近收集', action: '查看全部', onTap: onHistory),
          SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profileCards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => CollectibleCard(data: profileCards[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageFrame(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
          children: const [
            TopBar(title: '训练记录'),
            SizedBox(height: 22),
            CalendarBlock(),
            SizedBox(height: 22),
            HistoryDayCard(),
          ],
        ),
      ),
    );
  }
}

class CameraScreen extends StatelessWidget {
  final bool showBack;
  const CameraScreen({super.key, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return AppPageFrame(
      child: Stack(
        children: [
          const Positioned.fill(child: RoomCameraVisual()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (showBack) RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)) else const SnapLogo(size: 28),
                      const Spacer(),
                      if (!showBack) const _StreakPill(days: 7),
                    ],
                  ),
                  const SizedBox(height: 42),
                  const FrostPill(text: '将镜头对准身边的物品'),
                  const Spacer(),
                  const ScanCorners(),
                  const Spacer(),
                  const RecognitionPanel(),
                  const SizedBox(height: 20),
                  const CameraControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppPageFrame extends StatelessWidget {
  final Widget child;
  const AppPageFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [Color(0xFF092030), AppColors.bg],
        ),
      ),
      child: child,
    );
  }
}

class SnapLogo extends StatelessWidget {
  final double size;
  const SnapLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.1),
        children: const [
          TextSpan(text: 'Snap', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'Rep', style: TextStyle(color: AppColors.cyan)),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int days;
  const _StreakPill({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: AppColors.cyan, size: 18),
          const SizedBox(width: 6),
          Text('连续打卡 ', style: TextStyle(color: Colors.white.withOpacity(.86), fontSize: 14, fontWeight: FontWeight.w800)),
          Text('$days', style: const TextStyle(color: AppColors.cyan, fontSize: 22, fontWeight: FontWeight.w900)),
          const Text(' 天', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class NeonCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  const NeonCard({super.key, required this.child, this.height, this.radius = 24, this.padding = const EdgeInsets.all(16), this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? const LinearGradient(colors: [Color(0xFF0B1721), Color(0xFF071018)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(.085)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: AppColors.cyan.withOpacity(.05), blurRadius: 36),
        ],
      ),
      child: child,
    );
  }
}

class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double? width;
  final double height;

  const NeonButton({super.key, required this.label, required this.onTap, this.icon, this.width, this.height = 52});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cyan,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(.35), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.black, size: 22),
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const GhostButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.04),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, color: Colors.white.withOpacity(.85), size: 20), const SizedBox(width: 8), Text(label, style: TextStyle(color: Colors.white.withOpacity(.9), fontWeight: FontWeight.w800))],
        ),
      ),
    );
  }
}

TextStyle sectionTitleStyle() => const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900);

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool onTapLabel;

  const SectionHeader({super.key, required this.title, this.action, this.icon, this.onTap, this.onTapLabel = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 14),
      child: Row(
        children: [
          Container(width: 5, height: 24, decoration: BoxDecoration(color: AppColors.cyan, borderRadius: BorderRadius.circular(9))),
          const SizedBox(width: 10),
          Text(title, style: sectionTitleStyle()),
          const Spacer(),
          if (action != null)
            InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  if (icon != null) Icon(icon, size: 18, color: Colors.white.withOpacity(.72)),
                  if (icon != null) const SizedBox(width: 6),
                  Text(action!, style: TextStyle(color: onTapLabel ? AppColors.cyan : Colors.white.withOpacity(.64), fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(.62), size: 22),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  final String title;
  final String? trailing;
  const TopBar({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.maybePop(context)),
          const Spacer(),
          if (title == 'SnapRep') const SnapLogo(size: 25) else Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const Spacer(),
          SizedBox(
            width: 44,
            child: trailing != null ? Text(trailing!, textAlign: TextAlign.right, style: TextStyle(color: Colors.white.withOpacity(.66), fontSize: 15, fontWeight: FontWeight.w700)) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: Colors.white.withOpacity(.05), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(.1))),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class SceneItem {
  final String title, desc;
  final IconData icon;
  final Color color;
  const SceneItem(this.title, this.desc, this.icon, this.color);
}

const sceneItems = [
  SceneItem('办公室', '工间燃脂，效率加倍', Icons.work_rounded, Color(0xFF4C65FF)),
  SceneItem('客厅/沙发', '在家也能高效训练', Icons.weekend_rounded, Color(0xFFD447FF)),
  SceneItem('起床后', '唤醒身体，活力满满', Icons.wb_sunny_rounded, Color(0xFFFFB92E)),
  SceneItem('睡前放松', '放松身心，助眠舒缓', Icons.nightlight_round, Color(0xFF6A5BFF)),
  SceneItem('旅途中', '小空间轻练', Icons.luggage_rounded, Color(0xFF31D8FF)),
  SceneItem('楼梯/台阶', '强阶训练', Icons.stairs_rounded, Color(0xFF28E6FF)),
];

class ObjectItem {
  final String title, desc;
  final IconData icon;
  const ObjectItem(this.title, this.desc, this.icon);
}

const objectItems = [
  ObjectItem('空手', '无需器械', Icons.back_hand_rounded),
  ObjectItem('椅子', '稳定支撑', Icons.chair_alt_rounded),
  ObjectItem('墙面', '支撑训练', Icons.grid_view_rounded),
  ObjectItem('水瓶', '灵活负重', Icons.water_drop_rounded),
  ObjectItem('背包', '增加挑战', Icons.backpack_rounded),
  ObjectItem('台阶', '强阶训练', Icons.stairs_rounded),
  ObjectItem('沙发', '居家训练', Icons.weekend_rounded),
  ObjectItem('毛巾', '拉伸辅助', Icons.layers_rounded),
];

class SceneCard extends StatelessWidget {
  final SceneItem item;
  final bool compact;
  const SceneCard({super.key, required this.item, this.compact = true});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      height: null,
      radius: 18,
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(colors: [item.color.withOpacity(.28), const Color(0xFF071018)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleIcon(icon: item.icon, color: item.color),
            const Spacer(),
            Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(item.desc, style: TextStyle(color: Colors.white.withOpacity(.62), fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

extension NeonCardSize on NeonCard {
  Widget withWidth(double width) => SizedBox(width: width, child: this);
}

class ObjectCard extends StatelessWidget {
  final ObjectItem item;
  const ObjectCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 108,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: AppColors.cyan, size: 42),
            const SizedBox(height: 14),
            Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(item.desc, style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const CircleIcon({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: color.withOpacity(.18), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(.3))),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class ThemeWeekBlock extends StatelessWidget {
  const ThemeWeekBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: NeonCard(
            height: 160,
            radius: 20,
            padding: const EdgeInsets.all(18),
            gradient: const LinearGradient(colors: [Color(0xFF092C3B), Color(0xFF071018)]),
            child: Stack(
              children: [
                const Positioned(right: 10, bottom: 0, child: Icon(Icons.chair_alt_rounded, color: AppColors.cyan, size: 86)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('本周主题', style: TextStyle(color: Colors.white.withOpacity(.55), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    const Text('本周：#椅子日', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('用椅子动三下，完成燃脂挑战', style: TextStyle(color: Colors.white.withOpacity(.72), fontWeight: FontWeight.w700)),
                    const Spacer(),
                    NeonButton(label: '一键加入 🚀', width: 138, height: 40, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            children: const [
              PreviewThemeCard(title: '#水瓶周', date: '7月20日开启', icon: Icons.water_drop_rounded),
              SizedBox(height: 12),
              PreviewThemeCard(title: '#背包周', date: '7月27日开启', icon: Icons.backpack_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

class PreviewThemeCard extends StatelessWidget {
  final String title, date;
  final IconData icon;
  const PreviewThemeCard({super.key, required this.title, required this.date, required this.icon});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      height: 74,
      radius: 16,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('下周预告', style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), Text(date, style: TextStyle(color: Colors.white.withOpacity(.48), fontSize: 11))])),
          Icon(icon, color: AppColors.purple, size: 34),
        ],
      ),
    );
  }
}

class ChallengeBanner extends StatelessWidget {
  const ChallengeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      height: 120,
      radius: 22,
      padding: const EdgeInsets.all(18),
      gradient: const LinearGradient(colors: [Color(0xFF0D778D), Color(0xFF071018)]),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('物品挑战赛', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text('用身边物品完成训练，赢取限定奖励', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)), Spacer(), Text('👥 12.3k 人已参与', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800))])),
          const Icon(Icons.emoji_events_rounded, color: AppColors.cyan, size: 56),
          const SizedBox(width: 10),
          NeonButton(label: '发现挑战 🏆', width: 130, height: 42, onTap: () {}),
        ],
      ),
    );
  }
}

class ProgressPill extends StatelessWidget {
  final String text;
  final IconData icon;
  const ProgressPill({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cyan.withOpacity(.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cyan.withOpacity(.55)),
          boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(.24), blurRadius: 22)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(text, style: const TextStyle(color: AppColors.cyan, fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(width: 12), Icon(icon, color: AppColors.cyan)]),
      ),
    );
  }
}

class BigTitle extends StatelessWidget {
  final String before, highlight, after, subtitle;
  const BigTitle({super.key, required this.before, required this.highlight, required this.after, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, height: 1.12, letterSpacing: -1.4), children: [TextSpan(text: before, style: const TextStyle(color: Colors.white)), TextSpan(text: highlight, style: const TextStyle(color: AppColors.cyan)), TextSpan(text: after, style: const TextStyle(color: Colors.white))]),
        ),
        const SizedBox(height: 12),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 19, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class IntentCard extends StatelessWidget {
  final String title, desc;
  final IconData icon;
  final bool selected;
  const IntentCard({super.key, required this.title, required this.desc, required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(colors: [selected ? AppColors.cyan.withOpacity(.14) : Colors.white.withOpacity(.04), const Color(0xFF071018)]),
      child: Stack(
        children: [
          if (selected) const Positioned(right: 0, top: 0, child: CircleAvatar(radius: 18, backgroundColor: AppColors.cyan, child: Icon(Icons.check_rounded, color: Colors.black, size: 24))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleIcon(icon: icon, color: selected ? AppColors.cyan : AppColors.purple),
              const Spacer(),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(desc, style: TextStyle(color: Colors.white.withOpacity(.62), fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickStartStrip extends StatelessWidget {
  const QuickStartStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleIcon(icon: Icons.flash_on_rounded, color: AppColors.cyan),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('直接开练60秒 ✨', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)), SizedBox(height: 6), Text('默认模板：舒展 → 活动 → 力量 20s × 3', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))])),
          const Icon(Icons.water_drop_rounded, color: AppColors.cyan, size: 46),
        ],
      ),
    );
  }
}

class StepLabel extends StatelessWidget {
  final int num;
  final String text;
  const StepLabel({super.key, required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.cyan, borderRadius: BorderRadius.circular(10)), child: Text('$num', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18))), const SizedBox(width: 10), Text(text, style: sectionTitleStyle())]);
  }
}

class SelectSceneCard extends StatelessWidget {
  final SceneItem item;
  final bool selected;
  const SelectSceneCard({super.key, required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: selected ? AppColors.cyan : Colors.white.withOpacity(.1), width: selected ? 2 : 1),
        gradient: LinearGradient(colors: [item.color.withOpacity(.25), const Color(0xFF071018)]),
        boxShadow: selected ? [BoxShadow(color: AppColors.cyan.withOpacity(.25), blurRadius: 26)] : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(alignment: Alignment.topRight, child: selected ? const CircleAvatar(radius: 15, backgroundColor: AppColors.cyan, child: Icon(Icons.check_rounded, color: Colors.black, size: 20)) : const SizedBox(height: 30)),
          const Spacer(),
          CircleIcon(icon: item.icon, color: item.color),
          const SizedBox(height: 14),
          Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class SelectObjectCard extends StatelessWidget {
  final ObjectItem item;
  final bool selected;
  const SelectObjectCard({super.key, required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 18,
      padding: const EdgeInsets.all(10),
      gradient: LinearGradient(colors: [selected ? AppColors.cyan.withOpacity(.12) : Colors.white.withOpacity(.035), const Color(0xFF071018)]),
      child: Stack(
        children: [
          Positioned(right: 0, top: 0, child: Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: selected ? AppColors.cyan : Colors.white.withOpacity(.62))),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item.icon, color: AppColors.cyan, size: 38), const SizedBox(height: 14), Center(child: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)))])
        ],
      ),
    );
  }
}

const bodyTargets = [
  ObjectItem('上肢', '手臂 / 肩部 / 胸部', Icons.accessibility_new_rounded),
  ObjectItem('核心', '腹部 / 腰部 / 核心', Icons.blur_circular_rounded),
  ObjectItem('下肢', '腿部 / 臀部', Icons.directions_walk_rounded),
  ObjectItem('全身', '全面训练', Icons.person_rounded),
];

class BodyTargetVisual extends StatelessWidget {
  const BodyTargetVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: BodyPainter(), child: const SizedBox.expand());
  }
}

class BodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height * .05;
    final glow = Paint()..color = AppColors.cyan.withOpacity(.20)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(Offset(centerX, size.height * .46), size.width * .38, glow);
    final body = Paint()..color = Colors.white.withOpacity(.72)..strokeWidth = 10..strokeCap = StrokeCap.round;
    final hi = Paint()..color = AppColors.cyan.withOpacity(.72)..strokeWidth = 18..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(centerX, baseY + 40), 24, body);
    canvas.drawLine(Offset(centerX, baseY + 70), Offset(centerX, baseY + 185), body);
    canvas.drawLine(Offset(centerX - 70, baseY + 95), Offset(centerX + 70, baseY + 95), body);
    canvas.drawLine(Offset(centerX - 58, baseY + 100), Offset(centerX - 105, baseY + 180), body);
    canvas.drawLine(Offset(centerX + 58, baseY + 100), Offset(centerX + 105, baseY + 180), body);
    canvas.drawLine(Offset(centerX, baseY + 185), Offset(centerX - 55, baseY + 300), body);
    canvas.drawLine(Offset(centerX, baseY + 185), Offset(centerX + 55, baseY + 300), body);
    canvas.drawLine(Offset(centerX - 36, baseY + 120), Offset(centerX + 36, baseY + 120), hi);
    canvas.drawLine(Offset(centerX, baseY + 132), Offset(centerX, baseY + 178), hi);
    canvas.drawCircle(Offset(centerX, baseY + 160), 28, Paint()..color = AppColors.cyan.withOpacity(.36));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TargetCard extends StatelessWidget {
  final ObjectItem item;
  final bool selected;
  const TargetCard({super.key, required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(colors: [selected ? AppColors.cyan.withOpacity(.13) : Colors.white.withOpacity(.035), const Color(0xFF071018)]),
      child: SizedBox(
        width: 124,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Align(alignment: Alignment.topRight, child: Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: selected ? AppColors.cyan : Colors.white60)), const Spacer(), Icon(item.icon, color: AppColors.cyan, size: 46), const SizedBox(height: 12), Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(item.desc, style: TextStyle(color: Colors.white.withOpacity(.56), fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)]),
      ),
    );
  }
}

class InfoCapsule extends StatelessWidget {
  final IconData icon;
  final String label;
  const InfoCapsule({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.05), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(.1))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: AppColors.cyan, size: 18), const SizedBox(width: 7), Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)))]),
      ),
    );
  }
}

class WorkoutData {
  final String title, part;
  final IconData icon;
  const WorkoutData(this.title, this.part, this.icon);
}

const workoutCards = [
  WorkoutData('椅子辅助深蹲', '下肢 / 臀部', Icons.airline_seat_recline_extra_rounded),
  WorkoutData('椅子臂屈伸', '上肢 / 手臂', Icons.fitness_center_rounded),
  WorkoutData('椅子仰卧抬腿', '核心 / 腹部', Icons.self_improvement_rounded),
];

const alternatives = [
  WorkoutData('椅子前步蹲', '下肢 / 臀部', Icons.directions_walk_rounded),
  WorkoutData('椅子提踵', '小腿', Icons.accessibility_new_rounded),
  WorkoutData('椅子俯身划船', '上肢 / 背部', Icons.fitness_center_rounded),
  WorkoutData('椅子侧支撑', '核心 / 侧腹', Icons.self_improvement_rounded),
  WorkoutData('椅子卷腹', '核心 / 腹部', Icons.airline_seat_recline_normal_rounded),
];

class WorkoutCard extends StatelessWidget {
  final int index;
  final WorkoutData data;
  const WorkoutCard({super.key, required this.index, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NeonCard(
        height: 214,
        radius: 22,
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            Positioned(right: 10, top: -12, child: Text(index.toString().padLeft(2, '0'), style: TextStyle(color: Colors.white.withOpacity(.05), fontSize: 72, fontWeight: FontWeight.w900))),
            Positioned(right: 0, bottom: 0, width: 160, height: 155, child: ExerciseVisual(icon: data.icon)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: Text(data.title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))), Tag(text: data.part)]),
                const SizedBox(height: 14),
                const Text('要点', style: TextStyle(color: AppColors.cyan, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('• 双脚与肩同宽，核心收紧\n• 动作放慢，控制节奏\n• 轻触椅面后发力站起', style: TextStyle(color: Colors.white.withOpacity(.72), fontSize: 13, height: 1.42)),
                const SizedBox(height: 10),
                const Text('红线', style: TextStyle(color: AppColors.red, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('× 膝盖内扣或大幅前冲\n× 借惯性弹起', style: TextStyle(color: Colors.white.withOpacity(.68), fontSize: 13, height: 1.42)),
                const Spacer(),
                Row(children: const [Icon(Icons.schedule_rounded, color: AppColors.cyan, size: 19), SizedBox(width: 6), Text('20秒 × 1组', style: TextStyle(color: AppColors.cyan, fontSize: 18, fontWeight: FontWeight.w900))]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseVisual extends StatelessWidget {
  final IconData icon;
  const ExerciseVisual({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cyan.withOpacity(.8), width: 4), boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(.24), blurRadius: 24)])),
        Icon(icon, size: 78, color: Colors.white.withOpacity(.9)),
      ],
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  const Tag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.cyan.withOpacity(.6)), color: AppColors.cyan.withOpacity(.08)), child: Text(text, style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w900, fontSize: 13)));
  }
}

class MiniExerciseCard extends StatelessWidget {
  final WorkoutData data;
  const MiniExerciseCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 16,
      padding: const EdgeInsets.all(10),
      child: SizedBox(width: 86, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(data.icon, color: AppColors.cyan, size: 40), const SizedBox(height: 10), Text(data.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 3), Text(data.part, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(.48), fontSize: 10))])),
    );
  }
}

class BottomActionBar extends StatelessWidget {
  final String leftText, centerText, rightText;
  final VoidCallback onLeft, onCenter, onRight;
  const BottomActionBar({super.key, required this.leftText, required this.centerText, required this.rightText, required this.onLeft, required this.onCenter, required this.onRight});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xEC091018), borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.white.withOpacity(.08))),
            child: Row(
              children: [
                Expanded(child: GhostButton(label: leftText, icon: Icons.refresh_rounded, onTap: onLeft)),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: NeonButton(label: centerText, icon: Icons.flash_on_rounded, onTap: onCenter)),
                const SizedBox(width: 10),
                Expanded(child: GhostButton(label: rightText, icon: Icons.badge_outlined, onTap: onRight)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChairPosterVisual extends StatelessWidget {
  const ChairPosterVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFF0A7C97), Color(0xFF071018)], radius: .85))),
        Container(width: 230, height: 230, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cyan, width: 5), boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(.4), blurRadius: 40)])),
        const Icon(Icons.chair_alt_rounded, color: Colors.white, size: 150),
      ],
    );
  }
}

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF112233), border: Border.all(color: AppColors.cyan.withOpacity(.55), width: 2), boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(.25), blurRadius: 24)]), child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 48));
  }
}

class StatLine extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const StatLine({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [CircleIcon(icon: icon, color: AppColors.cyan), const SizedBox(width: 18), Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), const Spacer(), Text(value, style: const TextStyle(color: AppColors.cyan, fontSize: 28, fontWeight: FontWeight.w900))]);
  }
}

class AvatarRing extends StatelessWidget {
  const AvatarRing({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(width: 94, height: 94, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cyan, width: 3), boxShadow: [BoxShadow(color: AppColors.cyan.withOpacity(.35), blurRadius: 24)]), child: const Icon(Icons.person_rounded, color: Colors.white, size: 54)),
        Positioned(right: 0, bottom: 0, child: Container(width: 34, height: 34, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.cyan), child: const Icon(Icons.edit_rounded, color: Colors.black, size: 18))),
      ],
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String value, label;
  const ProfileStat({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [Text(value, style: const TextStyle(color: AppColors.cyan, fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(label, style: TextStyle(color: Colors.white.withOpacity(.6), fontWeight: FontWeight.w700))]));
  }
}

class CollectionSeriesCard extends StatelessWidget {
  final ObjectItem item;
  const CollectionSeriesCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: NeonCard(
        height: 116,
        radius: 17,
        padding: const EdgeInsets.all(10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item.icon, color: AppColors.cyan, size: 32), const SizedBox(height: 10), Text('${item.title}系列', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('${8 + item.title.length} 张卡片', style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 12))]),
      ),
    );
  }
}

class ProfileCardData {
  final String title, rare;
  final IconData icon;
  final Color color;
  const ProfileCardData(this.title, this.rare, this.icon, this.color);
}

const profileCards = [
  ProfileCardData('椅子辅助深蹲', 'COMMON', Icons.airline_seat_recline_extra_rounded, AppColors.cyan),
  ProfileCardData('椅子臂屈伸', 'COMMON', Icons.fitness_center_rounded, AppColors.cyan),
  ProfileCardData('椅子仰卧抬腿', 'RARE', Icons.self_improvement_rounded, AppColors.purple),
  ProfileCardData('单腿髋拉', 'RARE', Icons.directions_run_rounded, AppColors.purple),
];

class CollectibleCard extends StatelessWidget {
  final ProfileCardData data;
  const CollectibleCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 20,
      padding: const EdgeInsets.all(13),
      gradient: LinearGradient(colors: [data.color.withOpacity(.16), const Color(0xFF071018)]),
      child: SizedBox(
        width: 138,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: data.color.withOpacity(.18), borderRadius: BorderRadius.circular(10), border: Border.all(color: data.color.withOpacity(.55))), child: Text(data.rare, style: TextStyle(color: data.color, fontSize: 12, fontWeight: FontWeight.w900))), const Spacer(), Center(child: Icon(data.icon, color: Colors.white, size: 72)), const Spacer(), Text(data.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900), maxLines: 2), const SizedBox(height: 4), Row(children: [Text(data.rare, style: TextStyle(color: data.color, fontWeight: FontWeight.w900)), const Spacer(), Icon(Icons.flash_on_rounded, color: data.color)])]),
      ),
    );
  }
}

class CalendarBlock extends StatelessWidget {
  const CalendarBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 30,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(children: const [Icon(Icons.chevron_left_rounded, color: Colors.white, size: 34), Spacer(), Text('2024年7月', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)), Spacer(), Icon(Icons.chevron_right_rounded, color: Colors.white, size: 34)]),
          const SizedBox(height: 24),
          Row(children: '一二三四五六日'.split('').map((e) => Expanded(child: Center(child: Text(e, style: TextStyle(color: Colors.white.withOpacity(.58), fontWeight: FontWeight.w900))))).toList()),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 31,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.05),
            itemBuilder: (_, i) {
              final day = i + 1;
              final active = day == 20;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: active ? 48 : 34,
                    height: active ? 48 : 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: active ? AppColors.cyan : Colors.transparent, boxShadow: active ? [BoxShadow(color: AppColors.cyan.withOpacity(.45), blurRadius: 22)] : null),
                    child: Text('$day', style: TextStyle(color: active ? Colors.black : Colors.white.withOpacity(day > 27 ? .45 : .92), fontSize: active ? 24 : 18, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 3),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [Dot(color: [AppColors.cyan, AppColors.green, AppColors.purple, AppColors.orange][day % 4]), if (day % 4 == 1) const SizedBox(width: 3), if (day % 4 == 1) const Dot(color: AppColors.cyan)]),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, children: const [LegendDot(text: '初级', color: Colors.blue), LegendDot(text: '中级', color: AppColors.green), LegendDot(text: '高级', color: AppColors.purple), LegendDot(text: '拉伸', color: AppColors.orange), LegendDot(text: '主体', color: AppColors.cyan)]),
        ],
      ),
    );
  }
}

class Dot extends StatelessWidget {
  final Color color;
  const Dot({super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class LegendDot extends StatelessWidget {
  final String text;
  final Color color;
  const LegendDot({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Dot(color: color), const SizedBox(width: 6), Text(text, style: TextStyle(color: Colors.white.withOpacity(.62), fontWeight: FontWeight.w700))]);
}

class HistoryDayCard extends StatelessWidget {
  const HistoryDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      height: 240,
      radius: 26,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('7月20日', style: TextStyle(color: AppColors.cyan, fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 10), Text('星期六', style: TextStyle(color: Colors.white.withOpacity(.55), fontWeight: FontWeight.w700)), const SizedBox(height: 20), const Text('椅子 · 办公室', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text('舒展筋骨 · 全身', style: TextStyle(color: Colors.white.withOpacity(.62), fontSize: 16, fontWeight: FontWeight.w700)), const Spacer(), Row(children: const [Icon(Icons.flash_on_rounded, color: AppColors.cyan), SizedBox(width: 6), Text('3个动作', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)), SizedBox(width: 18), Icon(Icons.schedule_rounded, color: Colors.white54), SizedBox(width: 6), Text('1分钟', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800))]), const SizedBox(height: 16), NeonButton(label: '再练一次', icon: Icons.flash_on_rounded, width: 170, height: 46, onTap: () {})])),
          const SizedBox(width: 12),
          const SizedBox(width: 130, child: ChairPosterVisual()),
        ],
      ),
    );
  }
}

class RoomCameraVisual extends StatelessWidget {
  const RoomCameraVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: RoomPainter());
  }
}

class RoomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..shader = const LinearGradient(colors: [Color(0xFF14100E), Color(0xFF02070C), Color(0xFF061829)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);
    final floor = Paint()..color = Colors.white.withOpacity(.05);
    for (double y = size.height * .56; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 20), floor);
    }
    final lamp = Paint()..color = AppColors.orange.withOpacity(.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(Offset(size.width * .18, size.height * .32), 70, lamp);
    final chair = Paint()..color = Colors.white.withOpacity(.78)..strokeWidth = 6..strokeCap = StrokeCap.round;
    final cx = size.width * .52;
    final cy = size.height * .46;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 120, height: 86), const Radius.circular(14)), Paint()..color = Colors.black.withOpacity(.72));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 84), width: 140, height: 38), const Radius.circular(14)), Paint()..color = Colors.black.withOpacity(.74));
    canvas.drawLine(Offset(cx - 50, cy + 105), Offset(cx - 80, cy + 205), chair);
    canvas.drawLine(Offset(cx + 50, cy + 105), Offset(cx + 80, cy + 205), chair);
    canvas.drawLine(Offset(cx - 35, cy + 105), Offset(cx - 20, cy + 205), chair);
    canvas.drawLine(Offset(cx + 35, cy + 105), Offset(cx + 20, cy + 205), chair);
    final glowLine = Paint()..color = AppColors.cyan.withOpacity(.72)..strokeWidth = 3..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(Offset(size.width * .72, 0), Offset(size.width * .72, size.height * .62), glowLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FrostPill extends StatelessWidget {
  final String text;
  const FrostPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), decoration: BoxDecoration(color: Colors.white.withOpacity(.08), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white.withOpacity(.13))), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))),
      ),
    );
  }
}

class ScanCorners extends StatelessWidget {
  const ScanCorners({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: CustomPaint(painter: ScanPainter()),
    );
  }
}

class ScanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.cyan..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    const l = 42.0;
    canvas.drawLine(const Offset(38, 34), const Offset(38, 72), p);
    canvas.drawLine(const Offset(38, 34), const Offset(76, 34), p);
    canvas.drawLine(Offset(w - 38, 34), Offset(w - 38, 72), p);
    canvas.drawLine(Offset(w - 38, 34), Offset(w - 76, 34), p);
    canvas.drawLine(Offset(38, h - 34), Offset(38, h - 72), p);
    canvas.drawLine(Offset(38, h - 34), Offset(76, h - 34), p);
    canvas.drawLine(Offset(w - 38, h - 34), Offset(w - 38, h - 72), p);
    canvas.drawLine(Offset(w - 38, h - 34), Offset(w - 76, h - 34), p);
    final scan = Paint()..color = AppColors.cyan.withOpacity(.7)..strokeWidth = 2..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(Offset(w * .25, h * .48), Offset(w * .75, h * .48), scan);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RecognitionPanel extends StatelessWidget {
  const RecognitionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('识别结果', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          Row(
            children: [
              NeonCard(height: 110, radius: 16, padding: const EdgeInsets.all(8), child: const SizedBox(width: 110, child: Icon(Icons.chair_alt_rounded, color: Colors.white, size: 72))),
              const SizedBox(width: 18),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('椅子', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)), SizedBox(height: 6), Text('识别率 92%', style: TextStyle(color: AppColors.cyan, fontSize: 18, fontWeight: FontWeight.w900)), SizedBox(height: 14), NeonButton(label: '使用该物品', height: 48, onTap: _noop)])),
            ],
          ),
        ],
      ),
    );
  }
}

void _noop() {}

class CameraControls extends StatelessWidget {
  const CameraControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(children: const [Icon(Icons.flash_on_rounded, color: AppColors.cyan, size: 34), SizedBox(height: 6), Text('闪光灯', style: TextStyle(color: Colors.white70))]),
        Container(width: 82, height: 82, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.cyan, width: 5), color: Colors.white)),
        Column(children: const [Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 34), SizedBox(height: 6), Text('切换摄像头', style: TextStyle(color: Colors.white70))]),
      ],
    );
  }
}
