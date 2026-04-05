---
name: yt-dlp
description: Video and audio download tool supporting 1000+ platforms including YouTube, Bilibili, Twitter, TikTok, Instagram, etc. Use when users request downloading videos, extracting audio from videos, getting video information, or downloading content from video-sharing platforms. Triggered by requests like "download this video", "extract audio from", "get video info", or when provided with video URLs.
---

# yt-dlp Video Downloader

Download videos and audio from 1000+ platforms using the powerful yt-dlp tool.

## Quick Start

### Prerequisites

Ensure yt-dlp is installed:
```bash
# Check installation
yt-dlp --version

# Install if needed
pip install yt-dlp
# or: brew install yt-dlp
```

### Basic Usage

**Download video (best quality):**
```bash
python scripts/download_video.py "https://www.youtube.com/watch?v=xxx"
```

**Download to specific directory:**
```bash
python scripts/download_video.py "https://www.youtube.com/watch?v=xxx" -o ~/Videos
```

**Extract audio only (MP3):**
```bash
python scripts/download_video.py "https://www.youtube.com/watch?v=xxx" -a
```

**Download with specific quality:**
```bash
python scripts/download_video.py "https://www.youtube.com/watch?v=xxx" -q 720p
```

**Get video info without downloading:**
```bash
python scripts/download_video.py "https://www.youtube.com/watch?v=xxx" --info-only
```

## Common Tasks

### 1. Download Videos

Use `scripts/download_video.py` for most download tasks.

**Available options:**
- `-o, --output <path>` - Output directory (default: ./downloads)
- `-q, --quality <quality>` - Quality: best, 1080p, 720p, 480p
- `-a, --audio-only` - Extract audio as MP3
- `-s, --subtitles` - Download subtitles
- `-f, --format <spec>` - Custom format specification
- `--info-only` - Show info without downloading

**Examples:**
```bash
# Download highest quality to custom folder
python scripts/download_video.py "URL" -o ~/Downloads/Videos -q best

# Download 720p with subtitles
python scripts/download_video.py "URL" -q 720p -s

# Extract audio only
python scripts/download_video.py "URL" -a -o ~/Music
```

### 2. Check Available Formats

Use `scripts/get_formats.py` to see all available quality options before downloading.

```bash
python scripts/get_formats.py "https://www.youtube.com/watch?v=xxx"
```

This displays:
- Available video qualities (4K, 1080p, 720p, etc.)
- Audio formats and bitrates
- File sizes (when available)
- Format IDs for advanced usage

### 3. Handle Different Platforms

Most platforms work with the same commands. See `references/platforms.md` for platform-specific notes.

**Commonly supported platforms:**
- YouTube, Bilibili, Twitter/X, TikTok
- Instagram, Facebook, Reddit, Vimeo
- And 1000+ more

**Special cases:**
- **Authentication required**: Some platforms need cookies
- **Geo-restrictions**: May need proxy
- **Live streams**: Supported with monitoring options

Read `references/platforms.md` when encountering platform-specific issues.

## Workflow

When a user requests video download:

1. **Verify URL format** - Ensure valid video URL
2. **Check requirements** (optional):
   - Run `scripts/get_formats.py` to show available qualities
   - Ask user for quality preference if needed
3. **Download**:
   - Use `scripts/download_video.py` with appropriate options
   - Default to best quality unless specified
4. **Confirm completion** - Show output path

## Advanced Usage

### Custom Format Selection

For precise control, use format codes from `get_formats.py`:

```bash
# Best video + best audio (recommended)
yt-dlp -f 'bestvideo+bestaudio' <url>

# Specific format IDs
yt-dlp -f 137+140 <url>

# Best quality ≤1080p
yt-dlp -f 'bestvideo[height<=1080]+bestaudio' <url>
```

### Batch Downloads

Download multiple videos:
```bash
# From a playlist
python scripts/download_video.py "PLAYLIST_URL" -q 720p

# From a text file with URLs
while read url; do
  python scripts/download_video.py "$url" -o ~/Videos
done < urls.txt
```

### Platform-Specific Options

For geo-restricted or authenticated content:

```bash
# Use browser cookies
yt-dlp --cookies-from-browser chrome <url>

# Use proxy
yt-dlp --proxy socks5://127.0.0.1:1080 <url>

# Live stream monitoring
yt-dlp --wait-for-video 10 <url>
```

See `references/platforms.md` for detailed platform guides.

## Troubleshooting

**"yt-dlp not found"**
- Install: `pip install yt-dlp` or `brew install yt-dlp`

**"Video unavailable"**
- May be geo-blocked or require authentication
- Check `references/platforms.md` for platform-specific solutions

**"Format not available"**
- Run `scripts/get_formats.py` to see available options
- Try lower quality setting

**Download too slow**
- Check internet connection
- Try different quality (lower file size)
- Platform CDN may be slow

## Resources

- `scripts/download_video.py` - Main download script
- `scripts/get_formats.py` - Format inspection tool
- `references/platforms.md` - Platform-specific guides and tips
