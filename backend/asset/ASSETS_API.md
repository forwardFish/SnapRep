# Assets API Documentation

## Overview

统一的静态资源管理API，支持视频、图片等多种媒体文件的访问。

## API Endpoints

### 1. 获取视频文件

**GET** `/api/v1/assets/videos/:filename`

获取训练动作演示视频（支持流式传输和范围请求）

**Parameters:**
- `filename` (path) - 视频文件名，例如：`wall_chest_opener.mp4`

**Response:**
- `200` - 视频文件流
- `404` - 视频文件不存在

**Example:**
```
GET http://localhost:3000/api/v1/assets/videos/wall_chest_opener.mp4
```

**Features:**
- ✅ 支持 HTTP Range Request（视频拖动）
- ✅ 自动设置正确的 Content-Type
- ✅ 长期缓存（1年）
- ✅ CORS 支持

---

### 2. 获取图片文件

**GET** `/api/v1/assets/images/:filename`

获取图片文件（缩略图、场景图片、训练动作图片等）

**Parameters:**
- `filename` (path) - 图片文件名，例如：`exercise_thumbnail.jpg`

**Response:**
- `200` - 图片文件
- `404` - 图片文件不存在

**Example:**
```
GET http://localhost:3000/api/v1/assets/images/exercise_thumbnail.jpg
```

**Supported formats:**
- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)
- GIF (.gif)
- SVG (.svg)

**Features:**
- ✅ 缓存7天
- ✅ CORS 支持
- ✅ 自动 Content-Type 识别

---

### 3. 检查视频是否存在

**GET** `/api/v1/assets/videos/check/:filename`

检查视频文件是否存在（不下载文件）

**Parameters:**
- `filename` (path) - 视频文件名

**Response:**
```json
{
  "exists": true,
  "filename": "wall_chest_opener.mp4",
  "size": 1048576,
  "url": "/api/v1/assets/videos/wall_chest_opener.mp4"
}
```

**Example:**
```
GET http://localhost:3000/api/v1/assets/videos/check/wall_chest_opener.mp4
```

---

### 4. 检查图片是否存在

**GET** `/api/v1/assets/images/check/:filename`

检查图片文件是否存在（不下载文件）

**Parameters:**
- `filename` (path) - 图片文件名

**Response:**
```json
{
  "exists": true,
  "filename": "exercise_thumbnail.jpg",
  "size": 204800,
  "url": "/api/v1/assets/images/exercise_thumbnail.jpg"
}
```

---

## File Organization

```
backend/
└── asset/
    ├── videos/           # 训练视频文件
    │   ├── wall_chest_opener.mp4
    │   ├── chair_sit_to_stand.mp4
    │   └── core_three_point_support.mp4
    └── images/           # 图片资源
        ├── thumbnails/   # 缩略图
        ├── scenarios/    # 场景图片
        └── exercises/    # 训练动作图片
```

## Database Integration

### Exercises Table

新增字段：
```sql
ALTER TABLE "exercises"
ADD COLUMN "video_filename" TEXT;
```

**Example data:**
```sql
UPDATE "exercises"
SET "video_filename" = 'wall_chest_opener.mp4'
WHERE "code" = 'wall_chest_opener';
```

后端API会自动拼接完整URL：
```json
{
  "id": "ex_001",
  "code": "wall_chest_opener",
  "name": "Wall Chest Opener",
  "videoFilename": "wall_chest_opener.mp4",
  "videoUrl": "http://localhost:3000/api/v1/assets/videos/wall_chest_opener.mp4"
}
```

## Frontend Integration

### Flutter Video Player Example

```dart
import 'package:video_player/video_player.dart';

class ExerciseVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const ExerciseVideoPlayer({required this.videoUrl});

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : CircularProgressIndicator();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Usage Example

```dart
// 从API获取训练动作
final exercise = await exerciseService.getExerciseById('ex_001');

// 显示视频
ExerciseVideoPlayer(
  videoUrl: exercise.videoUrl, // 完整URL: http://localhost:3000/api/v1/assets/videos/...
)
```

## Video Optimization Guide

### 当前状态
- ✅ MP4 文件支持
- ✅ 流式传输
- ❌ 文件体积较大

### 优化建议

1. **转换为 H.265/HEVC 编码**
   ```bash
   ffmpeg -i input.mp4 -c:v libx265 -crf 28 -c:a copy output.mp4
   ```
   预计减少 50-70% 文件大小

2. **生成多分辨率版本**
   ```bash
   # 高清 (720p)
   ffmpeg -i input.mp4 -vf scale=-2:720 -c:v libx264 -crf 23 output_720p.mp4

   # 标清 (480p)
   ffmpeg -i input.mp4 -vf scale=-2:480 -c:v libx264 -crf 23 output_480p.mp4

   # 低清 (360p)
   ffmpeg -i input.mp4 -vf scale=-2:360 -c:v libx264 -crf 23 output_360p.mp4
   ```

3. **文件命名规范**
   - 原始：`{exercise_code}.mp4`
   - 优化：`{exercise_code}_opt.mp4`
   - 高清：`{exercise_code}_720p.mp4`
   - 标清：`{exercise_code}_480p.mp4`
   - 低清：`{exercise_code}_360p.mp4`

## Security Features

✅ **Directory Traversal Protection**
- 自动验证文件名
- 拒绝包含 `..`, `/`, `\` 的请求

✅ **CORS Support**
- 所有资源允许跨域访问

✅ **Cache Control**
- 视频：1年缓存
- 图片：7天缓存

## Testing

### Test Video Access

```bash
# 直接访问
curl http://localhost:3000/api/v1/assets/videos/wall_chest_opener.mp4

# 检查文件
curl http://localhost:3000/api/v1/assets/videos/check/wall_chest_opener.mp4

# Range Request（视频拖动）
curl -H "Range: bytes=0-1023" http://localhost:3000/api/v1/assets/videos/wall_chest_opener.mp4
```

### Test Image Access

```bash
# 直接访问
curl http://localhost:3000/api/v1/assets/images/exercise_thumbnail.jpg

# 检查文件
curl http://localhost:3000/api/v1/assets/images/check/exercise_thumbnail.jpg
```

## Migration Checklist

- [x] 创建 SQL migration 文件
- [x] 添加 video_filename 字段
- [x] 创建 AssetsController
- [x] 配置静态文件服务
- [x] 注册 AssetsModule
- [x] 创建 images 目录
- [ ] 更新 Exercise DAO 返回 videoUrl
- [ ] 更新前端 Exercise Model
- [ ] 测试视频流式传输
- [ ] 优化视频文件（可选）

## Next Steps

1. **运行数据库 migration**
   ```bash
   # Supabase SQL Editor
   # 执行 backend/sql/migration-add-video-filename.sql
   ```

2. **更新 Exercise DAO**
   - 在查询结果中添加 `videoUrl` 字段
   - 格式：`${baseUrl}/api/v1/assets/videos/${videoFilename}`

3. **更新前端 Exercise Model**
   - 添加 `videoUrl` 字段
   - 使用 video_player 插件播放

4. **测试完整流程**
   - 获取训练动作列表
   - 播放视频
   - 测试范围请求（视频拖动）

---

## Support

For questions or issues, contact the development team or check the codebase documentation.
