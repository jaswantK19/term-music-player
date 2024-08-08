
#!/bin/zsh

# Directory containing ambient music
MUSIC_DIR="$HOME/music-player/music-repo"

# Check if the directory exists
if [[ ! -d "$MUSIC_DIR" ]]; then
  echo "Music directory not found at $MUSIC_DIR"
  exit 1
fi

# Find all music files in the directory, shuffle them, and handle spaces
find "$MUSIC_DIR" -type f \( -iname "*.mp3" -or -iname "*.wav" -or -iname "*.flac" \) -print0 | shuf -z | while IFS= read -r -d '' file; do
  echo "Now playing: $file"
  mpv --no-video "$file"
done

