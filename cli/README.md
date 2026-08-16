# AI Video Studio CLI

Local models + prompt workflow for Windows, macOS, and Linux.

```bash
cd cli
python -m venv .venv

# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# macOS / Linux
source .venv/bin/activate

pip install -r requirements.txt
python -m ai_video_studio list-models
python -m ai_video_studio download demo-t2v
python -m ai_video_studio generate "a cute cartoon rabbit in a garden" --model demo-t2v
python -m ai_video_studio paths
```

Data directory: `~/.ai-video-studio/`

Download happens **through this CLI** (or the mobile/web UI), not a separate required tool for end users.
