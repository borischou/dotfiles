#!/usr/bin/env python3
"""
Get available video formats for a URL using yt-dlp.

Usage:
    python get_formats.py <url>

Example:
    python get_formats.py "https://www.youtube.com/watch?v=xxx"
"""

import sys
import subprocess
import json


def get_formats(url):
    """Get all available formats for a video URL."""
    try:
        result = subprocess.run(
            ["yt-dlp", "--list-formats", "--dump-json", url],
            capture_output=True,
            text=True,
            check=True
        )

        # Parse first line (main video info)
        info = json.loads(result.stdout.split('\n')[0])

        print(f"📹 Video: {info.get('title')}")
        print(f"⏱️  Duration: {info.get('duration')} seconds")
        print(f"👤 Uploader: {info.get('uploader')}")
        print("\n" + "=" * 80)
        print("Available Formats:")
        print("=" * 80)

        formats = info.get('formats', [])

        # Group formats by type
        video_formats = []
        audio_formats = []

        for fmt in formats:
            format_id = fmt.get('format_id')
            ext = fmt.get('ext')
            resolution = fmt.get('resolution', 'audio only')
            filesize = fmt.get('filesize')
            vcodec = fmt.get('vcodec', 'none')
            acodec = fmt.get('acodec', 'none')

            size_str = f"{filesize / (1024*1024):.1f}MB" if filesize else "unknown"

            if vcodec != 'none' and acodec != 'none':
                # Video + Audio
                video_formats.append(f"  [{format_id:5}] {ext:4} {resolution:15} (video+audio) - {size_str}")
            elif vcodec != 'none':
                # Video only
                video_formats.append(f"  [{format_id:5}] {ext:4} {resolution:15} (video only)  - {size_str}")
            elif acodec != 'none':
                # Audio only
                abr = fmt.get('abr', 0)
                audio_formats.append(f"  [{format_id:5}] {ext:4} audio only ({abr}kbps) - {size_str}")

        if video_formats:
            print("\n🎬 Video Formats:")
            for fmt in video_formats[:15]:  # Show top 15
                print(fmt)

        if audio_formats:
            print("\n🎵 Audio Formats:")
            for fmt in audio_formats[:10]:  # Show top 10
                print(fmt)

        print("\n" + "=" * 80)
        print("💡 Tips:")
        print("  - Use format ID with -f option: yt-dlp -f 137+140 <url>")
        print("  - Best video+audio: yt-dlp -f 'bestvideo+bestaudio' <url>")
        print("  - Best quality ≤1080p: yt-dlp -f 'bestvideo[height<=1080]+bestaudio' <url>")
        print("  - Audio only MP3: yt-dlp -x --audio-format mp3 <url>")

    except subprocess.CalledProcessError as e:
        print(f"❌ Error: {e.stderr}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    url = sys.argv[1]
    print(f"🔍 Fetching available formats for: {url}\n")
    get_formats(url)


if __name__ == "__main__":
    main()
