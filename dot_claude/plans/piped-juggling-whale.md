# 实现计划：underwater_enhance.py

## Context

项目处于规划阶段，`video-enhance-plan.md` 已定义完整技术方案。需要实现单文件 Python 命令行工具 `underwater_enhance.py`。

## 实现步骤

### 1. UnderwaterEnhancer 类

包含 5 个处理方法和 1 个统一入口 `enhance()`：

- `auto_white_balance(img, strength)` — 三通道均值增益，strength 控制校正程度，各通道增益上限 R=1.8/G=1.5/B=1.2
- `dehaze(img, omega)` — 暗通道先验去雾，patch_size=15，导向滤波平滑透射率（radius=60, eps=1e-3），fallback 到双边滤波
- `apply_clahe(img, clip_limit)` — LAB 空间 L 通道 CLAHE，tileGridSize=(8,8)
- `enhance_color(img, saturation_boost)` — HSV 空间饱和度 × boost，明度 ×1.05
- `sharpen(img, strength)` — Unsharp Mask，sigma=3
- `enhance(img)` — 按序调用以上 5 步

构造函数接收所有参数，带默认值（medium 预设值）。

### 2. 图像处理函数

- `process_image(input_path, output_path, enhancer)` — 读取、增强、保存
- `create_comparison(original, enhanced)` — 左右拼接 + 中间白色分割线

### 3. 视频处理函数

- `process_video(input_path, output_path, enhancer)` — VideoCapture 逐帧处理，mp4v 临时输出，每 30 帧打印进度
- `process_video_comparison(input_path, output_path, enhancer)` — 同上，但每帧生成对比画面
- `ffmpeg_reencode(temp_path, final_path, audio_source)` — subprocess 调用 ffmpeg，hevc_videotoolbox 硬件编码，-c:a copy 保留音轨，处理完删除临时文件

### 4. 预设系统

字典定义 light/medium/heavy 三档参数，直接硬编码在文件中（不需要 presets.json）。

### 5. CLI 接口

argparse + 子命令（image/video/batch）：
- 公共参数：`-o/--output`、`--compare`、`--preset`、`--white-balance`、`--dehaze`、`--clahe`、`--color-boost`、`--sharpen`
- batch 子命令：输入为目录，自动处理所有图片/视频文件
- 自定义参数覆盖预设值

### 6. 导向滤波 Fallback

文件顶部 try/except 检测 `cv2.ximgproc`，设置全局标志 `HAS_GUIDED_FILTER`，dehaze 中据此选择滤波方式。

## 文件

- 创建：`/Users/zhouboli/Documents/video-enhance/underwater_enhance.py`（单文件，全部逻辑）

## 验证

```bash
# 确认语法正确
python underwater_enhance.py --help

# 测试图片处理（需要实际图片）
python underwater_enhance.py image test.jpg -o out.jpg --compare

# 测试视频处理
python underwater_enhance.py video test.mp4 -o out.mp4
```
