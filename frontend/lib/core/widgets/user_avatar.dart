import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 用户头像组件
///
/// 支持多种头像显示方式：
/// 1. 网络图片 URL (avatarUrl)
/// 2. 基于用户名首字母的生成头像 (name)
/// 3. 默认占位符
///
/// 设计原则：
/// - Material Design 3 风格
/// - 26种优雅的渐变配色方案
/// - 高对比度，确保可读性
/// - 一致性：同名用户颜色一致
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;
  final String? email;
  final double size;
  final double fontSize;
  final double borderWidth;
  final Color? borderColor;

  const UserAvatar({
    Key? key,
    this.avatarUrl,
    this.name,
    this.email,
    this.size = 50,
    this.fontSize = 20,
    this.borderWidth = 0,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 如果有头像 URL 且不为空，显示网络图片
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return _buildNetworkAvatar(context);
    }

    // 否则，生成基于首字母的头像
    return _buildGeneratedAvatar(context);
  }

  /// 构建网络图片头像（带加载失败回退）
  Widget _buildNetworkAvatar(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? Theme.of(context).dividerColor,
                width: borderWidth,
              )
            : null,
      ),
      child: ClipOval(
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingAvatar(context);
          },
          errorBuilder: (context, error, stackTrace) {
            // 加载失败时，回退到生成头像
            return _buildGeneratedAvatar(context);
          },
        ),
      ),
    );
  }

  /// 构建加载中占位符
  Widget _buildLoadingAvatar(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// 构建基于首字母的生成头像
  Widget _buildGeneratedAvatar(BuildContext context) {
    final displayName = name ?? email ?? 'U';
    final initials = _getInitials(displayName);
    final colors = _getGradientColors(displayName);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.3),
                width: borderWidth,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// 获取用户名的首字母（1-2个字符）
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final trimmed = name.trim();
    final parts = trimmed.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      // 取前两个单词的首字母：John Doe → JD
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      // 单个单词
      final firstWord = parts[0];
      // 中文只取1个字符，英文取前1-2个
      final isChinese = RegExp(r'[\u4e00-\u9fa5]').hasMatch(firstWord);
      if (isChinese) {
        return firstWord[0];
      } else {
        final length = math.min(2, firstWord.length);
        return firstWord.substring(0, length).toUpperCase();
      }
    }
  }

  /// 根据名字生成一致的渐变色
  /// 使用哈希算法确保同名用户颜色一致
  List<Color> _getGradientColors(String name) {
    final index = _getColorIndex(name);
    final gradients = _colorGradients;
    return gradients[index % gradients.length];
  }

  /// 计算名字的哈希值并映射到颜色索引
  int _getColorIndex(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return hash.abs();
  }

  /// 26种优雅的渐变配色方案
  /// 参考 Material Design 3 色板
  static const List<List<Color>> _colorGradients = [
    // 红色系
    [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
    [Color(0xFFE66767), Color(0xFFC44569)],
    [Color(0xFFFD7272), Color(0xFFC44569)],

    // 粉色系
    [Color(0xFFFD79A8), Color(0xFFF093FB)],
    [Color(0xFFF8A5C2), Color(0xFFF78FB3)],
    [Color(0xFFEA8685), Color(0xFFD76C6C)],

    // 橙色系
    [Color(0xFFF19066), Color(0xFFE77F67)],
    [Color(0xFFFFC048), Color(0xFFF79F1F)],
    [Color(0xFFFF9A56), Color(0xFFEE7752)],

    // 黄色系
    [Color(0xFFFFEAA7), Color(0xFFFDCB6E)],
    [Color(0xFFFEC163), Color(0xFFDE7112)],
    [Color(0xFFFFCB77), Color(0xFFF3A683)],

    // 绿色系
    [Color(0xFF96CEB4), Color(0xFF7FB069)],
    [Color(0xFF1DD1A1), Color(0xFF10AC84)],
    [Color(0xFF55E6C1), Color(0xFF25CCF7)],

    // 青色系
    [Color(0xFF4ECDC4), Color(0xFF44A08D)],
    [Color(0xFF63CDDA), Color(0xFF3DC1D3)],
    [Color(0xFF48DBFB), Color(0xFF0ABDE3)],

    // 蓝色系
    [Color(0xFF45B7D1), Color(0xFF3498DB)],
    [Color(0xFF54A0FF), Color(0xFF2E86DE)],
    [Color(0xFF546DE5), Color(0xFF3F51B5)],
    [Color(0xFF3C6382), Color(0xFF2C3E50)],

    // 紫色系
    [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
    [Color(0xFF786FA6), Color(0xFF574B90)],
    [Color(0xFF9B59B6), Color(0xFF8E44AD)],

    // 特殊色系
    [Color(0xFF596275), Color(0xFF303952)], // 石板灰
    [Color(0xFFDFE6E9), Color(0xFFB2BEC3)], // 浅灰
  ];
}

/// 大尺寸用户头像（用于个人资料页面）
class LargeUserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;
  final String? email;
  final VoidCallback? onTap;

  const LargeUserAvatar({
    Key? key,
    this.avatarUrl,
    this.name,
    this.email,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          UserAvatar(
            avatarUrl: avatarUrl,
            name: name,
            email: email,
            size: 100,
            fontSize: 36,
            borderWidth: 3,
            borderColor: Colors.white,
          ),
          if (onTap != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 小尺寸用户头像（用于列表、评论等）
class SmallUserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;
  final String? email;

  const SmallUserAvatar({
    Key? key,
    this.avatarUrl,
    this.name,
    this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      avatarUrl: avatarUrl,
      name: name,
      email: email,
      size: 32,
      fontSize: 14,
    );
  }
}
