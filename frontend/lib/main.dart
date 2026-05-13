import 'dart:ui';

import 'package:flutter/material.dart';

import 'features/profile/screens/cosmic_profile_pages.dart';

void main() {
  runApp(const SnapRepApp());
}

class SnapRepApp extends StatelessWidget {
  const SnapRepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapRep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
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
  static const bg = Color(0xFF02060B);
  static const panel = Color(0xFF08131E);
  static const panel2 = Color(0xFF0B1823);
  static const stroke = Color(0xFF243544);
  static const cyan = Color(0xFF27E7FF);
  static const cyan2 = Color(0xFF53F4FF);
  static const purple = Color(0xFF8E55FF);
  static const amber = Color(0xFFFFB13A);
  static const green = Color(0xFF57F46A);
  static const red = Color(0xFFFF505D);
  static const blue = Color(0xFF2495FF);
  static const muted = Color(0xFF9CA8B3);
}

const double kPhoneMaxWidth = 470;

class Assets {
  static const relax = 'assets/images/guide_step1_visuals/relax_bg_no_text.jpg';
  static const stretch =
      'assets/images/guide_step1_visuals/mobility_stretch_no_text.jpg';
  static const light =
      'assets/images/guide_step1_visuals/light_movement_no_text.jpg';
  static const strength =
      'assets/images/guide_step1_visuals/strength_focus_no_text.jpg';
  static const bottle =
      'assets/images/guide_step1_visuals/quick_start_bottle_no_text.jpg';
  static const cameraRoom = 'assets/backup/old/camera_room_chair.png';
  static const bodyFull =
      'assets/images/body/ChatGPT Image 2026年5月3日 20_59_25 (1).png';
  static const bodyUpper =
      'assets/images/body/ChatGPT Image 2026年5月3日 20_59_25 (2).png';
  static const bodyCore =
      'assets/images/body/ChatGPT Image 2026年5月3日 20_59_26 (3).png';
  static const bodyLower =
      'assets/images/body/ChatGPT Image 2026年5月3日 20_59_26 (4).png';
  static const bodyAll =
      'assets/images/body/ChatGPT Image 2026年5月3日 20_59_27 (5).png';
  static const chairSquat =
      'assets/images/workout_result/exercise_01_chair_squat_visual.jpg';
  static const chairDip =
      'assets/images/workout_result/exercise_02_chair_dip_visual.jpg';
  static const legRaise =
      'assets/images/workout_result/exercise_03_chair_leg_raise_visual.jpg';
  static const alt1 =
      'assets/images/workout_result/alt_01_chair_forward_step_visual.jpg';
  static const alt2 =
      'assets/images/workout_result/alt_02_chair_knee_raise_visual.jpg';
  static const alt3 =
      'assets/images/workout_result/alt_03_chair_bent_row_visual.jpg';
  static const alt4 =
      'assets/images/workout_result/alt_04_chair_side_plank_visual.jpg';
  static const alt5 =
      'assets/images/workout_result/alt_05_chair_crunch_visual.jpg';
  static const alt6 =
      'assets/images/workout_result/alt_06_chair_deep_squat_pause_visual.jpg';
}

PageRouteBuilder<T> snapRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(.03, .015), end: Offset.zero)
                  .animate(curved),
          child: child,
        ),
      );
    },
  );
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
      HomeScreen(onCamera: () => setState(() => index = 1)),
      CameraScreen(onClose: () => setState(() => index = 0)),
      CosmicProfileHome(
        onOpenCollection: () =>
            Navigator.of(context).push(snapRoute(const CosmicCollectionPage())),
        onOpenCard: () => Navigator.of(context).push(
          snapRoute(
            const CosmicCardDetailPage(
              card: TrainingCard(
                title: '椅子臂屈伸',
                rarity: '史诗',
                image:
                    'assets/images/workout_result/exercise_02_chair_dip_visual.jpg',
                color: Color(0xFF9456FF),
                level: 4,
                progress: .68,
              ),
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[index],
      bottomNavigationBar: index == 1
          ? null
          : SnapBottomNav(
              index: index,
              onChanged: (value) => setState(() => index = value),
            ),
    );
  }
}

class SnapBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const SnapBottomNav(
      {super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kPhoneMaxWidth),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Glass(
            radius: 36,
            child: Container(
              height: 82,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.white.withOpacity(.08)),
                color: const Color(0xE5081119),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NavButton(
                      icon: Icons.home_rounded,
                      label: '首页',
                      active: index == 0,
                      onTap: () => onChanged(0)),
                  NavButton(
                      icon: Icons.photo_camera_outlined,
                      label: '相机',
                      active: index == 1,
                      onTap: () => onChanged(1)),
                  NavButton(
                      icon: Icons.person_outline_rounded,
                      label: '我的',
                      active: index == 2,
                      onTap: () => onChanged(2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const NavButton(
      {super.key,
      required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.cyan : Colors.white.withOpacity(.62);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 86,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 29),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final VoidCallback onCamera;

  const HomeScreen({super.key, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return SnapFrame(
      bottomPadding: 112,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 112),
        children: [
          const SizedBox(height: 30),
          Row(
            children: const [
              SnapLogo(size: 32),
              Spacer(),
              StreakPill(days: 7),
            ],
          ),
          const SizedBox(height: 22),
          HomeHero(
            onStart: () =>
                Navigator.of(context).push(snapRoute(const GuideStep1Screen())),
          ),
          SectionTitle(
            title: '场景',
            action: '查看更多',
            onTap: () =>
                Navigator.of(context).push(snapRoute(const GuideStep2Screen())),
          ),
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: scenes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) =>
                  SceneTile(scene: scenes[index], width: 228),
            ),
          ),
          SectionTitle(
            title: '物品',
            action: '拍照识别',
            icon: Icons.photo_camera_outlined,
            onTap: onCamera,
          ),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: objects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) => ObjectTile(item: objects[index]),
            ),
          ),
          const SectionTitle(title: '主题周'),
          const ThemeWeekPanel(),
          const SizedBox(height: 22),
          const ChallengeStrip(),
        ],
      ),
    );
  }
}

class HomeHero extends StatelessWidget {
  final VoidCallback onStart;

