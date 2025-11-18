import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 设置Tab - 用户偏好设置
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  // 设置状态
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedDifficulty = 'Intermediate';
  double _workoutReminderHour = 9.0; // 9 AM

  final List<String> _languages = ['English', '中文', 'Español', 'Français'];
  final List<String> _difficulties = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 用户偏好设置
        _buildSectionHeader('Preferences', Icons.tune),
        const SizedBox(height: 8),
        _buildSettingsCard([
          _buildSwitchSetting(
            'Sound Effects',
            'Enable workout sound effects',
            Icons.volume_up,
            _soundEnabled,
            (value) => setState(() => _soundEnabled = value),
          ),
          _buildSwitchSetting(
            'Vibration',
            'Haptic feedback during workouts',
            Icons.vibration,
            _vibrationEnabled,
            (value) => setState(() => _vibrationEnabled = value),
          ),
          _buildSwitchSetting(
            'Dark Mode',
            'Use dark theme',
            Icons.dark_mode,
            _darkModeEnabled,
            (value) => setState(() => _darkModeEnabled = value),
          ),
        ]),

        const SizedBox(height: 24),

        // 通知设置
        _buildSectionHeader('Notifications', Icons.notifications_outlined),
        const SizedBox(height: 8),
        _buildSettingsCard([
          _buildSwitchSetting(
            'Push Notifications',
            'Workout reminders and achievements',
            Icons.notifications,
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          _buildSliderSetting(
            'Daily Reminder',
            'Set your preferred workout time',
            Icons.schedule,
            _workoutReminderHour,
            0,
            23,
            (value) => setState(() => _workoutReminderHour = value),
            _formatHour(_workoutReminderHour),
          ),
        ]),

        const SizedBox(height: 24),

        // 训练设置
        _buildSectionHeader('Workout Settings', Icons.fitness_center),
        const SizedBox(height: 8),
        _buildSettingsCard([
          _buildDropdownSetting(
            'Default Difficulty',
            'Your preferred workout difficulty',
            Icons.trending_up,
            _selectedDifficulty,
            _difficulties,
            (value) => setState(() => _selectedDifficulty = value!),
          ),
          _buildDropdownSetting(
            'Language',
            'App display language',
            Icons.language,
            _selectedLanguage,
            _languages,
            (value) => setState(() => _selectedLanguage = value!),
          ),
        ]),

        const SizedBox(height: 24),

        // 账户设置
        _buildSectionHeader('Account', Icons.person_outline),
        const SizedBox(height: 8),
        _buildSettingsCard([
          _buildActionSetting(
            'Edit Profile',
            'Update your personal information',
            Icons.edit,
            () => _handleEditProfile(),
          ),
          _buildActionSetting(
            'Data & Privacy',
            'Manage your data and privacy settings',
            Icons.privacy_tip,
            () => _handleDataPrivacy(),
          ),
          _buildActionSetting(
            'Export Data',
            'Download your workout data',
            Icons.download,
            () => _handleExportData(),
          ),
        ]),

        const SizedBox(height: 24),

        // 应用信息
        _buildSectionHeader('About', Icons.info_outline),
        const SizedBox(height: 8),
        _buildSettingsCard([
          _buildActionSetting(
            'Help & Support',
            'Get help and contact support',
            Icons.help,
            () => _handleHelp(),
          ),
          _buildActionSetting(
            'Rate the App',
            'Share your feedback on the app store',
            Icons.star,
            () => _handleRateApp(),
          ),
          _buildActionSetting(
            'Terms of Service',
            'Read our terms and conditions',
            Icons.description,
            () => _handleTerms(),
          ),
          _buildActionSetting(
            'Privacy Policy',
            'Learn about our privacy practices',
            Icons.policy,
            () => _handlePrivacyPolicy(),
          ),
        ]),

        const SizedBox(height: 16),

        // 版本信息
        Center(
          child: Text(
            'SnapRep v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  /// 构建区域标题
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF4CAF50),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// 构建设置卡片容器
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// 构建开关设置项
  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF4CAF50),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4CAF50),
      ),
    );
  }

  /// 构建滑动条设置项
  Widget _buildSliderSetting(
    String title,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String displayValue,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4CAF50),
              inactiveTrackColor: const Color(0xFF4CAF50).withOpacity(0.2),
              thumbColor: const Color(0xFF4CAF50),
              overlayColor: const Color(0xFF4CAF50).withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建下拉选择设置项
  Widget _buildDropdownSetting(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF4CAF50),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建操作设置项
  Widget _buildActionSetting(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF4CAF50),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  /// 格式化小时
  String _formatHour(double hour) {
    final h = hour.round();
    if (h == 0) return '12:00 AM';
    if (h == 12) return '12:00 PM';
    if (h < 12) return '$h:00 AM';
    return '${h - 12}:00 PM';
  }

  /// 处理编辑个人资料
  void _handleEditProfile() {
    debugPrint('Edit profile tapped');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Profile editing feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 处理数据隐私
  void _handleDataPrivacy() {
    debugPrint('Data privacy tapped');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data & Privacy'),
        content: const Text('Your data is secure with us. We do not share personal information with third parties.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 处理导出数据
  void _handleExportData() {
    debugPrint('Export data tapped');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Would you like to export your workout data as a CSV file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 实际的导出功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export started...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  /// 处理帮助支持
  void _handleHelp() {
    debugPrint('Help tapped');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text('For support, please contact us at support@snaprep.com\n\nWe typically respond within 24 hours.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// 处理评分应用
  void _handleRateApp() {
    debugPrint('Rate app tapped');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate SnapRep'),
        content: const Text('Enjoying SnapRep? Please rate us on the App Store!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  /// 处理服务条款
  void _handleTerms() {
    debugPrint('Terms tapped');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service\n\n'
            '1. Use of the app is subject to these terms.\n'
            '2. The app is provided "as is" without warranties.\n'
            '3. Users must be 13 years or older.\n'
            '4. Content must not violate applicable laws.\n'
            '5. We reserve the right to modify these terms.\n\n'
            'Last updated: November 2024',
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

  /// 处理隐私政策
  void _handlePrivacyPolicy() {
    debugPrint('Privacy policy tapped');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            'We respect your privacy and are committed to protecting your personal data.\n\n'
            'Data we collect:\n'
            '• Workout session data\n'
            '• App usage analytics\n'
            '• Device information\n\n'
            'How we use your data:\n'
            '• To provide and improve our services\n'
            '• To personalize your experience\n'
            '• For analytics and research\n\n'
            'We do not sell or share your personal information with third parties.\n\n'
            'Last updated: November 2024',
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