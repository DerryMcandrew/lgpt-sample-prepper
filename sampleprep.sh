#!/usr/bin/env bash
set -euo pipefail
set -o errtrace
IFS=$'\n\t'

# Sampleprep: batch convert and key-tag audio files in parallel

# Default configs (override via env)
SAMPLES_DIR="${SAMPLES_DIR:-$HOME/samples}"
KEYFINDER_CMD="${KEYFINDER_CMD:-$(command -v keyfinder-cli || echo keyfinder-cli)}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 1)}"

usage() {
  cat <<EOF
Usage: $0 [-j N] [-d]
  -j N    Number of parallel jobs (default: CPU cores)
  -d      Dry run; show actions without executing
  -h      Show this help
EOF
  exit 1
}

DRY=0
while getopts ":j:dh" opt; do
  case $opt in
    j) JOBS=$OPTARG ;;
    d) DRY=1     ;;
    h) usage     ;;
    *) usage     ;;
  esac
done
shift $((OPTIND-1))

# Make sure keyfinder-cli exists
if ! command -v "${KEYFINDER_CMD%% *}" &>/dev/null; then
  echo "error: keyfinder-cli not found" >&2
  exit 1
fi

# Find all .wav/.mp3 under $SAMPLES_DIR
mapfile -t files < <(find "$SAMPLES_DIR" -type f \( -iname '*.wav' -o -iname '*.mp3' \))
total=${#files[@]}
(( total )) || { echo "No audio files found in $SAMPLES_DIR"; exit 0; }

echo "[INFO] Processing $total files in '$SAMPLES_DIR' with $JOBS job(s)${DRY:+ (dry run)}"

process_file() {
  local file="$1"
  local base name dir tmp raw key clean out

  base=$(basename "$file")
  name="${base%.*}"
  dir=$(dirname "$file")
  tmp="${dir}/${name}_conv.wav"

  # 1) Convert to mono WAV @ 44.1kHz
  echo "[RUN] ffmpeg -> $tmp"
  (( DRY )) || ffmpeg -hide_banner -v error -y -i "$file" -ar 44100 -ac 1 -sample_fmt s16 "$tmp"

  # 2) Run keyfinder
  raw=$("$KEYFINDER_CMD" "$tmp" 2>&1)
  key=$(printf '%s\n' "$raw" | sed -n '1{s/^[[:space:]]*//;s/[[:space:]]*$//;p}')

  if [[ -z "$key" ]]; then
    (( DRY )) || rm -f "$tmp"
    echo "[WARN] no key for $base"
    return
  fi

  # 3) Rename & cleanup
  clean=${name%%_*}
  out="${dir}/${clean}_${key}.wav"
  echo "[RUN] mv $tmp -> $out"
  if (( DRY )); then
    echo "[DRY] Would remove original: $file"
  else
    mv "$tmp" "$out" && rm -f "$file"
  fi

  echo "[DONE] $out"
}

export DRY KEYFINDER_CMD
export -f process_file

# Parallel dispatch: note the '_' placeholder for $0, then file becomes $1
printf '%s\0' "${files[@]}" |
  xargs -0 -P "$JOBS" -n1 bash -c 'process_file "$1"' _ \
  || echo "[ERROR] Parallel processing failed"

echo "[INFO] All done at $(date '+%Y-%m-%d %H:%M:%S')"