  const HomeHero({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      height: 268,
      radius: 28,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned.fill(
              child:
                  ImagePanel(image: Assets.chairDip, radius: 28, opacity: .92)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(.78),
                    Colors.black.withOpacity(.18),
                    Colors.black.withOpacity(.74)
                  ],
                  stops: const [0, .55, 1],
                ),
              ),
            ),
          ),
          Positioned(
              right: 28, top: 26, bottom: 26, child: NeonRing(size: 142)),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 26, 30, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Spacer(),
                  Icon(Icons.flash_on_rounded, color: AppColors.cyan, size: 34),
                  Spacer(flex: 3)
                ]),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.03),
                    children: [
                      TextSpan(
                          text: '给我', style: TextStyle(color: Colors.white)),
                      TextSpan(
                          text: '60', style: TextStyle(color: AppColors.cyan)),
                      TextSpan(
                          text: '秒', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('随时随地，3个动作开启训练',
                    style: TextStyle(
                        color: Colors.white.withOpacity(.82),
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                CyanButton(
                    label: '给我60秒',
                    icon: Icons.flash_on_rounded,
                    width: 172,
                    onTap: onStart),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        color: Colors.white.withOpacity(.78), size: 19),
                    const SizedBox(width: 8),
                    Text('30秒内获得专属方案',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.72),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GuideStep1Screen extends StatelessWidget {
  const GuideStep1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return SnapFrame(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 4, 26, 24),
          child: Column(
            children: [
              const PageTopBar(showBack: true, trailing: '跳过'),
              const SizedBox(height: 42),
              const ProgressCapsule(text: '1 / 3'),
              const SizedBox(height: 26),
              const HeroTitle(
                  before: '今天想',
                  highlight: '怎么动',
                  after: '?',
                  subtitle: '不纠结，先选感觉'),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: .83,
                  children: const [
                    IntentCard(
                        title: '放松',
                        desc: '降紧张 / 舒缓身心',
                        icon: Icons.nightlight_round,
                        image: Assets.relax),
                    IntentCard(
                        title: '舒展筋骨',
                        desc: '拉伸与活动度',
                        icon: Icons.check_rounded,
                        image: Assets.stretch,
                        selected: true),
                    IntentCard(
                        title: '适当运动',
                        desc: '轻汗 / 微心率',
                        icon: Icons.flash_on_rounded,
                        image: Assets.light),
                    IntentCard(
                        title: '主体锻炼',
                        desc: '轻力量 / 稳定性',
                        icon: Icons.fitness_center_rounded,
                        image: Assets.strength),
                  ],
                ),
              ),
              const QuickStartCard(),
              const SizedBox(height: 20),
              CyanButton(
                label: '下一步：选择场景',
                height: 62,
                onTap: () => Navigator.of(context)
                    .push(snapRoute(const GuideStep2Screen())),
              ),
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
    return SnapFrame(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTopBar(showBack: true, trailing: '跳过'),
              const SizedBox(height: 34),
              const HeroTitle(
                  before: '你在哪里',
                  highlight: '练',
                  after: '? 有啥东西?',
                  subtitle: '没有也能练'),
              const SizedBox(height: 24),
              const StepCaption(num: 1, text: '选择场景'),
              const SizedBox(height: 12),
              SizedBox(
                height: 148,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: scenes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => SelectSceneTile(
                      scene: scenes[index], selected: index == 0),
                ),
              ),
              const SizedBox(height: 24),
              const StepCaption(num: 2, text: '选择物品 （可多选）'),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: .78,
                  children: objects
                      .map((item) => SelectObjectTile(
                          item: item, selected: item.title == '椅子'))
                      .toList(),
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context)
                      .push(snapRoute(const CameraScreen(showBack: true))),
                  icon: const Icon(Icons.help_outline_rounded,
                      color: AppColors.cyan),
                  label: const Text('不知道? 稍后拍摄识别',
                      style: TextStyle(
                          color: AppColors.cyan, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              CyanButton(
                label: '下一步：选择重点部位',
                icon: Icons.flash_on_rounded,
                height: 62,
                onTap: () => Navigator.of(context)
                    .push(snapRoute(const GuideStep3Screen())),
              ),
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
    return SnapFrame(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            children: [
              const PageTopBar(showBack: true),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  PagerDot(active: false),
                  SizedBox(width: 14),
                  PagerDot(active: false),
                  SizedBox(width: 14),
                  PagerDot(active: true),
                ],
              ),
              const SizedBox(height: 24),
              const HeroTitle(
                  before: '想',
                  highlight: '重点',
                  after: '练哪里?',
                  subtitle: '可多选（最多2个）'),
              const SizedBox(height: 20),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const NeonRing(size: 318, dim: true),
                    Image.asset(Assets.bodyFull, fit: BoxFit.contain),
                  ],
                ),
              ),
              SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: bodyTargets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, index) => BodyTargetCard(
                      target: bodyTargets[index], selected: index == 1),
                ),
              ),
              const SizedBox(height: 18),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(text: '已选 '),
                    TextSpan(
                        text: '0',
                        style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 28,
                            fontWeight: FontWeight.w900)),
                    TextSpan(text: ' / 2'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              CyanButton(
                label: '生成我的3个动作',
                height: 62,
                onTap: () => Navigator.of(context)
                    .push(snapRoute(const WorkoutResultScreen())),
              ),
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
    return SnapFrame(
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 124),
              children: [
                Row(
                  children: const [
                    SnapLogo(size: 23),
                    Spacer(),
                    Text('为你推荐',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.w900)),
                    Spacer(flex: 2),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: const [
                    Expanded(
                        child: InfoPill(
                            icon: Icons.chair_alt_rounded, text: '物品：椅子')),
                    SizedBox(width: 10),
                    Expanded(
                        child: InfoPill(
                            icon: Icons.business_center_rounded,
                            text: '场景：办公室')),
                    SizedBox(width: 10),
                    Expanded(
                        child: InfoPill(
                            icon: Icons.bar_chart_rounded, text: '难度：初级')),
                  ],
                ),
                const SizedBox(height: 18),
                ...workoutCards.asMap().entries.map((entry) =>
                    WorkoutCard(index: entry.key + 1, data: entry.value)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SectionTick(),
                    const SizedBox(width: 9),
                    Text('替换单卡', style: smallSectionStyle()),
                    const SizedBox(width: 8),
                    Text('（滑动选择更多动作）',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.58),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 106,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: alternativeCards.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) =>
                        MiniWorkoutCard(data: alternativeCards[index]),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ResultBottomBar(
                onStart: () => Navigator.of(context)
                    .push(snapRoute(const TrainingPracticeScreen())),
                onCard: () => Navigator.of(context)
                    .push(snapRoute(const ResultCardScreen())),
              ),
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
    return SnapFrame(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SnapLogo(size: 33),
              const SizedBox(height: 28),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 50, fontWeight: FontWeight.w900, height: 1.05),
                  children: [
                    TextSpan(
                        text: '椅子日', style: TextStyle(color: AppColors.cyan)),
                    TextSpan(
                        text: '挑战完成!', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('2024.07.20',
                  style: TextStyle(
                      color: Colors.white.withOpacity(.52),
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              Container(
                  width: 70,
                  height: 4,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                      color: AppColors.cyan,
                      borderRadius: BorderRadius.circular(4))),
              Expanded(
                child: Stack(
                  children: [
                    const Align(
                        alignment: Alignment.center,
                        child: NeonRing(size: 330)),
                    Align(
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: const Offset(10, 10),
                        child: Image.asset(Assets.chairDip,
                            width: 330, fit: BoxFit.contain),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      bottom: 34,
                      right: 0,
                      child: NeonCard(
                        radius: 24,
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                        child: Column(
                          children: const [
                            StatRow(
                                icon: Icons.flash_on_rounded,
                                label: '完成动作',
                                value: '3个'),
                            Divider(color: Color(0x3327E7FF), height: 24),
                            StatRow(
                                icon: Icons.schedule_rounded,
                                label: '训练总长',
                                value: '1分钟'),
                            Divider(color: Color(0x3327E7FF), height: 24),
                            StatRow(
                                icon: Icons.chair_alt_rounded,
                                label: '训练场景',
                                value: '办公室'),
                            Divider(color: Color(0x3327E7FF), height: 24),
                            StatRow(
                                icon: Icons.bar_chart_rounded,
                                label: '难度等级',
                                value: '初级'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: AppColors.cyan, size: 84),
                    const SizedBox(height: 14),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900),
                        children: [
                          TextSpan(text: '坚持运动，遇见'),
                          TextSpan(
                              text: '更好的',
                              style: TextStyle(color: AppColors.cyan)),
                          TextSpan(text: '自己!'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    return SnapFrame(
      bottomPadding: 112,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 118),
        children: [
          const Center(
              child: Text('我的',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900))),
          const SizedBox(height: 34),
          NeonCard(
            radius: 28,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    const AvatarImage(),
                    const SizedBox(width: 26),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Hi，健身达人 👋',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 31,
                                  fontWeight: FontWeight.w900)),
                          SizedBox(height: 12),
                          Text('连续运动 12 天',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(.08)),
                    color: Colors.white.withOpacity(.035),
                  ),
                  child: Row(
                    children: const [
                      ProfileStat(value: '36', label: '收藏卡片'),
                      VerticalDivider(color: Color(0x33FFFFFF), thickness: 1),
                      ProfileStat(value: '28', label: '训练次数'),
                      VerticalDivider(color: Color(0x33FFFFFF), thickness: 1),
                      ProfileStat(value: '12', label: '连续天数'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SectionTitle(title: '卡片收藏', action: '全部系列', onTap: onHistory),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: collectionSeries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, index) =>
                  CollectionTile(item: collectionSeries[index]),
            ),
          ),
          SectionTitle(title: '最近收集', action: '查看全部', onTap: onHistory),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: workoutCards.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, index) {
                final card = index < workoutCards.length
                    ? workoutCards[index]
                    : alternativeCards[2];
                return CollectCard(data: card, rare: index > 1);
              },
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
    return SnapFrame(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          children: [
            const PageTopBar(showBack: true, title: '训练记录'),
            const SizedBox(height: 24),
            NeonCard(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 42),
                      Spacer(),
                      Text('2024年7月',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900)),
                      Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 42),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                      children: ['一', '二', '三', '四', '五', '六', '日']
                          .map((e) => Expanded(
                              child: Center(
                                  child: Text(e,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800)))))
                          .toList()),
                  const SizedBox(height: 18),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 31,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7, childAspectRatio: .78),
                    itemBuilder: (_, index) => CalendarDay(day: index + 1),
                  ),
                  const SizedBox(height: 18),
                  const CalendarLegend(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            NeonCard(
              radius: 26,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text('7月20日',
                                style: TextStyle(
                                    color: AppColors.cyan,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900)),
                            SizedBox(width: 18),
                            Text('星期六',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Text('椅子 · 办公室',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        const Text('舒展筋骨 · 全身',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 20),
                        Row(
                          children: const [
                            Icon(Icons.flash_on_rounded, color: AppColors.cyan),
                            SizedBox(width: 6),
                            Text('3个动作',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(width: 18),
                            Icon(Icons.schedule_rounded, color: Colors.white54),
                            SizedBox(width: 6),
                            Text('1分钟',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 22),
                        CyanButton(
                            label: '再练一次',
                            icon: Icons.flash_on_rounded,
                            width: 172,
                            height: 52,
                            onTap: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                      width: 96,
                      child: Stack(alignment: Alignment.center, children: [
                        const NeonRing(size: 92),
                        Image.asset(Assets.chairDip)
                      ])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final bool showBack;
  final VoidCallback? onClose;

  const CameraScreen({super.key, this.showBack = false, this.onClose});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool recognized = false;

  @override
  Widget build(BuildContext context) {
    return SnapFrame(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(Assets.cameraRoom, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(recognized ? .46 : .10),
                    Colors.black.withOpacity(recognized ? .20 : .05),
                    Colors.black.withOpacity(recognized ? .92 : .52)
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
                children: [
                  CameraHeader(
                    recognized: recognized,
                    showBack: widget.showBack || widget.onClose != null,
                    onBack: widget.onClose ?? () => Navigator.of(context).pop(),
                  ),
                  SizedBox(height: recognized ? 26 : 34),
                  const FrostLabel(text: '将镜头对准身边的物品'),
                  SizedBox(height: recognized ? 62 : 70),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          left: recognized ? 62 : 50,
                          right: recognized ? 62 : 52,
                          top: recognized ? 12 : 0,
                          bottom: recognized ? 52 : 10,
                          child: const ScanCorners(),
                        ),
                        if (!recognized)
                          Positioned(
                            left: 80,
                            right: 80,
                            top: 135,
                            child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                    color: AppColors.cyan.withOpacity(.92),
                                    boxShadow: [
                                      BoxShadow(
                                          color:
                                              AppColors.cyan.withOpacity(.95),
                                          blurRadius: 24,
                                          spreadRadius: 3)
                                    ])),
                          ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: recognized
                        ? RecognitionSheet(
                            key: const ValueKey('recognized'),
                            onUse: _noop,
                            onRetake: () => setState(() => recognized = false),
                          )
                        : CameraCaptureDock(
                            key: const ValueKey('captureDock'),
                            onCapture: () => setState(() => recognized = true),
                            onReset: () => setState(() => recognized = false),
                          ),
                  ),
                  if (recognized) ...[
                    const SizedBox(height: 20),
                    CameraControls(
                      compact: true,
                      onCapture: () => setState(() => recognized = true),
                      onReset: () => setState(() => recognized = false),
                    ),
                    Container(
                      width: 140,
                      height: 5,
                      margin: const EdgeInsets.only(top: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SnapFrame extends StatelessWidget {
  final Widget child;
  final double bottomPadding;

  const SnapFrame({super.key, required this.child, this.bottomPadding = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [Color(0xFF0B2333), AppColors.bg],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kPhoneMaxWidth),
          child: child,
        ),
      ),
    );
  }
}

class SnapLogo extends StatelessWidget {
  final double size;

  const SnapLogo({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
            fontSize: size,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4),
        children: const [
          TextSpan(text: 'Snap', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'Rep', style: TextStyle(color: AppColors.cyan)),
        ],
      ),
    );
  }
}

class StreakPill extends StatelessWidget {
  final int days;

  const StreakPill({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(.055),
        border: Border.all(color: Colors.white.withOpacity(.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: AppColors.cyan, size: 20),
          const SizedBox(width: 8),
          Text('连续打卡 ',
              style: TextStyle(
                  color: Colors.white.withOpacity(.92),
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          Text('$days',
              style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const Text(' 天',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class NeonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double? height;

  const NeonCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18),
      this.radius = 22,
      this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: AppColors.panel.withOpacity(.9),
        border: Border.all(color: Colors.white.withOpacity(.10)),
        boxShadow: [
          BoxShadow(
              color: AppColors.cyan.withOpacity(.08),
              blurRadius: 28,
              offset: const Offset(0, 10)),
          BoxShadow(
              color: Colors.black.withOpacity(.35),
              blurRadius: 26,
              offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}

class Glass extends StatelessWidget {
  final Widget child;
  final double radius;

  const Glass({super.key, required this.child, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: child,
      ),
    );
  }
}

class ImagePanel extends StatelessWidget {
  final String image;
  final double radius;
  final double opacity;

  const ImagePanel(
      {super.key, required this.image, this.radius = 20, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Opacity(
        opacity: opacity,
        child: Image.asset(image, fit: BoxFit.cover),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final IconData? icon;
  final VoidCallback? onTap;

  const SectionTitle(
      {super.key, required this.title, this.action, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
      child: Row(
        children: [
          const SectionTick(),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  if (icon != null)
                    Icon(icon, color: Colors.white.withOpacity(.74), size: 20),
                  if (icon != null) const SizedBox(width: 8),
                  Text(action!,
                      style: TextStyle(
                          color: Colors.white.withOpacity(.72),
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(.72), size: 23),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SectionTick extends StatelessWidget {
  const SectionTick({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 5,
        height: 26,
        decoration: BoxDecoration(
            color: AppColors.cyan, borderRadius: BorderRadius.circular(6)));
  }
}

class CyanButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double? width;
  final double height;

  const CyanButton(
      {super.key,
      required this.label,
      required this.onTap,
      this.icon,
      this.width,
      this.height = 54});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(height / 2)),
          textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 26),
            if (icon != null) const SizedBox(width: 10),
            Flexible(
                child:
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class PageTopBar extends StatelessWidget {
  final bool showBack;
  final String? title;
  final String? trailing;

  const PageTopBar(
      {super.key, this.showBack = false, this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: showBack
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).maybePop()))
                : null,
          ),
          Expanded(
              child: Center(
                  child: title == null
                      ? const SnapLogo(size: 29)
                      : Text(title!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900)))),
          SizedBox(
            width: 70,
            child: trailing == null
                ? null
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(trailing!,
                        style: TextStyle(
                            color: Colors.white.withOpacity(.78),
                            fontSize: 18,
                            fontWeight: FontWeight.w700))),
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(.055),
            border: Border.all(color: Colors.white.withOpacity(.10))),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}

class ProgressCapsule extends StatelessWidget {
  final String text;

  const ProgressCapsule({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(.045),
        border: Border.all(color: AppColors.cyan.withOpacity(.7)),
        boxShadow: [
          BoxShadow(color: AppColors.cyan.withOpacity(.18), blurRadius: 18)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('1',
              style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          Text(' / 3',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 21,
                  fontWeight: FontWeight.w800)),
          SizedBox(width: 16),
          Icon(Icons.flash_on_rounded, color: AppColors.cyan, size: 24),
        ],
      ),
    );
  }
}

class HeroTitle extends StatelessWidget {
  final String before;
  final String highlight;
  final String after;
  final String subtitle;

  const HeroTitle(
      {super.key,
      required this.before,
      required this.highlight,
      required this.after,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
                color: Colors.white,
                fontSize: 43,
                fontWeight: FontWeight.w900,
                height: 1.08),
            children: [
              TextSpan(text: before),
              TextSpan(
                  text: highlight,
                  style: const TextStyle(color: AppColors.cyan)),
              TextSpan(text: after),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(.66),
                fontSize: 22,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class IntentCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final String image;
  final bool selected;

  const IntentCard(
      {super.key,
      required this.title,
      required this.desc,
      required this.icon,
      required this.image,
      this.selected = false});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 22,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
              child: ImagePanel(image: image, radius: 22, opacity: .9)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: selected
                        ? AppColors.cyan
                        : Colors.white.withOpacity(.05),
                    width: selected ? 3 : 1),
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(.02),
                      Colors.black.withOpacity(.80)
                    ]),
              ),
            ),
          ),
          Positioned(
              left: 18,
              top: 18,
              child: CircleIcon(
                  icon: icon,
                  color: selected ? AppColors.cyan : AppColors.purple)),
          if (selected)
            const Positioned(
                right: 16,
                top: 16,
                child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.cyan,
                    child: Icon(Icons.check_rounded,
                        color: Colors.black, size: 30))),
          Positioned(
            left: 20,
            right: 14,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(desc,
                    style: TextStyle(
                        color: Colors.white.withOpacity(.72),
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuickStartCard extends StatelessWidget {
  const QuickStartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      height: 124,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(20, 14, 18, 14),
      child: Row(
        children: const [
          CircleIcon(
              icon: Icons.flash_on_rounded, color: AppColors.cyan, size: 56),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '直接开练'),
                      TextSpan(
                          text: '60', style: TextStyle(color: AppColors.cyan)),
                      TextSpan(text: '秒 ✨')
                    ]),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('默认模板：舒展 → 活动 → 力量 20s × 3',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(
              width: 96,
              child:
                  Image(image: AssetImage(Assets.bottle), fit: BoxFit.contain)),
        ],
      ),
    );
  }
}

class StepCaption extends StatelessWidget {
  final int num;
  final String text;

  const StepCaption({super.key, required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AppColors.cyan, borderRadius: BorderRadius.circular(9)),
          child: Text('$num',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 12),
        Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class SceneTile extends StatelessWidget {
  final SceneItem scene;
  final double width;

  const SceneTile({super.key, required this.scene, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: NeonCard(
        radius: 15,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(child: ImagePanel(image: scene.image, radius: 15)),
            Positioned.fill(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(.12),
                              Colors.black.withOpacity(.72)
                            ])))),
            Positioned(
                left: 16,
                top: 16,
                child:
                    CircleIcon(icon: scene.icon, color: scene.color, size: 48)),
            Positioned(
                left: 16,
                right: 12,
                bottom: 14,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scene.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(scene.desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withOpacity(.72),
                              fontSize: 14,
                              fontWeight: FontWeight.w600))
                    ])),
          ],
        ),
      ),
    );
  }
}

class SelectSceneTile extends StatelessWidget {
  final SceneItem scene;
  final bool selected;

  const SelectSceneTile(
      {super.key, required this.scene, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Stack(
        children: [
          SceneTile(scene: scene, width: 110),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: selected ? AppColors.cyan : Colors.transparent,
                      width: 3),
                ),
              ),
            ),
          ),
          if (selected)
            const Positioned(
                right: 10,
                top: 10,
                child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.cyan,
                    child: Icon(Icons.check_rounded,
                        color: Colors.black, size: 22))),
        ],
      ),
    );
  }
}

class ObjectTile extends StatelessWidget {
  final ObjectItem item;

  const ObjectTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      child: NeonCard(
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(child: ItemVisual(item: item)),
            Text(item.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(item.desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withOpacity(.58),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class SelectObjectTile extends StatelessWidget {
  final ObjectItem item;
  final bool selected;

  const SelectObjectTile(
      {super.key, required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 15,
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Positioned(
              right: 0,
              top: 0,
              child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.cyan : Colors.white70,
                  size: 23)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: Center(child: ItemVisual(item: item))),
              Text(item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class ItemVisual extends StatelessWidget {
  final ObjectItem item;

  const ItemVisual({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.image != null) {
      return Image.asset(item.image!, fit: BoxFit.contain);
    }
    return Icon(item.icon, color: item.color, size: 50);
  }
}

class BodyTargetCard extends StatelessWidget {
  final BodyTarget target;
  final bool selected;

  const BodyTargetCard(
      {super.key, required this.target, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: NeonCard(
        radius: 18,
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned(
                right: 0,
                top: 0,
                child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? AppColors.cyan : Colors.white70)),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Image.asset(target.image, fit: BoxFit.contain)),
                Text(target.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(target.desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(.56),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoPill({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(.055),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.cyan, size: 23),
          const SizedBox(width: 8),
          Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  final int index;
  final WorkoutData data;

  const WorkoutCard({super.key, required this.index, required this.data});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      height: 310,
      radius: 22,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
              right: 0,
              left: 250,
              child: ImagePanel(image: data.image, radius: 22, opacity: .95)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(colors: [
                  const Color(0xFF07131E).withOpacity(.98),
                  const Color(0xFF07131E).withOpacity(.86),
                  Colors.transparent
                ]),
              ),
            ),
          ),
          Positioned(
              right: 22,
              top: 16,
              child: Text(index.toString().padLeft(2, '0'),
                  style: TextStyle(
                      color: Colors.white.withOpacity(.09),
                      fontSize: 54,
                      fontWeight: FontWeight.w900))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
            child: Row(
              children: [
                Expanded(
                  flex: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                              child: Text(data.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900))),
                          const SizedBox(width: 10),
                          Tag(text: data.part),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('要点',
                          style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      ...data.tips.map((tip) =>
                          BulletLine(text: tip, color: AppColors.cyan)),
                      const Spacer(),
                      const Text('红线',
                          style: TextStyle(
                              color: AppColors.red,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      ...data.warnings.map((tip) => BulletLine(
                          text: tip, color: AppColors.red, cross: true)),
                    ],
                  ),
                ),
                const Spacer(flex: 5),
              ],
            ),
          ),
          Positioned(
            right: 28,
            bottom: 18,
            child: Row(
              children: const [
                Icon(Icons.schedule_rounded, color: AppColors.cyan, size: 22),
                SizedBox(width: 7),
                Text('20秒 × 1组',
                    style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MiniWorkoutCard extends StatelessWidget {
  final WorkoutData data;

  const MiniWorkoutCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: NeonCard(
        radius: 14,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(child: ImagePanel(image: data.image, radius: 14)),
            Positioned.fill(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(.85)
                            ])))),
            Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900)),
                      Text(data.part,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withOpacity(.68),
                              fontSize: 12,
                              fontWeight: FontWeight.w700))
                    ])),
          ],
        ),
      ),
    );
  }
}

class TrainingPracticeScreen extends StatefulWidget {
  const TrainingPracticeScreen({super.key});

  @override
  State<TrainingPracticeScreen> createState() => _TrainingPracticeScreenState();
}

class _TrainingPracticeScreenState extends State<TrainingPracticeScreen> {
  int page = 0;
  bool paused = false;

  PracticePageData get data => practicePages[page];

  void next() => setState(() {
        if (page < practicePages.length - 1) {
          page += 1;
        }
      });

  void previous() => setState(() {
        if (page > 0) {
          page -= 1;
        }
      });

  @override
  Widget build(BuildContext context) {
    return SnapFrame(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          children: [
            PracticeHeader(onBack: () => Navigator.of(context).maybePop()),
            const SizedBox(height: 24),
            PracticeTitlePill(data: data),
            const SizedBox(height: 10),
            PracticePartPill(part: data.part),
            const SizedBox(height: 18),
            PracticeVideoCard(data: data),
            const SizedBox(height: 8),
            if (data.panel == PracticePanel.details)
              PracticeDetailsPanel(data: data)
            else if (data.panel == PracticePanel.progress)
              PracticeProgressPanel(activeStep: data.exerciseIndex)
            else
              PracticeCollapsedPanel(
                onTap: () => setState(() => page = page == 2 ? 0 : 1),
              ),
            const SizedBox(height: 12),
            PracticeControls(
              paused: paused,
              canPrevious: page > 0,
              canNext: page < practicePages.length - 1,
              onPrevious: previous,
              onNext: next,
              onPause: () => setState(() => paused = !paused),
            ),
          ],
        ),
      ),
    );
  }
}

class PracticeHeader extends StatelessWidget {
  final VoidCallback onBack;

  const PracticeHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const Spacer(),
        const Text('跟练中',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900)),
        const Spacer(),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: Colors.white.withOpacity(.045),
              border: Border.all(color: Colors.white.withOpacity(.18))),
          child: Row(
            children: const [
              Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text('静音模式',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }
}

class PracticeTitlePill extends StatelessWidget {
  final PracticePageData data;

  const PracticeTitlePill({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.panel.withOpacity(.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(.18)),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
            children: [
              const TextSpan(text: '动作 '),
              TextSpan(
                  text: '${data.exerciseIndex}/3',
                  style: const TextStyle(color: AppColors.cyan)),
              TextSpan(text: ' · ${data.title}'),
            ],
          ),
        ),
      ),
    );
  }
}

