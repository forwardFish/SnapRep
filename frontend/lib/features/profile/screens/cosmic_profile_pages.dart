import 'package:flutter/material.dart';

const double _maxPhoneWidth = 470;

class CosmicProfileHome extends StatelessWidget {
  final VoidCallback onOpenCollection;
  final VoidCallback onOpenCard;

  const CosmicProfileHome({
    super.key,
    required this.onOpenCollection,
    required this.onOpenCard,
  });

  @override
  Widget build(BuildContext context) {
    return _CosmicScaffold(
      bottomPadding: 112,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 116),
        children: [
          const _TopBrand(showSettings: true),
          const SizedBox(height: 28),
          const _ProfileHero(),
          const SizedBox(height: 22),
          const _StatsGlassCard(),
          const SizedBox(height: 18),
          _CollectionBanner(
            onTap: onOpenCollection,
            onOpenCard: onOpenCard,
          ),
          const SizedBox(height: 18),
          _TrainingCalendarCard(onTap: onOpenCollection),
        ],
      ),
    );
  }
}

class CosmicCollectionPage extends StatefulWidget {
  const CosmicCollectionPage({super.key});

  @override
  State<CosmicCollectionPage> createState() => _CosmicCollectionPageState();
}

class _CosmicCollectionPageState extends State<CosmicCollectionPage> {
  String selected = '全部';

  @override
  Widget build(BuildContext context) {
    return _CosmicScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          const _CollectionHeader(),
          const SizedBox(height: 22),
          const _CollectionSummaryCard(),
          const SizedBox(height: 16),
          _RarityFilter(
            selected: selected,
            onChanged: (value) => setState(() => selected = value),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            itemCount: _cards.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              childAspectRatio: .54,
            ),
            itemBuilder: (context, index) {
              final card = _cards[index];
              return _MiniTrainingCard(
                card: card,
                onTap: () => Navigator.of(context).push(
                  _snapPageRoute(CosmicCardDetailPage(card: card)),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          _AchievementEntry(onTap: () {}),
        ],
      ),
    );
  }
}

class CosmicCardDetailPage extends StatelessWidget {
  final TrainingCard card;

  const CosmicCardDetailPage({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return _CosmicScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          _DetailHeader(onShare: () {
            Navigator.of(context)
                .push(_snapPageRoute(CosmicShareCardPage(card: card)));
          }),
          const SizedBox(height: 16),
          _HeroAchievementCard(card: card, compact: false),
          const SizedBox(height: 26),
          const _SectionLabel('挑战数据'),
          const SizedBox(height: 12),
          const _ChallengeStats(),
          const SizedBox(height: 24),
          const _SectionLabel('卡片故事'),
          const SizedBox(height: 12),
          const _StoryPanel(),
          const SizedBox(height: 24),
          const _SectionLabel('卡片属性加成'),
          const SizedBox(height: 12),
          const _BoostPanel(),
          const SizedBox(height: 26),
          _PrimaryGlowButton(
            label: '分享卡片',
            subtitle: '让朋友见证你的成就',
            icon: Icons.share_rounded,
            onTap: () => Navigator.of(context).push(
              _snapPageRoute(CosmicShareCardPage(card: card)),
            ),
          ),
        ],
      ),
    );
  }
}

class CosmicShareCardPage extends StatelessWidget {
  final TrainingCard card;

