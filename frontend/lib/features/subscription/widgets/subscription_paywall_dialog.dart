import 'package:flutter/material.dart';
import '../../../core/services/subscription_service.dart';

/// 订阅付费弹窗
/// 当用户达到每日限制或需要付费功能时显示
/// 设计风格参考付费订阅.md文档
class SubscriptionPaywallDialog extends StatefulWidget {
  final String? triggerSource; // 触发来源(用于埋点分析)
  final VoidCallback? onSubscribed; // 订阅成功回调

  const SubscriptionPaywallDialog({
    super.key,
    this.triggerSource,
    this.onSubscribed,
  });

  @override
  State<SubscriptionPaywallDialog> createState() =>
      _SubscriptionPaywallDialogState();
}

class _SubscriptionPaywallDialogState extends State<SubscriptionPaywallDialog> {
  bool isYearlySelected = true; // 默认推荐年付
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildTrialBanner(),
                    const SizedBox(height: 24),
                    _buildFeaturesList(),
                    const SizedBox(height: 24),
                    _buildPricingCards(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildContinueButton(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// 页面头部 - 带关闭按钮
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock Unlimited',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Workouts & Premium Features',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Color(0xFF666666)),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  /// 免费试用横幅
  Widget _buildTrialBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            '7-Day Free Trial',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 功能特性列表
  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.fitness_center, 'text': 'Unlimited workouts every day'},
      {'icon': Icons.star_rounded, 'text': 'Access to premium challenges'},
      {'icon': Icons.trending_up, 'text': 'Advanced progress analytics'},
      {'icon': Icons.lock_open, 'text': 'Unlock all exercise variations'},
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: const Color(0xFF6C5CE7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature['text'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 价格卡片
  Widget _buildPricingCards() {
    return Column(
      children: [
        // 年付方案 (推荐)
        _buildPricingCard(
          title: 'Premium Yearly',
          subtitle: 'Most Popular',
          price: '\$29.99',
          period: 'per year',
          savings: 'Save 50%',
          monthlyEquivalent: '\$2.50/month',
          isSelected: isYearlySelected,
          isRecommended: true,
          onTap: () => setState(() => isYearlySelected = true),
        ),

        const SizedBox(height: 16),

        // 月付方案
        _buildPricingCard(
          title: 'Premium Monthly',
          subtitle: 'Flexible plan',
          price: '\$4.99',
          period: 'per month',
          isSelected: !isYearlySelected,
          onTap: () => setState(() => isYearlySelected = false),
        ),
      ],
    );
  }

  /// 单个价格卡片
  Widget _buildPricingCard({
    required String title,
    required String subtitle,
    required String price,
    required String period,
    String? savings,
    String? monthlyEquivalent,
    required bool isSelected,
    bool isRecommended = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF6C5CE7) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF6C5CE7).withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 6 : 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                      if (monthlyEquivalent != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          monthlyEquivalent,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C5CE7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            period,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (savings != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B894),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          savings,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // Selection indicator
            if (isSelected) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF6C5CE7),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Selected',
                      style: TextStyle(
                        color: Color(0xFF6C5CE7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 继续按钮
  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: isLoading ? null : _handleStartTrial,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: const Color(0xFF6C5CE7).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBackgroundColor: const Color(0xFF6C5CE7).withOpacity(0.5),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Start Free Trial',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  /// 页脚信息
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Text(
            isYearlySelected
                ? '7 days free, then \$29.99 per year. Cancel anytime.'
                : '7 days free, then \$4.99 per month. Cancel anytime.',
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _showTerms(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Terms of Service',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text(' • ', style: TextStyle(color: Color(0xFFCCCCCC))),
              TextButton(
                onPressed: () => _showPrivacy(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 处理开始试用
  Future<void> _handleStartTrial() async {
    setState(() => isLoading = true);

    try {
      await SubscriptionService().startFreeTrial();

      if (!mounted) return;

      // 试用开始成功
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('🎉 Free trial started! Enjoy 7 days of premium access.'),
          backgroundColor: Color(0xFF00B894),
          duration: Duration(seconds: 5),
        ),
      );

      // 关闭弹窗并调用回调
      Navigator.pop(context, true);
      widget.onSubscribed?.call();
    } catch (e) {
      if (!mounted) return;

      // 提取错误信息
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      // 显示详细错误对话框
      _showErrorDialog(
        'Unable to Start Trial',
        errorMessage,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// 显示错误对话框
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE74C3C), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6C5CE7),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示服务条款
  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service content goes here...\n\n'
            'By using SnapRep Premium, you agree to our terms.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// 显示隐私政策
  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy content goes here...\n\n'
            'We protect your data and privacy.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// 显示订阅付费弹窗的辅助方法
Future<bool?> showSubscriptionPaywall(
  BuildContext context, {
  String? triggerSource,
  VoidCallback? onSubscribed,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => SubscriptionPaywallDialog(
      triggerSource: triggerSource,
      onSubscribed: onSubscribed,
    ),
  );
}
