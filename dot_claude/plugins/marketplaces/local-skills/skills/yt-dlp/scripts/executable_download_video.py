#!/usr/bin/env python3
"""
Download video using yt-dlp with configurable options.

Usage:
    python download_video.py <url> [options]

Options:
    --output, -o <path>       Output directory (default: ./downloads)
    --format, -f <format>     Format selection (default: best)
    --audio-only, -a          Extract audio only (MP3)
    --quality, -q <quality>   Quality: best, 1080p, 720p, 480p (default: best)
    --subtitles, -s           Download subtitles if available
    --info-only              Show video info without downloading

Examples:
    python download_video.py "https://www.youtube.com/watch?v=xxx"
    python download_video.py "https://www.youtube.com/watch?v=xxx" -o ~/Videos -q 720p
    python download_video.py "https://www.youtube.com/watch?v=xxx" -a
"""

import sys
import os
import subprocess
import json
from pathlib import Path


def check_yt_dlp():
    """Check if yt-dlp is installed."""
    try:
        subprocess.run(
            ["yt-dlp", "--version"],
            capture_output=True,
            check=True
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def get_video_info(url):
    """Get video information without downloading."""
    try:
        result = subprocess.run(
            ["yt-dlp", "--dump-json", "--no-playlist", url],
            capture_output=True,
            text=True,
            check=True
        )
        info = json.loads(result.stdout)
        return {
            "title": info.get("title"),
            "duration": info.get("duration"),
            "uploader": info.get("uploader"),
            "upload_date": info.get("upload_date"),
            "view_count": info.get("view_count"),
            "formats_available": len(info.get("formats", [])),
        }
    except Exception as e:
        return {"error": str(e)}


def download_video(url, output_dir="./downloads", format_spec="best", audio_only=False, quality=None, subtitles=False):
    """
    Download video using yt-dlp.

    Args:
        url: Video URL
        output_dir: Output directory path
        format_spec: Format specification string
        audio_only: Extract audio only
        quality: Quality preference (best, 1080p, 720p, 480p)
        subtitles: Download subtitles
    """
    # Create output directory
    output_path = Path(output_dir).expanduser()
    output_path.mkdir(parents=True, exist_ok=True)

    # Build yt-dlp command
    cmd = ["yt-dlp"]

    # Output template
    cmd.extend(["-o", str(output_path / "%(title)s.%(ext)s")])

    # Format selection
    if audio_only:
        cmd.extend(["-x", "--audio-format", "mp3"])
    elif quality:
        quality_map = {
            "best": "bestvideo+bestaudio/best",
            "1080p": "bestvideo[height<=1080]+bestaudio/best[height<=1080]",
            "720p": "bestvideo[height<=720]+bestaudio/best[height<=720]",
            "480p": "bestvideo[height<=480]+bestaudio/best[height<=480]",
        }
        cmd.extend(["-f", quality_map.get(quality, "best")])
    else:
        cmd.extend(["-f", format_spec])

    # Subtitles
    if subtitles:
        cmd.extend(["--write-subs", "--sub-lang", "en,zh-CN,zh-TW"])

    # Progress display
    cmd.append("--progress")

    # Merge output format
    cmd.extend(["--merge-output-format", "mp4"])

    # URL
    cmd.append(url)

    print(f"Running: {' '.join(cmd)}")
    print(f"Output directory: {output_path}")
    print("-" * 60)

    # Execute download
    try:
        subprocess.run(cmd, check=True)
        print("-" * 60)
        print(f"✅ Download completed successfully!")
        print(f"📁 Files saved to: {output_path}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Download failed: {e}")
        return False


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    # Check if yt-dlp is installed
    if not check_yt_dlp():
        print("❌ Error: yt-dlp is not installed.")
        print("\nInstall it using one of these methods:")
        print("  - pip: pip install yt-dlp")
        print("  - brew: brew install yt-dlp")
        print("  - Manual: https://github.com/yt-dlp/yt-dlp#installation")
        sys.exit(1)

    # Parse arguments
    url = sys.argv[1]
    output_dir = "./downloads"
    format_spec = "best"
    audio_only = False
    quality = None
    subtitles = False
    info_only = False

    i = 2
    while i < len(sys.argv):
        arg = sys.argv[i]
        if arg in ["-o", "--output"]:
            output_dir = sys.argv[i + 1]
            i += 2
        elif arg in ["-f", "--format"]:
            format_spec = sys.argv[i + 1]
            i += 2
        elif arg in ["-a", "--audio-only"]:
            audio_only = True
            i += 1
        elif arg in ["-q", "--quality"]:
            quality = sys.argv[i + 1]
            i += 2
        elif arg in ["-s", "--subtitles"]:
            subtitles = True
            i += 1
        elif arg == "--info-only":
            info_only = True
            i += 1
        else:
            print(f"Unknown argument: {arg}")
            sys.exit(1)

    # Info only mode
    if info_only:
        print("📹 Fetching video information...")
        info = get_video_info(url)
        if "error" in info:
            print(f"❌ Error: {info['error']}")
            sys.exit(1)

        print("\nVideo Information:")
        print(f"  Title: {info['title']}")
        print(f"  Duration: {info['duration']} seconds")
        print(f"  Uploader: {info['uploader']}")
        print(f"  Upload Date: {info['upload_date']}")
        print(f"  Views: {info['view_count']}")
        print(f"  Available Formats: {info['formats_available']}")
        return

    # Download video
    print(f"📹 Downloading video from: {url}")
    if audio_only:
        print("🎵 Mode: Audio extraction (MP3)")
    elif quality:
        print(f"📺 Mode: Video ({quality})")
    else:
        print(f"📺 Mode: Video ({format_spec})")

    success = download_video(
        url=url,
        output_dir=output_dir,
        format_spec=format_spec,
        audio_only=audio_only,
        quality=quality,
        subtitles=subtitles
    )

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