class PracticePartPill extends StatelessWidget {
  final String part;

  const PracticePartPill({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cyan.withOpacity(.7))),
        child: Text(part,
            style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 16,
                fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class PracticeVideoCard extends StatelessWidget {
  final PracticePageData data;

  const PracticeVideoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: data.panel == PracticePanel.details ? 360 : 390,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(data.image, fit: BoxFit.cover)),
            Positioned.fill(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                  Colors.black.withOpacity(.18),
                  Colors.transparent,
                  Colors.black.withOpacity(.62)
                ])))),
            Positioned(
                left: 16,
                top: 16,
                child: CountdownBadge(seconds: data.seconds)),
            Positioned(
              right: 14,
              top: 14,
              child: CircleIcon(
                  icon: Icons.open_in_full_rounded,
                  color: Colors.white,
                  size: 46),
            ),
            const Positioned(
                left: 18, right: 18, bottom: 16, child: VideoBar()),
          ],
        ),
      ),
    );
  }
}

class CountdownBadge extends StatelessWidget {
  final int seconds;

  const CountdownBadge({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: .72,
            strokeWidth: 6,
            backgroundColor: Colors.white.withOpacity(.28),
            valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$seconds',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900)),
                const Text('秒',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoBar extends StatelessWidget {
  const VideoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.pause_rounded, color: Colors.white, size: 36),
        const SizedBox(width: 14),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.25),
                      borderRadius: BorderRadius.circular(6))),
              FractionallySizedBox(
                widthFactor: .7,
                child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                        color: AppColors.cyan,
                        borderRadius: BorderRadius.circular(6))),
              ),
              Align(
                alignment: const Alignment(.38, 0),
                child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        const Text('00:12 / 00:20',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class PracticeDetailsPanel extends StatelessWidget {
  final PracticePageData data;

  const PracticeDetailsPanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(icon: Icons.track_changes_rounded, text: '动作要点'),
          const SizedBox(height: 12),
          ...data.tips
              .map((tip) => BulletLine(text: tip, color: AppColors.cyan)),
          Divider(height: 22, color: Colors.white.withOpacity(.12)),
          const PanelTitle(
              icon: Icons.warning_amber_rounded,
              text: '常见错误',
              color: AppColors.red),
          const SizedBox(height: 10),
          ...data.warnings
              .map((tip) => BulletLine(text: tip, color: AppColors.red)),
        ],
      ),
    );
  }
}

