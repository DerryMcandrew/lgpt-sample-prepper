# SamplePrep for Little Piggy Tracker 🐷🎶

**TL;DR:**  
A no-BS bash script to batch-convert your `.wav`/`.mp3` files to mono 44.1 kHz and tag them with musical keys in parallel. Get your sample folder tracker-ready in seconds.

---

## 🚀 What It Does
- **Converts** all `.wav`/`.mp3` files under `SAMPLES_DIR` to mono WAV @ 44.1 kHz.
- **Detects** the musical key using `keyfinder-cli`.
- **Renames** each file to `<originalName>_<Key>.wav`.
- **Cleans up** intermediate files and originals.
- **Runs in parallel** across CPU cores (configurable).

No GUI, no hand-holding. Just drop your samples folder, run the script, and boom—key-tagged loops ready for Little Piggy Tracker.

---

## 🔧 Prerequisites
- **OS:** Unix-y environment (Linux, macOS, WSL, etc.)
- **Bash:** v4+ (for `mapfile`, `pipefail`, etc.)
- **ffmpeg** installed and in your `$PATH`.
- **keyfinder-cli** installed (see [KeyFinder](https://github.com/evansiroky/keyfinder) or your distro’s package).
- **xargs**, **nproc** (or fallback to 1 job on non-GNU systems).

---

## ⚙️ Installation
1. Clone or copy `sampleprep.sh` to somewhere in your `$PATH`.
2. `chmod +x sampleprep.sh`.

---

## 🛠️ Configuration
You can override defaults via environment variables:

| Variable         | Default                                      | What It Does                                 |
| ---------------- | -------------------------------------------- | --------------------------------------------- |
| `SAMPLES_DIR`    | `"$HOME/samples"`                            | Root folder to scan for `.wav` & `.mp3` files |
| `KEYFINDER_CMD`  | `keyfinder-cli`                              | Command to call KeyFinder                    |
| `JOBS`           | Number of CPU cores (`nproc`) or `1`         | Parallel processes count                      |

---

## 📖 Usage
```bash
# Dry-run only (no file modifications)
SAMPLES_DIR=~/myLoops ./sampleprep.sh -j 4 -d

# Real run, default jobs = CPU cores
./sampleprep.sh

# Force 2 parallel jobs
./sampleprep.sh -j 2
