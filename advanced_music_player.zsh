
#!/bin/zsh

# Directory containing ambient music
MUSIC_DIR="$HOME/music-player/music-repo"

# Check if the directory exists
if [[ ! -d "$MUSIC_DIR" ]]; then
  echo "Music directory not found at $MUSIC_DIR"
  exit 1
fi

# Colors for UI
RESET_COLOR="\033[0m"
GREEN_COLOR="\033[1;32m"
YELLOW_COLOR="\033[1;33m"
CYAN_COLOR="\033[1;36m"
RED_COLOR="\033[1;31m"
MAGENTA_COLOR="\033[1;35m"
BLUE_COLOR="\033[1;34m"

# Array of colors for equalizer bars
EQUALIZER_COLORS=("$GREEN_COLOR" "$YELLOW_COLOR" "$CYAN_COLOR" "$RED_COLOR" "$MAGENTA_COLOR" "$BLUE_COLOR")

# Function to display a dashed progress bar and colorful equalizer
function show_progress_and_equalizer {
  local duration=$1
  local elapsed=$2
  local progressBarLength=30

  # Calculate progress
  local percent=$(( 100 * elapsed / duration ))
  local filledLength=$(( progressBarLength * elapsed / duration ))
  local emptyLength=$(( progressBarLength - filledLength ))
  local progressBar="${CYAN_COLOR}$(printf '━%.0s' $(seq 1 $filledLength))${RESET_COLOR}$(printf ' %.0s' $(seq 1 $emptyLength))"

  # Generate a colorful equalizer visualizer
  local equalizer=""
  for _ in {1..8}; do
    local height=$((RANDOM % 5 + 1))
    local color=${EQUALIZER_COLORS[RANDOM % ${#EQUALIZER_COLORS[@]}]}

    # Transition from dots to bars based on height
    local visualizer=""
    for ((i = 1; i <= height; i++)); do
      if [[ $i -lt 3 ]]; then
        visualizer+="."
      else
        visualizer+="|"
      fi
    done

    equalizer+="${color}${visualizer}${RESET_COLOR} "
  done

  printf "\rPlaying: [${progressBar}] ${percent}%% | ${equalizer}"
}

# Function to get the duration of the track
function get_duration {
  local file="$1"
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" | awk '{print int($1)}'
}

# Find all music files in the directory, shuffle them, and handle spaces
find "$MUSIC_DIR" -type f \( -iname "*.mp3" -or -iname "*.wav" -or -iname "*.flac" \) -print0 | shuf -z | while IFS= read -r -d '' file; do
  echo -e "${BLUE_COLOR}Now playing:${RESET_COLOR} ${YELLOW_COLOR}$(basename "$file")${RESET_COLOR}"
  
  # Get the duration of the track in seconds
  duration=$(get_duration "$file")

  # Play the file and show progress
  if [[ -n $duration ]]; then
    mpv --no-video --quiet --no-terminal --idle=no --input-ipc-server=/tmp/mpvsocket "$file" >/dev/null 2>&1 &
    mpv_pid=$!

    while kill -0 $mpv_pid 2>/dev/null; do
      # Query playback time from mpv IPC
      elapsed=$(echo '{ "command": ["get_property", "playback-time"] }' | socat - /tmp/mpvsocket | jq '.data')
      elapsed=$(printf "%.0f" "$elapsed")

      # Show progress and equalizer
      show_progress_and_equalizer $duration $elapsed

      sleep 1
    done
    echo "" # Ensure a new line after completion
  else
    echo -e "${RED_COLOR}Error: Could not determine the duration of the track.${RESET_COLOR}"
  fi
done