class PracticeProgressPanel extends StatelessWidget {
  final int activeStep;

  const PracticeProgressPanel({super.key, required this.activeStep});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(icon: Icons.bar_chart_rounded, text: '训练进度'),
          const SizedBox(height: 14),
          ...List.generate(workoutCards.length, (index) {
            final step = index + 1;
            return PracticeStepRow(
              index: step,
              title: workoutCards[index].title,
              active: step == activeStep,
            );
          }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(.12)),
                color: Colors.white.withOpacity(.025)),
            child: Row(
              children: const [
                Expanded(child: PracticeMetric(label: '本次训练', value: '1/3')),
                VerticalDivider(width: 1, color: Colors.white24),
                Expanded(child: PracticeMetric(label: '已完成', value: '00:12')),
                VerticalDivider(width: 1, color: Colors.white24),
                Expanded(child: PracticeMetric(label: '剩余约', value: '00:48')),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class PracticeCollapsedPanel extends StatelessWidget {
  final VoidCallback onTap;

  const PracticeCollapsedPanel({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeonCard(
        height: 74,
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          children: const [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 30),
            SizedBox(width: 14),
            Expanded(
              child: Text('动作要点 / 训练进度',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 34),
          ],
        ),
      ),
    );
  }
}

class PanelTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const PanelTitle(
      {super.key,
      required this.icon,
      required this.text,
      this.color = AppColors.cyan});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class PracticeStepRow extends StatelessWidget {
  final int index;
  final String title;
  final bool active;

  const PracticeStepRow(
      {super.key,
      required this.index,
      required this.title,
      required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: active ? Colors.white.withOpacity(.045) : Colors.transparent,
          border: active
              ? Border.all(color: Colors.white.withOpacity(.10))
              : Border.all(color: Colors.transparent)),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.cyan : Colors.white.withOpacity(.12),
                border: Border.all(color: Colors.white.withOpacity(.18))),
            child: Text('$index',
                style: TextStyle(
                    color: active ? Colors.black : Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: active ? Colors.white : Colors.white54,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          if (active)
            const Text('进行中',
                style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 15,
                    fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class PracticeMetric extends StatelessWidget {
  final String label;
  final String value;

  const PracticeMetric({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(.66),
                fontSize: 13,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 20,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class PracticeControls extends StatelessWidget {
  final bool paused;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPause;

  const PracticeControls(
      {super.key,
      required this.paused,
      required this.canPrevious,
      required this.canNext,
      required this.onPrevious,
      required this.onNext,
      required this.onPause});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        PracticeSideControl(
            icon: Icons.skip_previous_rounded,
            label: '上一个动作',
            enabled: canPrevious,
            onTap: onPrevious),
        GestureDetector(
          onTap: onPause,
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.cyan.withOpacity(.36),
                      blurRadius: 28,
                      spreadRadius: 2)
                ]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white, size: 54),
                Text(paused ? '继续' : '暂停',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
        PracticeSideControl(
            icon: Icons.skip_next_rounded,
            label: '下一个动作',
            enabled: canNext,
            onTap: onNext),
      ],
    );
  }
}

class PracticeSideControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const PracticeSideControl(
      {super.key,
      required this.icon,
      required this.label,
      required this.enabled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.white : Colors.white38;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(enabled ? .055 : .025),
                border: Border.all(color: Colors.white.withOpacity(.14))),
            child: Icon(icon, color: color, size: 46),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

enum PracticePanel { details, progress, collapsed }

class PracticePageData {
  final int exerciseIndex;
  final String title;
  final String part;
  final String image;
  final PracticePanel panel;
  final int seconds;
  final List<String> tips;
  final List<String> warnings;

  const PracticePageData(
      {required this.exerciseIndex,
      required this.title,
      required this.part,
      required this.image,
      required this.panel,
      required this.seconds,
      required this.tips,
      required this.warnings});
}

const practicePages = [
  PracticePageData(
      exerciseIndex: 1,
      title: '椅子辅助深蹲',
      part: '下肢 / 臀部',
      image: Assets.chairSquat,
      panel: PracticePanel.details,
      seconds: 18,
      tips: ['脚跟踩稳，膝盖朝向脚尖', '臀部向后坐，核心收紧', '起身时感受臀腿发力'],
      warnings: ['膝盖内扣', '身体前倾过多']),
  PracticePageData(
      exerciseIndex: 1,
      title: '椅子辅助深蹲',
      part: '下肢 / 臀部',
      image: Assets.chairSquat,
      panel: PracticePanel.progress,
      seconds: 18,
      tips: ['脚跟踩稳，膝盖朝向脚尖', '臀部向后坐，核心收紧', '起身时感受臀腿发力'],
      warnings: ['膝盖内扣', '身体前倾过多']),
  PracticePageData(
      exerciseIndex: 2,
      title: '椅子臂屈伸',
      part: '上肢 / 手臂',
      image: Assets.chairDip,
      panel: PracticePanel.collapsed,
      seconds: 18,
      tips: ['双手握住椅边，肘关节向后弯曲', '肩部下沉，避免耸肩'],
      warnings: ['肘部外翻', '肩部受压']),
  PracticePageData(
      exerciseIndex: 3,
      title: '椅子仰卧抬腿',
      part: '核心 / 腹部',
      image: Assets.legRaise,
      panel: PracticePanel.collapsed,
      seconds: 18,
      tips: ['核心收紧，腰背贴地', '慢速控制双腿下落'],
      warnings: ['腰部离地', '借助惯性甩腿']),
];

class ResultBottomBar extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onCard;

  const ResultBottomBar(
      {super.key, required this.onStart, required this.onCard});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: Glass(
        radius: 36,
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xED09131D),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withOpacity(.09)),
          ),
          child: Row(
            children: [
              Expanded(
                  child: GhostButton(
                      label: '换一批', icon: Icons.refresh_rounded, onTap: () {})),
              const SizedBox(width: 12),
              Expanded(
                  flex: 2,
                  child: CyanButton(
                      label: '开始跟练',
                      icon: Icons.flash_on_rounded,
                      onTap: onStart)),
              const SizedBox(width: 12),
              Expanded(
                  child: GhostButton(
                      label: '生成成果卡',
                      icon: Icons.badge_outlined,
                      onTap: onCard)),
            ],
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const GhostButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(.14)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }
}

class ThemeWeekPanel extends StatelessWidget {
  const ThemeWeekPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: NeonCard(
            height: 190,
            radius: 20,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: Stack(
              children: [
                const Positioned(
                    right: -4, bottom: -34, child: NeonRing(size: 150)),
                Positioned(
                    right: 6,
                    bottom: -8,
                    child: Image.asset(Assets.chairDip, width: 120)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('本周主题',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.62),
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('本周：#椅子日',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 7),
                    Text('用椅子动三下，完成燃脂挑战',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.78),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    CyanButton(
                        label: '一键加入 🚀', width: 126, height: 40, onTap: () {}),
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
              PreviewWeek(title: '#水瓶周', date: '7月20日开启', image: Assets.bottle),
              PreviewWeek(
                  title: '#背包周', date: '7月27日开启', icon: Icons.backpack_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

class PreviewWeek extends StatelessWidget {
  final String title;
  final String date;
  final String? image;
  final IconData? icon;

  const PreviewWeek(
      {super.key,
      required this.title,
      required this.date,
      this.image,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      height: 88,
      radius: 15,
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      child: Row(
        children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('下周预告',
                    style: TextStyle(
                        color: Colors.white.withOpacity(.56),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                Text(date,
                    style: TextStyle(
                        color: Colors.white.withOpacity(.58),
                        fontSize: 11,
                        fontWeight: FontWeight.w700))
              ])),
          if (image != null)
            Image.asset(image!, width: 54, height: 54, fit: BoxFit.cover)
          else
            Icon(icon, color: AppColors.cyan, size: 42),
        ],
      ),
    );
  }
}

class ChallengeStrip extends StatelessWidget {
  const ChallengeStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      height: 150,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      child: Stack(
        children: [
          Positioned(
              right: 92,
              top: 2,
              bottom: 0,
              child:
                  Image.asset(Assets.bottle, width: 78, fit: BoxFit.contain)),
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
                width: 102,
                child: CyanButton(label: '发现挑战', height: 46, onTap: _noop)),
          ),
          Positioned.fill(
            right: 188,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '挑战奇葩物品训练',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '用身边物品完成训练',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withOpacity(.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Row(children: const [
                  Icon(Icons.people_alt_rounded,
                      color: AppColors.cyan, size: 20),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      '12.3k 人已参与',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                    ),
                  )
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CollectionTile extends StatelessWidget {
  final CollectionItem item;

  const CollectionTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      child: NeonCard(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Expanded(child: ItemVisual(item: item.object)),
            Text(item.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Text('${item.count} 张卡片',
                style: TextStyle(
                    color: Colors.white.withOpacity(.62),
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class CollectCard extends StatelessWidget {
  final WorkoutData data;
  final bool rare;

  const CollectCard({super.key, required this.data, required this.rare});

  @override
  Widget build(BuildContext context) {
    final color = rare ? AppColors.purple : AppColors.cyan;
    return SizedBox(
      width: 156,
      child: NeonCard(
        radius: 16,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(child: ImagePanel(image: data.image, radius: 16)),
            Positioned.fill(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(.05),
                              Colors.black.withOpacity(.82)
                            ])))),
            Positioned(
                left: 10,
                top: 10,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: color.withOpacity(.22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(.55))),
                    child: Text(rare ? 'RARE' : 'NEW',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 12)))),
            Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Row(children: [
                        Text(rare ? 'RARE' : 'COMMON',
                            style: TextStyle(
                                color: color,
                                fontSize: 14,
                                fontWeight: FontWeight.w900)),
                        const Spacer(),
                        Icon(Icons.flash_on_rounded, color: color, size: 22)
                      ])
                    ])),
          ],
        ),
      ),
    );
  }
}

class AvatarImage extends StatelessWidget {
  const AvatarImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 122,
          height: 122,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                  colors: [AppColors.cyan, AppColors.purple, AppColors.cyan]),
              boxShadow: [
                BoxShadow(
                    color: AppColors.cyan.withOpacity(.22), blurRadius: 22)
              ]),
          child: const ClipOval(
              child:
                  Image(image: AssetImage(Assets.chairDip), fit: BoxFit.cover)),
        ),
        Positioned(
            right: 2,
            bottom: 6,
            child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.panel,
                    border: Border.all(color: AppColors.cyan, width: 2)),
                child: const Icon(Icons.edit_rounded,
                    color: AppColors.cyan, size: 18))),
      ],
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const ProfileStat({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Column(children: [
      Text(value,
          style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 33,
              fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(.72),
              fontSize: 14,
              fontWeight: FontWeight.w700))
    ]));
  }
}

