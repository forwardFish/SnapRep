import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 首字母头像生成器
/// 当 avatarUrl 为 null 时，使用用户名首字母生成本地头像
class InitialAvatar extends StatelessWidget {
  final String name;
  final String? email;
  final double size;
  final double fontSize;

  const InitialAvatar({
    super.key,
    required this.name,
    this.email,
    this.size = 60,
    this.fontSize = 24,
  });

  /// 获取用户名的首字母（1-2个字符）
  String _getInitials() {
    if (name.isEmpty) {
      // 如果 name 为空，尝试使用 email
      if (email != null && email!.isNotEmpty) {
        final emailName = email!.split('@')[0];
        return emailName.substring(0, math.min(1, emailName.length)).toUpperCase();
      }
      return 'U'; // 默认为 'U' (User)
    }

    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      // 取前两个单词的首字母：John Doe → JD
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else {
      // 单个单词取前1-2个字符：Alice → AL, 林 → 林
      final firstWord = parts[0];
      // 中文只取1个字符，英文取前2个
      final isChinese = RegExp(r'[\u4e00-\u9fa5]').hasMatch(firstWord);
      if (isChinese) {
        return firstWord[0];
      } else {
        return firstWord.substring(0, math.min(2, firstWord.length)).toUpperCase();
      }
    }
  }

  /// 根据名字生成一致的颜色
  Color _getBackgroundColor() {
    final colors = [
      const Color(0xFFFF6B6B), // 红色
      const Color(0xFF4ECDC4), // 青色
      const Color(0xFF45B7D1), // 蓝色
      const Color(0xFF96CEB4), // 绿色
      const Color(0xFFFD79A8), // 粉色
      const Color(0xFFA29BFE), // 紫色
      const Color(0xFFFD7272), // 浅红
      const Color(0xFF54A0FF), // 天蓝
      const Color(0xFF48DBFB), // 青蓝
      const Color(0xFF1DD1A1), // 翠绿
      const Color(0xFFFFC048), // 橙色
      const Color(0xFFEE5A6F), // 玫红
      const Color(0xFFC44569), // 深红
      const Color(0xFF786FA6), // 靛色
      const Color(0xFFF8A5C2), // 樱粉
      const Color(0xFF63CDDA), // 水蓝
      const Color(0xFFEA8685), // 珊瑚
      const Color(0xFF596275), // 石板灰
      const Color(0xFF574B90), // 深紫
      const Color(0xFFF19066), // 橘色
      const Color(0xFF546DE5), // 宝蓝
      const Color(0xFFE66767), // 砖红
      const Color(0xFF303952), // 深灰
      const Color(0xFF3C6382), // 钢蓝
      const Color(0xFF6C5CE7), // 紫罗兰
      const Color(0xFFFFD700), // 金色
    ];

    // 使用简单的哈希算法确保同名用户颜色一致
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final index = hash.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials();
    final backgroundColor = _getBackgroundColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Avatar Widget Wrapper
/// 优先使用 avatarUrl，如果为 null 则使用首字母头像
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String? email;
  final double size;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.email,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    // 如果有 avatarUrl，使用网络图片
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2C2C2C),
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // 如果网络图片加载失败，fallback 到首字母头像
              return InitialAvatar(
                name: name,
                email: email,
                size: size,
                fontSize: size * 0.4,
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFFFFD700),
                  strokeWidth: 2,
                ),
              );
            },
          ),
        ),
      );
    }

    // 如果没有 avatarUrl，使用首字母头像
    return InitialAvatar(
      name: name,
      email: email,
      size: size,
      fontSize: size * 0.4,
    );
  }
}
