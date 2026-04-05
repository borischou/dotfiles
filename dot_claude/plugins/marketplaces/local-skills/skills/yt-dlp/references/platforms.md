# Supported Platforms

yt-dlp supports 1000+ websites. Below are the most commonly used platforms and any special considerations.

## Popular Video Platforms

### YouTube
- **URL formats**:
  - `https://www.youtube.com/watch?v=VIDEO_ID`
  - `https://youtu.be/VIDEO_ID`
  - Playlists: `https://www.youtube.com/playlist?list=PLAYLIST_ID`
- **Special features**:
  - Live streams supported
  - Automatic subtitle download available
  - Age-restricted videos supported with cookies
- **Quality options**: Up to 8K (4320p), HDR, 60fps

### Bilibili
- **URL formats**:
  - `https://www.bilibili.com/video/BV***`
  - `https://www.bilibili.com/video/av***`
- **Special notes**:
  - May require cookies for high quality
  - Danmaku (弹幕) not downloaded by default

### Twitter / X
- **URL formats**:
  - `https://twitter.com/user/status/ID`
  - `https://x.com/user/status/ID`
- **Notes**: Videos are usually limited to 1080p

### TikTok
- **URL formats**:
  - `https://www.tiktok.com/@user/video/ID`
  - `https://vt.tiktok.com/SHORT_CODE/`
- **Notes**: Watermark included in downloaded videos

### Instagram
- **URL formats**:
  - Posts: `https://www.instagram.com/p/POST_ID/`
  - Reels: `https://www.instagram.com/reel/REEL_ID/`
- **Notes**: May require authentication for private accounts

### Facebook
- **URL formats**:
  - `https://www.facebook.com/watch/?v=VIDEO_ID`
- **Notes**: Authentication often required

### Reddit
- **URL formats**:
  - `https://www.reddit.com/r/subreddit/comments/POST_ID/`
- **Notes**: Direct video links work best

### Vimeo
- **URL formats**:
  - `https://vimeo.com/VIDEO_ID`
- **Notes**: High quality options available

## Platform-Specific Tips

### For platforms requiring authentication:
```bash
# Use cookies from browser
yt-dlp --cookies-from-browser chrome <url>
```

### For geo-restricted content:
```bash
# Use proxy
yt-dlp --proxy socks5://127.0.0.1:1080 <url>
```

### For live streams:
```bash
# Download live stream
yt-dlp <live_url>

# Monitor and download when live starts
yt-dlp --wait-for-video 10 <live_url>
```

## Common Issues

1. **"Video unavailable"**: May be geo-blocked or require authentication
2. **"Format not available"**: Try different quality settings
3. **Slow download**: Use `--concurrent-fragments` or change CDN with `--extractor-args`