class CalendarDay extends StatelessWidget {
  final int day;

  const CalendarDay({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final active = day == 20;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: active ? 42 : 30,
          height: active ? 42 : 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.cyan : Colors.transparent,
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: AppColors.cyan.withOpacity(.55),
                          blurRadius: 24)
                    ]
                  : null),
          child: Text('$day',
              style: TextStyle(
                  color: active
                      ? Colors.black
                      : Colors.white.withOpacity(day % 7 == 0 ? .46 : .95),
                  fontSize: active ? 19 : 16,
                  fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Dot(color: legendColors[day % legendColors.length]),
            if (day % 4 == 1) const SizedBox(width: 4),
            if (day % 4 == 1)
              Dot(color: legendColors[(day + 2) % legendColors.length]),
          ],
        ),
      ],
    );
  }
}

class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final labels = ['初级', '中级', '高级', '拉伸', '主体', '其他'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(.08))),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 18,
        runSpacing: 10,
        children: List.generate(
            labels.length,
            (index) => Row(mainAxisSize: MainAxisSize.min, children: [
                  Dot(color: legendColors[index]),
                  const SizedBox(width: 7),
                  Text(labels[index],
                      style: TextStyle(
                          color: Colors.white.withOpacity(.72),
                          fontWeight: FontWeight.w700))
                ])),
      ),
    );
  }
}