  const CosmicShareCardPage({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return _CosmicScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 34),
        children: [
          const _ShareHeader(),
          const SizedBox(height: 20),
          _HeroAchievementCard(card: card, compact: true),
          const SizedBox(height: 18),
          const _ShareCaptionCard(),
          const SizedBox(height: 20),
          Text(
            '长按图片可保存到相册',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.68),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _GhostActionButton(
                  label: '保存图片',
                  icon: Icons.download_rounded,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _SolidActionButton(
                  label: '立即分享',
                  icon: Icons.reply_rounded,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CosmicScaffold extends StatelessWidget {
  final Widget child;
  final double bottomPadding;

  const _CosmicScaffold({
    required this.child,
    this.bottomPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CosmicColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxPhoneWidth),
          child: Stack(
            children: [
              const Positioned.fill(child: _CosmicBackground()),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CosmicBackground extends StatelessWidget {
  const _CosmicBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF02060C),
            Color(0xFF020812),
            Color(0xFF05030A),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 70,
            right: -70,
            child: _GlowOrb(color: _CosmicColors.blue, size: 250, opacity: .32),
          ),
          const Positioned(
            top: 210,
            left: -110,
            child: _GlowOrb(color: _CosmicColors.cyan, size: 220, opacity: .18),
          ),
          const Positioned(
            bottom: 80,
            right: -80,
            child:
                _GlowOrb(color: _CosmicColors.purple, size: 260, opacity: .20),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _StarsPainter()),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * .22),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _TopBrand extends StatelessWidget {
  final bool showSettings;

  const _TopBrand({this.showSettings = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _SnapLogo(size: 30),
        const Spacer(),
        if (showSettings)
          _RoundIconButton(
            icon: Icons.settings_outlined,
            onTap: () {},
          ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 112,
          height: 112,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                _CosmicColors.cyan,
                _CosmicColors.blue,
                _CosmicColors.cyan
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _CosmicColors.cyan.withOpacity(.35),
                blurRadius: 24,
              ),
            ],
          ),
          child: const CircleAvatar(
            backgroundImage: AssetImage(_AssetRefs.dip),
            backgroundColor: Colors.black,
          ),
        ),
        const SizedBox(width: 22),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RepMaster',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.6,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '自律即自由，训练即信仰。',
                style: TextStyle(
                  color: Color(0xFFC8D0DC),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGlassCard extends StatelessWidget {
  const _StatsGlassCard();

  @override
  Widget build(BuildContext context) {
    return const _GlassCard(
      radius: 24,
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _BigStat(
              icon: Icons.library_add_check_outlined,
              label: '收藏卡片',
              value: '68',
              color: _CosmicColors.blue,
            ),
          ),
          _VerticalRule(),
          Expanded(
            child: _BigStat(
              icon: Icons.fitness_center_rounded,
              label: '训练次数',
              value: '28',
              color: _CosmicColors.purple,
            ),
          ),
          _VerticalRule(),
          Expanded(
            child: _BigStat(
              icon: Icons.check_circle_outline_rounded,
              label: '本周完成',
              value: '12',
              color: _CosmicColors.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionBanner extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onOpenCard;

  const _CollectionBanner({
    required this.onTap,
    required this.onOpenCard,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _GlassCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 14),
        borderColor: _CosmicColors.purple.withOpacity(.55),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -4,
              bottom: -10,
              child: GestureDetector(
                onTap: onOpenCard,
                child: SizedBox(
                  width: 160,
                  child: _CardStackPreview(card: _cards[1]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 132),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.style_outlined,
                      color: _CosmicColors.purple, size: 34),
                  const SizedBox(height: 14),
                  const Text(
                    '卡片收藏',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '探索并收集强大训练卡片',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _RarityRow(),
                ],
              ),
            ),
            const Positioned(
              right: 4,
              top: 64,
              child: Icon(Icons.chevron_right_rounded,
                  color: Colors.white70, size: 36),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingCalendarCard extends StatelessWidget {
  final VoidCallback onTap;

  const _TrainingCalendarCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      borderColor: _CosmicColors.blue.withOpacity(.50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_available_rounded,
                  color: _CosmicColors.blue, size: 34),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '训练记录',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '查看训练日历与历史完成',
                      style: TextStyle(
                        color: Color(0xFFB8C1CC),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StreakInline(),
            ],
          ),
          const SizedBox(height: 18),
          _GlassCard(
            radius: 16,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            color: Colors.black.withOpacity(.20),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.chevron_left_rounded,
                        color: Colors.white70, size: 30),
                    Spacer(),
                    Text(
                      '2024年7月',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white70, size: 30),
                  ],
                ),
                const SizedBox(height: 12),
                const _CalendarGrid(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _LegendDot(color: _CosmicColors.cyan, text: '已训练'),
                    const SizedBox(width: 24),
                    _LegendDot(
                        color: Colors.white.withOpacity(.8),
                        text: '今天',
                        hollow: true),
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

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _RoundIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => Navigator.pop(context)),
            const SizedBox(width: 16),
            const _SnapLogo(size: 22),
            const Spacer(),
            const _StreakPill(),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          '卡片收藏',
          style: TextStyle(
            color: Color(0xFFF0E8FF),
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '收集卡片，提升属性，挑战更高等级',
          style: TextStyle(
            color: Colors.white.withOpacity(.74),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CollectionSummaryCard extends StatelessWidget {
  const _CollectionSummaryCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 20,
      borderColor: _CosmicColors.purple.withOpacity(.55),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: '已拥有卡片\n',
                    style: TextStyle(
                        color: Color(0xFFB8C4D0), fontSize: 14, height: 1.6),
                  ),
                  TextSpan(
                    text: '28',
                    style: TextStyle(
                      color: _CosmicColors.cyan,
                      fontSize: 37,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: ' / 60\n',
                    style: TextStyle(
                        color: Color(0xFFB8C4D0),
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: '持续收集，解锁更强自己',
                    style: TextStyle(
                        color: Color(0xFFB8C4D0), fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RarityStat(label: '普通', value: '8', color: Colors.white70),
                _RarityStat(label: '稀有', value: '7', color: _CosmicColors.blue),
                _RarityStat(
                    label: '史诗', value: '6', color: _CosmicColors.purple),
                _RarityStat(label: '传说', value: '4', color: _CosmicColors.gold),
                _RarityStat(label: '神话', value: '3', color: Color(0xFFD66CFF)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RarityFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _RarityFilter({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['全部', '普通', '稀有', '史诗', '传说', '神话'];
    return _GlassCard(
      radius: 19,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(label),
                child: Container(
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: selected == label
                        ? _CosmicColors.cyan.withOpacity(.16)
                        : Colors.transparent,
                    border: selected == label
                        ? Border.all(color: _CosmicColors.cyan.withOpacity(.8))
                        : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected == label
                          ? _CosmicColors.cyan
                          : Colors.white.withOpacity(.74),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.filter_alt_outlined,
              color: Colors.white70, size: 20),
        ],
      ),
    );
  }
}

class _MiniTrainingCard extends StatelessWidget {
  final TrainingCard card;
  final VoidCallback onTap;

  const _MiniTrainingCard({
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: card.color.withOpacity(.82)),
          boxShadow: [
            BoxShadow(color: card.color.withOpacity(.20), blurRadius: 14),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(card.image, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(.10),
                      Colors.black.withOpacity(.22),
                      Colors.black.withOpacity(.90),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 7,
                left: 7,
                child: _MiniBadge(label: card.rarity, color: card.color),
              ),
              Positioned(
                top: 7,
                right: 7,
                child: Text(
                  'Lv.${card.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: card.progress,
                        backgroundColor: Colors.white.withOpacity(.14),
                        valueColor: AlwaysStoppedAnimation<Color>(card.color),
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

class _DetailHeader extends StatelessWidget {
  final VoidCallback onShare;

  const _DetailHeader({required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        const Spacer(),
        const _SnapLogo(size: 24),
        const Spacer(),
        const _StreakPill(),
      ],
    );
  }
}

class _ShareHeader extends StatelessWidget {
  const _ShareHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _RoundIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => Navigator.pop(context)),
            const Spacer(),
            const _SnapLogo(size: 22),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          '分享卡片 ✦',
          style: TextStyle(
            color: Color(0xFFF0E8FF),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '分享你的成就，激励更多人',
          style: TextStyle(
            color: Colors.white.withOpacity(.68),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeroAchievementCard extends StatelessWidget {
  final TrainingCard card;
  final bool compact;

  const _HeroAchievementCard({
    required this.card,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 555 : 410,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: _CosmicColors.purple.withOpacity(.9), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _CosmicColors.purple.withOpacity(.36), blurRadius: 26),
          BoxShadow(color: _CosmicColors.cyan.withOpacity(.18), blurRadius: 34),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(card.image, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(.28),
                    Colors.transparent,
                    Colors.black.withOpacity(.76),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 24,
              left: 26,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SnapLogo(size: 22),
                  SizedBox(height: compact ? 34 : 48),
                  Text(
                    compact ? '椅子日挑战完成' : '椅子日挑战',
                    style: TextStyle(
                      color: const Color(0xFFFFE6B2),
                      fontSize: compact ? 31 : 29,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 8)
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    compact
                        ? 'CHAIR DAY CHALLENGE COMPLETED'
                        : 'CHAIR DAY CHALLENGE',
                    style: const TextStyle(
                      color: Color(0xFFE7D5BE),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 14),
                    Text(
                      '◷ 2024.07.20 解锁',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.72),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Positioned(
              top: 24,
              right: 26,
              child: _MythicBadge(),
            ),
            if (compact)
              const Positioned(
                left: 18,
                right: 18,
                bottom: 98,
                child: _InlineChallengeStats(),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: compact ? 62 : 28,
              child: Text(
                '“ 稳稳当当，坐练成神 ”',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(.82),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
            ),
            if (compact)
              Positioned(
                left: 22,
                right: 22,
                bottom: 22,
                child: Row(
                  children: [
                    Text(
                      '2024.07.20',
                      style: TextStyle(
                          color: Colors.white.withOpacity(.70),
                          fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      'SnapRep',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.42),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: _CosmicColors.cyan,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                  color: _CosmicColors.cyan.withOpacity(.65), blurRadius: 12),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ChallengeStats extends StatelessWidget {
  const _ChallengeStats();

  @override
  Widget build(BuildContext context) {
    return const _GlassCard(
      radius: 18,
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(
              child: _IconStat(
                  icon: Icons.schedule_rounded, label: '挑战时长', value: '7 天')),
          _VerticalRule(),
          Expanded(
              child: _IconStat(
                  icon: Icons.fitness_center_rounded,
                  label: '总训练',
                  value: '21 次')),
          _VerticalRule(),
          Expanded(
              child: _IconStat(
                  icon: Icons.local_fire_department_rounded,
                  label: '消耗热量',
                  value: '2186 kcal')),
        ],
      ),
    );
  }
}

class _StoryPanel extends StatelessWidget {
  const _StoryPanel();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          const Positioned(
            right: 6,
            top: 0,
            bottom: 0,
            child:
                Icon(Icons.blur_on_rounded, color: Color(0x554B2D9E), size: 82),
          ),
          Text(
            '在平凡的椅子上，完成不平凡的突破。\n7天坚持，21次训练，你用自律创造了改变。\n这张卡片，记录了你的椅子日传奇。',
            style: TextStyle(
              color: Colors.white.withOpacity(.72),
              fontSize: 16,
              height: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostPanel extends StatelessWidget {
  const _BoostPanel();

  @override
  Widget build(BuildContext context) {
    return const _GlassCard(
      radius: 18,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BoostItem(icon: Icons.bolt_rounded, label: '力量', value: '+15%'),
          _BoostItem(
              icon: Icons.favorite_border_rounded, label: '耐力', value: '+15%'),
          _BoostItem(
              icon: Icons.local_fire_department_outlined,
              label: '燃脂',
              value: '+20%'),
          _BoostItem(
              icon: Icons.star_border_rounded, label: '专注', value: '+10%'),
        ],
      ),
    );
  }
}

class _ShareCaptionCard extends StatelessWidget {
  const _ShareCaptionCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF16212B),
            child: Icon(Icons.local_fire_department_rounded,
                color: _CosmicColors.cyan),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '我刚刚完成了 # 椅子日挑战！',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '用座椅也能练出强大，挑战7天，见证蜕变。',
                  style: TextStyle(
                    color: Color(0xFFB8C3CE),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(painter: _QrPainter()),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? color;

  const _GlassCard({
    required this.child,
    required this.padding,
    required this.radius,
    this.borderColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? const Color(0xCC07111B),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Colors.white.withOpacity(.12)),
        boxShadow: [
          BoxShadow(color: _CosmicColors.cyan.withOpacity(.08), blurRadius: 24),
          BoxShadow(
              color: Colors.black.withOpacity(.45),
              blurRadius: 18,
              offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}

class _SnapLogo extends StatelessWidget {
  final double size;

  const _SnapLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: -1.2,
        ),
        children: const [
          TextSpan(text: 'Snap', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'Rep', style: TextStyle(color: _CosmicColors.cyan)),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(.24),
          border: Border.all(color: Colors.white.withOpacity(.16)),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill();

  @override
  Widget build(BuildContext context) {
    return const _GlassCard(
      radius: 24,
      padding: EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              color: _CosmicColors.cyan, size: 21),
          SizedBox(width: 6),
          Text('连续打卡 ',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          Text('7',
              style: TextStyle(
                  color: _CosmicColors.cyan,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          Text(' 天',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StreakInline extends StatelessWidget {
  const _StreakInline();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.local_fire_department_rounded,
            color: _CosmicColors.cyan, size: 21),
        SizedBox(width: 5),
        Text('连续打卡 ',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        Text('7',
            style: TextStyle(
                color: _CosmicColors.cyan,
                fontSize: 21,
                fontWeight: FontWeight.w900)),
        Text(' 天',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BigStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BigStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(.72),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: color.withOpacity(.65), blurRadius: 10)
            ],
          ),
        ),
      ],
    );
  }
}

class _IconStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _IconStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _CosmicColors.purple.withOpacity(.20),
          child: Icon(icon, color: _CosmicColors.purple, size: 24),
        ),
        const SizedBox(height: 12),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(.62), fontSize: 14)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VerticalRule extends StatelessWidget {
  const _VerticalRule();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 52, color: Colors.white.withOpacity(.14));
  }
}

class _RarityRow extends StatelessWidget {
  const _RarityRow();

  @override
  Widget build(BuildContext context) {
    const data = [
      ('神话', '6', Color(0xFFC577FF)),
      ('传说', '12', _CosmicColors.gold),
      ('史诗', '18', _CosmicColors.purple),
      ('稀有', '20', _CosmicColors.cyan),
      ('普通', '12', Colors.white70),
    ];

    return Row(
      children: [
        for (final item in data)
          Padding(
            padding: const EdgeInsets.only(right: 9),
            child: Column(
              children: [
                Text(
                  item.$1,
                  style: TextStyle(
                      color: item.$3,
                      fontSize: 12,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  item.$2,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CardStackPreview extends StatelessWidget {
  final TrainingCard card;

  const _CardStackPreview({required this.card});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (var i = 3; i >= 0; i--)
          Transform.translate(
            offset: Offset(i * 8.0, i * -5.0),
            child: Transform.rotate(
              angle: (i - 1.5) * .10,
              child: Container(
                width: 112,
                height: 142,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: _CosmicColors.purple.withOpacity(.88)),
                  boxShadow: [
                    BoxShadow(
                        color: _CosmicColors.purple.withOpacity(.35),
                        blurRadius: 18)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(card.image, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid();

  @override
  Widget build(BuildContext context) {
    const days = ['日', '一', '二', '三', '四', '五', '六'];
    final trained = {2, 4, 5, 6, 7, 11, 16, 19, 24, 27};
    return Column(
      children: [
        Row(
          children: [
            for (final day in days)
              Expanded(
                child: Center(
                  child: Text(day,
                      style: TextStyle(
                          color: Colors.white.withOpacity(.70),
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          itemCount: 35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, childAspectRatio: 1.18),
          itemBuilder: (context, index) {
            final raw = index - 1;
            final day = raw <= 0 ? raw + 30 : raw;
            final inMonth = raw > 0 && raw <= 31;
            final isToday = day == 30 && inMonth;
            final isTrained = trained.contains(day) && inMonth;
            return Center(
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTrained
                      ? _CosmicColors.cyan.withOpacity(.68)
                      : Colors.transparent,
                  border: isToday
                      ? Border.all(color: _CosmicColors.cyan, width: 2)
                      : null,
                  boxShadow: isTrained
                      ? [
                          BoxShadow(
                              color: _CosmicColors.cyan.withOpacity(.38),
                              blurRadius: 10)
                        ]
                      : null,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color:
                        inMonth ? Colors.white : Colors.white.withOpacity(.25),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;
  final bool hollow;

  const _LegendDot({
    required this.color,
    required this.text,
    this.hollow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hollow ? Colors.transparent : color,
            border: hollow ? Border.all(color: color) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _RarityStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RarityStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.auto_awesome_rounded, color: color, size: 27),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _AchievementEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _AchievementEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.style_outlined,
              color: Colors.white.withOpacity(.62), size: 34),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('卡片成就',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 5),
                Text('收集卡片，解锁专属成就与奖励',
                    style: TextStyle(color: Color(0xFFABB6C2), fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white70, size: 30),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: color.withOpacity(.22),
        border: Border.all(color: color.withOpacity(.65)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _MythicBadge extends StatelessWidget {
  const _MythicBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _CosmicColors.purple.withOpacity(.25),
            border: Border.all(color: _CosmicColors.purple.withOpacity(.76)),
            boxShadow: [
              BoxShadow(
                  color: _CosmicColors.purple.withOpacity(.45), blurRadius: 22)
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Color(0xFFE1A2FF), size: 42),
        ),
        const SizedBox(height: 8),
        const Text('神话',
            style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900)),
        const Text('MYTHIC',
            style: TextStyle(
                color: Color(0xFFD8DCE8),
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _InlineChallengeStats extends StatelessWidget {
  const _InlineChallengeStats();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      color: Colors.black.withOpacity(.42),
      child: const Row(
        children: [
          Expanded(child: _SmallInlineStat(label: '挑战时长', value: '7 天')),
          _VerticalRule(),
          Expanded(child: _SmallInlineStat(label: '总训练', value: '21 次')),
          _VerticalRule(),
          Expanded(child: _SmallInlineStat(label: '消耗热量', value: '2186 kcal')),
        ],
      ),
    );
  }
}

class _SmallInlineStat extends StatelessWidget {
  final String label;
  final String value;

  const _SmallInlineStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _BoostItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BoostItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: _CosmicColors.cyan, size: 31),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(.58),
                fontSize: 13,
                fontWeight: FontWeight.w700)),
        Text(value,
            style: const TextStyle(
                color: _CosmicColors.cyan,
                fontSize: 17,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _PrimaryGlowButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryGlowButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
              colors: [_CosmicColors.cyan, _CosmicColors.blue]),
          boxShadow: [
            BoxShadow(
                color: _CosmicColors.cyan.withOpacity(.50), blurRadius: 22)
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.black, size: 24),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 23,
                        fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 3),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.black.withOpacity(.72),
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _GhostActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GhostActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _SolidActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SolidActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_CosmicColors.cyan, _CosmicColors.blue]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: _CosmicColors.cyan.withOpacity(.35), blurRadius: 18)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final points = <Offset>[
      Offset(size.width * .72, 90),
      Offset(size.width * .79, 118),
      Offset(size.width * .58, 145),
      Offset(size.width * .88, 210),
      Offset(size.width * .63, 248),
      Offset(size.width * .44, 96),
      Offset(size.width * .28, 340),
      Offset(size.width * .76, 520),
      Offset(size.width * .18, 640),
      Offset(size.width * .86, 760),
    ];

    for (var i = 0; i < points.length; i++) {
      paint.color = (i.isEven ? _CosmicColors.cyan : _CosmicColors.purple)
          .withOpacity(.35);
      canvas.drawCircle(points[i], i % 3 == 0 ? 1.6 : 1.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = Colors.black;
    final cyan = Paint()..color = _CosmicColors.cyan;
    final cell = size.width / 9;
    final blocks = <Offset>[
      const Offset(0, 0),
      const Offset(1, 0),
      const Offset(2, 0),
      const Offset(6, 0),
      const Offset(8, 0),
      const Offset(0, 1),
      const Offset(2, 1),
      const Offset(4, 1),
      const Offset(7, 1),
      const Offset(0, 2),
      const Offset(1, 2),
      const Offset(2, 2),
      const Offset(5, 2),
      const Offset(8, 2),
      const Offset(3, 3),
      const Offset(6, 3),
      const Offset(7, 3),
      const Offset(1, 4),
      const Offset(4, 4),
      const Offset(5, 4),
      const Offset(8, 4),
      const Offset(0, 5),
      const Offset(2, 5),
      const Offset(6, 5),
      const Offset(0, 6),
      const Offset(1, 6),
      const Offset(2, 6),
      const Offset(4, 6),
      const Offset(8, 6),
      const Offset(6, 7),
      const Offset(8, 7),
      const Offset(0, 8),
      const Offset(3, 8),
      const Offset(5, 8),
      const Offset(6, 8),
      const Offset(8, 8),
    ];

    for (final block in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              block.dx * cell + 3, block.dy * cell + 3, cell - 2, cell - 2),
          const Radius.circular(1),
        ),
        block == const Offset(4, 4) ? cyan : dark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

PageRouteBuilder<T> _snapPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curve =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(begin: const Offset(.05, .02), end: Offset.zero)
              .animate(curve),
          child: child,
        ),
      );
    },
  );
}

class TrainingCard {
  final String title;
  final String rarity;
  final String image;
  final Color color;
  final int level;
  final double progress;

  const TrainingCard({
    required this.title,
    required this.rarity,
    required this.image,
    required this.color,
    required this.level,
    required this.progress,
  });
}

class _CosmicColors {
  static const bg = Color(0xFF02060C);
  static const cyan = Color(0xFF20E7FF);
  static const blue = Color(0xFF168DFF);
  static const purple = Color(0xFF9456FF);
  static const gold = Color(0xFFFFAA2B);
}

class _AssetRefs {
  static const dip =
      'assets/images/workout_result/exercise_02_chair_dip_visual.jpg';
  static const squat =
      'assets/images/workout_result/exercise_01_chair_squat_visual.jpg';
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

const _cards = [
  TrainingCard(
    title: '俯卧撑',
    rarity: '稀有',
    image: _AssetRefs.alt3,
    color: _CosmicColors.cyan,
    level: 3,
    progress: .60,
  ),
  TrainingCard(
    title: '椅子臂屈伸',
    rarity: '史诗',
    image: _AssetRefs.dip,
    color: _CosmicColors.purple,
    level: 4,
    progress: .68,
  ),
  TrainingCard(
    title: '深蹲',
    rarity: '传说',
    image: _AssetRefs.squat,
    color: _CosmicColors.gold,
    level: 5,
    progress: .62,
  ),
  TrainingCard(
    title: '平板支撑',
    rarity: '神话',
    image: _AssetRefs.alt4,
    color: Color(0xFFC76BFF),
    level: 3,
    progress: .50,
  ),
  TrainingCard(
    title: '靠墙静蹲',
    rarity: '普通',
    image: _AssetRefs.alt2,
    color: Colors.white70,
    level: 2,
    progress: .80,
  ),
  TrainingCard(
    title: '椅子卷腹',
    rarity: '稀有',
    image: _AssetRefs.legRaise,
    color: _CosmicColors.blue,
    level: 2,
    progress: .70,
  ),
  TrainingCard(
    title: '登山跑',
    rarity: '史诗',
    image: _AssetRefs.alt5,
    color: _CosmicColors.purple,
    level: 3,
    progress: .75,
  ),
  TrainingCard(
    title: '保加利亚分腿蹲',
    rarity: '传说',
    image: _AssetRefs.alt1,
    color: _CosmicColors.gold,
    level: 2,
    progress: .60,
  ),
  TrainingCard(
    title: '反向支撑',
    rarity: '稀有',
    image: _AssetRefs.alt6,
    color: _CosmicColors.cyan,
    level: 1,
    progress: 1,
  ),
  TrainingCard(
    title: '抬腿举',
    rarity: '拾遗',
    image: _AssetRefs.legRaise,
    color: _CosmicColors.purple,
    level: 1,
    progress: .60,
  ),
  TrainingCard(
    title: '开合跳',
    rarity: '普通',
    image: _AssetRefs.squat,
    color: Colors.white70,
    level: 1,
    progress: .40,
  ),
  TrainingCard(
    title: '侧平板支撑',
    rarity: '稀有',
    image: _AssetRefs.alt4,
    color: _CosmicColors.blue,
    level: 1,
    progress: .80,
  ),
];
