# 训练视频存放说明 / Workout Videos Storage Guide

## 视频文件位置 / Video File Location
请将训练视频文件放在此目录下：
Place workout video files in this directory:
```
frontend/assets/videos/
```

## 视频格式要求 / Video Format Requirements

### 文件格式 / File Format
- **格式**: MP4 (H.264 编码)
- **Format**: MP4 (H.264 encoded)

### 分辨率建议 / Resolution Recommendations
- **推荐**: 1280x720 (720p) 或 1920x1080 (1080p)
- **Recommended**: 1280x720 (720p) or 1920x1080 (1080p)
- **最小**: 640x480 (480p)
- **Minimum**: 640x480 (480p)

### 文件大小 / File Size
- **建议**: 每个视频 5-20 MB
- **Recommended**: 5-20 MB per video
- **最大**: 不超过 50 MB
- **Maximum**: No more than 50 MB

### 视频时长 / Video Duration
- **建议**: 15-60 秒
- **Recommended**: 15-60 seconds

## 命名规范 / Naming Convention

请按照以下格式命名视频文件：
Please name video files following this format:

```
wall_chest_opener.mp4
chair_sit_to_stand.mp4
core_three_point_support.mp4
```

## 当前需要的视频 / Videos Currently Needed

1. **wall_chest_opener.mp4**
   - 训练名称: Wall Chest Opener
   - 时长: 20秒左右
   - 内容: 靠墙胸部伸展动作

2. **chair_sit_to_stand.mp4**
   - 训练名称: Chair Sit-to-Stand
   - 时长: 30秒左右
   - 内容: 椅子起立动作

3. **core_three_point_support.mp4**
   - 训练名称: Core Three-Point Support
   - 时长: 15秒左右
   - 内容: 核心三点支撑动作

## 如何获取视频 / How to Get Videos

### 选项 1: 从网上下载 / Option 1: Download from Internet
推荐网站 / Recommended Sites:
- Pexels: https://www.pexels.com/search/videos/fitness/
- Pixabay: https://pixabay.com/videos/search/workout/
- Unsplash (部分视频): https://unsplash.com/

### 选项 2: 自己录制 / Option 2: Record Your Own
使用手机或相机录制，然后转换为 MP4 格式
Use phone or camera to record, then convert to MP4 format

### 选项 3: 使用占位视频 / Option 3: Use Placeholder Videos
暂时可以使用任何健身视频作为占位符
You can temporarily use any fitness video as a placeholder

## 配置文件更新 / Configuration File Update

视频文件放置后，需要更新 `pubspec.yaml`:
After placing video files, update `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/videos/wall_chest_opener.mp4
    - assets/videos/chair_sit_to_stand.mp4
    - assets/videos/core_three_point_support.mp4
```

## 代码中的使用 / Usage in Code

视频文件将在以下位置使用:
Video files will be used in:
- `challenges_page.dart` - 视频预览区域
- `professional_workout_video_page_v2.dart` - 视频播放页面

## 注意事项 / Notes

1. ⚠️ **版权**: 确保视频有合法使用权限
   **Copyright**: Ensure you have legal rights to use the videos

2. ⚠️ **文件大小**: 保持文件小以提高加载速度
   **File Size**: Keep files small for faster loading

3. ⚠️ **测试**: 放置视频后运行 `flutter clean` 和 `flutter pub get`
   **Testing**: Run `flutter clean` and `flutter pub get` after placing videos

## 问题排查 / Troubleshooting

如果视频无法显示:
If videos don't display:
1. 检查文件路径是否正确
2. 确认 `pubspec.yaml` 已更新
3. 运行 `flutter clean` 和 `flutter pub get`
4. 重新运行应用

---

**更新日期 / Last Updated**: 2025-01-21