class Dot extends StatelessWidget {
  final Color color;

  const Dot({super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class CameraHeader extends StatelessWidget {
  final bool recognized;
  final bool showBack;
  final VoidCallback onBack;

  const CameraHeader(
      {super.key,
      required this.recognized,
      required this.showBack,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    if (recognized) {
      return Row(
        children: const [
          SnapLogo(size: 30),
          Spacer(),
          StreakPill(days: 7),
        ],
      );
    }

    return Row(
      children: [
        if (showBack)
          RoundIconButton(icon: Icons.arrow_back_rounded, onTap: onBack)
        else
          const SnapLogo(size: 27),
        const Spacer(),
        RoundIconButton(icon: Icons.cameraswitch_rounded, onTap: _noop),
      ],
    );
  }
}

class RecognitionSheet extends StatelessWidget {
  final VoidCallback onUse;
  final VoidCallback onRetake;

  const RecognitionSheet(
      {super.key, required this.onUse, required this.onRetake});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('识别结果',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                        width: 94,
                        height: 94,
                        child: NeonCard(
                            radius: 16,
                            padding: const EdgeInsets.all(8),
                            child: ItemVisual(item: objects[1]))),
                    const SizedBox(width: 18),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                          Text('椅子',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900)),
                          SizedBox(height: 6),
                          Text('识别率 92%',
                              style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900))
                        ])),
                  ],
                ),
                const SizedBox(height: 14),
                CyanButton(label: '使用该物品', height: 48, onTap: onUse),
                const SizedBox(height: 10),
                GhostButton(
                    label: '重新拍摄',
                    icon: Icons.refresh_rounded,
                    onTap: onRetake),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('相似物品',
                    style: TextStyle(
                        color: Colors.white.withOpacity(.66),
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Row(children: const [
                  Expanded(child: SimilarObject(title: '餐椅', rate: '89%')),
                  SizedBox(width: 10),
                  Expanded(child: SimilarObject(title: '靠背椅', rate: '87%')),
                  SizedBox(width: 10),
                  Expanded(child: SimilarObject(title: '办公椅', rate: '85%'))
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SimilarObject extends StatelessWidget {
  final String title;
  final String rate;

  const SimilarObject({super.key, required this.title, required this.rate});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      radius: 14,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(height: 62, child: ItemVisual(item: objects[1])),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900)),
          Text('识别率 $rate',
              style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class CameraCaptureDock extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onReset;

  const CameraCaptureDock(
      {super.key, required this.onCapture, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 34,
      child: Container(
        height: 118,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: const Color(0xE70A1118),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withOpacity(.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CameraTool(
                icon: Icons.flash_on_rounded, label: '闪光灯', onTap: onReset),
            GestureDetector(
              onTap: onCapture,
              child: Container(
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                      color: Colors.white.withOpacity(.92), width: 5),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.cyan.withOpacity(.22), blurRadius: 20)
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withOpacity(.18)),
                  ),
                ),
              ),
            ),
            CameraTool(
                icon: Icons.cameraswitch_rounded,
                label: '切换摄像头',
                onTap: onReset),
          ],
        ),
      ),
    );
  }
}

class CameraControls extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onReset;
  final bool compact;

  const CameraControls(
      {super.key,
      required this.onCapture,
      required this.onReset,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        CameraTool(icon: Icons.flash_on_rounded, label: '闪光灯', onTap: onReset),
        GestureDetector(
          onTap: onCapture,
          child: Container(
            width: compact ? 78 : 82,
            height: compact ? 78 : 82,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyan, width: 5),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.cyan.withOpacity(.28), blurRadius: 22)
                ]),
          ),
        ),
        CameraTool(
            icon: Icons.cameraswitch_rounded, label: '切换摄像头', onTap: onReset),
      ],
    );
  }
}

class CameraTool extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const CameraTool(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Icon(icon, color: AppColors.cyan, size: 35),
        const SizedBox(height: 7),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(.76),
                fontSize: 14,
                fontWeight: FontWeight.w700))
      ]),
    );
  }
}

class FrostLabel extends StatelessWidget {
  final String text;

  const FrostLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 28,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 15),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withOpacity(.10),
            border: Border.all(color: Colors.white.withOpacity(.13))),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class ScanCorners extends StatelessWidget {
  const ScanCorners({super.key});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: ScanPainter(), child: const SizedBox.expand());
}

class ScanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyan
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    const gap = 70.0;
    const inset = 34.0;
    final right = size.width - inset;
    final bottom = size.height - inset;
    canvas.drawLine(
        const Offset(inset, inset), const Offset(inset + gap, inset), paint);
    canvas.drawLine(
        const Offset(inset, inset), const Offset(inset, inset + gap), paint);
    canvas.drawLine(Offset(right, inset), Offset(right - gap, inset), paint);
    canvas.drawLine(Offset(right, inset), Offset(right, inset + gap), paint);
    canvas.drawLine(Offset(inset, bottom), Offset(inset + gap, bottom), paint);
    canvas.drawLine(Offset(inset, bottom), Offset(inset, bottom - gap), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right - gap, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - gap), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const CircleIcon(
      {super.key, required this.icon, required this.color, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(.16),
          border: Border.all(color: color.withOpacity(.34))),
      child: Icon(icon, color: color, size: size * .52),
    );
  }
}

class NeonRing extends StatelessWidget {
  final double size;
  final bool dim;

  const NeonRing({super.key, required this.size, this.dim = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [
          AppColors.cyan.withOpacity(dim ? .35 : .95),
          AppColors.purple.withOpacity(dim ? .28 : .88),
          AppColors.cyan.withOpacity(dim ? .35 : .95)
        ]),
        boxShadow: [
          BoxShadow(
              color: AppColors.cyan.withOpacity(dim ? .08 : .24),
              blurRadius: 32)
        ],
      ),
      child: Center(
        child: Container(
          width: size - 8,
          height: size - 8,
          decoration:
              const BoxDecoration(shape: BoxShape.circle, color: AppColors.bg),
        ),
      ),
    );
  }
}

class PagerDot extends StatelessWidget {
  final bool active;

  const PagerDot({super.key, required this.active});

  @override
  Widget build(BuildContext context) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.cyan : Colors.white.withOpacity(.18)));
}

class Tag extends StatelessWidget {
  final String text;

  const Tag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.cyan.withOpacity(.8)),
          color: Colors.black.withOpacity(.25)),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.cyan,
              fontWeight: FontWeight.w900,
              fontSize: 14)),
    );
  }
}

class BulletLine extends StatelessWidget {
  final String text;
  final Color color;
  final bool cross;

  const BulletLine(
      {super.key, required this.text, required this.color, this.cross = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(cross ? '×' : '•',
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withOpacity(.82),
                      fontSize: 14,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StatRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIcon(icon: icon, color: AppColors.cyan, size: 48),
        const SizedBox(width: 18),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 33,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

TextStyle smallSectionStyle() => const TextStyle(
    color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900);

void _noop() {}

class SceneItem {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final String image;

  const SceneItem(this.title, this.desc, this.icon, this.color, this.image);
}

const scenes = [
  SceneItem('办公室', '工间燃脂，效率加倍', Icons.business_center_rounded, AppColors.blue,
      Assets.light),
  SceneItem(
      '客厅/沙发', '在家也能高效训练', Icons.chair_rounded, AppColors.purple, Assets.relax),
  SceneItem('起床后', '唤醒身体，活力满满', Icons.wb_sunny_rounded, AppColors.amber,
      Assets.stretch),
  SceneItem('睡前放松', '放松身心，助眠舒缓', Icons.nightlight_round, AppColors.purple,
      Assets.relax),
  SceneItem(
      '旅途中', '没有器械也能活动', Icons.work_rounded, AppColors.cyan, Assets.light),
  SceneItem('楼梯/台阶', '强化下肢与心肺', Icons.stairs_rounded, AppColors.cyan,
      Assets.strength),
];

class ObjectItem {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final String? image;

  const ObjectItem(this.title, this.desc, this.icon, this.color, [this.image]);
}

const objects = [
  ObjectItem(
      '空手', '无需器械', Icons.back_hand_rounded, AppColors.cyan, Assets.bodyAll),
  ObjectItem(
      '椅子', '稳定支撑', Icons.chair_alt_rounded, AppColors.amber, Assets.chairDip),
  ObjectItem('墙面', '支撑训练', Icons.grid_view_rounded, AppColors.cyan),
  ObjectItem(
      '水瓶', '灵活负重', Icons.water_drop_rounded, AppColors.blue, Assets.bottle),
  ObjectItem('背包', '增加挑战', Icons.backpack_rounded, AppColors.purple),
  ObjectItem('沙发', '居家辅助', Icons.chair_rounded, AppColors.purple, Assets.relax),
  ObjectItem('毛巾', '拉伸辅助', Icons.dry_cleaning_rounded, AppColors.cyan),
  ObjectItem('台阶', '强阶训练', Icons.stairs_rounded, AppColors.cyan),
];

class BodyTarget {
  final String title;
  final String desc;
  final String image;

  const BodyTarget(this.title, this.desc, this.image);
}

const bodyTargets = [
  BodyTarget('上肢', '手臂 / 肩部 / 胸部', Assets.bodyUpper),
  BodyTarget('核心', '腹部 / 腰部 / 核心', Assets.bodyCore),
  BodyTarget('下肢', '腿部 / 臀部', Assets.bodyLower),
  BodyTarget('全身', '全面训练', Assets.bodyAll),
];

class WorkoutData {
  final String title;
  final String part;
  final String image;
  final List<String> tips;
  final List<String> warnings;

  const WorkoutData(
      this.title, this.part, this.image, this.tips, this.warnings);
}

const workoutCards = [
  WorkoutData(
      '椅子辅助深蹲',
      '下肢 / 臀部',
      Assets.chairSquat,
      ['双脚与肩同宽，脚尖微外展', '臀部向后坐，膝盖不超过脚尖', '轻触椅面后发力站起，保持核心收紧'],
      ['膝盖内扣或大幅超过脚尖', '身体前倾导致腰部代偿', '站起时借助惯性弹起']),
  WorkoutData(
      '椅子臂屈伸',
      '上肢 / 手臂',
      Assets.chairDip,
      ['双手握住椅边，指尖朝前', '肘关节向后弯曲，身体垂直下沉', '臀部发力推起，避免耸肩'],
      ['肘部外翻或内扣过度', '身体前移导致肩部受压', '下沉时过浅，效果不佳']),
  WorkoutData(
      '椅子仰卧抬腿',
      '核心 / 腹部',
      Assets.legRaise,
      ['仰卧，双手置于身体两侧', '核心收紧，双腿伸直抬起', '慢速控制下落，保持腰部贴地'],
      ['腰部离地或拱起', '借助惯性甩腿', '屈膝导致强度下降']),
];

const alternativeCards = [
  WorkoutData('椅子箭步蹲', '下肢 / 臀部', Assets.alt1, ['保持躯干稳定'], ['膝盖内扣']),
  WorkoutData('椅子提膝', '下肢 / 小腿', Assets.alt2, ['抬膝时核心收紧'], ['身体后仰']),
  WorkoutData('椅子俯身划船', '上肢 / 背部', Assets.alt3, ['背部保持平直'], ['耸肩代偿']),
  WorkoutData('椅子侧支撑', '核心 / 侧腹', Assets.alt4, ['髋部保持抬起'], ['塌腰']),
  WorkoutData('椅子卷腹', '核心 / 腹部', Assets.alt5, ['吐气卷起'], ['颈部发力']),
  WorkoutData('椅子深蹲停顿', '下肢 / 臀部', Assets.alt6, ['底部短暂停顿'], ['失去控制']),
];

class CollectionItem {
  final String title;
  final int count;
  final ObjectItem object;

  const CollectionItem(this.title, this.count, this.object);
}

final collectionSeries = [
  CollectionItem('家具系列', 15, objects[1]),
  CollectionItem('瓶罐系列', 12, objects[3]),
  CollectionItem('布料系列', 9, objects[6]),
  CollectionItem('学习办公', 10, objects[0]),
];

const legendColors = [
  AppColors.blue,
  AppColors.green,
  AppColors.purple,
  AppColors.amber,
  AppColors.cyan,
  Colors.grey
];
