# Sets up ComfyUI with FLUX the way tools/generate_art.py expects, on Windows with an
# NVIDIA GPU. The Windows twin of setup_comfyui.sh: the same versions, models and
# folders. It needs git and uv:
#   winget install Git.Git astral-sh.uv
#
#   powershell -ExecutionPolicy Bypass -File setup_comfyui.ps1 [-Dir C:\ComfyUI] [-Q8] [-Serve]
#
# -Dir    where to install; $HOME\ComfyUI by default
# -Q8     also fetch the 12.7 GB Q8 models, sharper and the better choice on a GPU with
#         16 GB or more; the Q4 models (about 7 GB) are always fetched
# -Serve  start ComfyUI on the network afterwards, so another computer can send it
#         work: python3 tools/generate_art.py --server http://<this-pc>:8188 [--q8] ...
#
# The script only needs this one file; it doesn't need the game's repo. It's safe to
# run again: finished steps are skipped. ComfyUI's Python also gets what the repo's
# art tools need, so with the repo on this PC they run here too:
#   $HOME\ComfyUI\.venv\Scripts\python.exe tools\generate_art.py restyle tortoise --q8
param(
	[string]$Dir = (Join-Path $HOME "ComfyUI"),
	[switch]$Q8,
	[switch]$Serve
)
$ErrorActionPreference = "Stop"

# The versions this project was set up and tested with.
$ComfyCommit = "e0a32bce84f4603f2b61b16b50f8958e68fd6171"
$GgufCommit = "6ea2651e7df66d7585f6ffee804b20e92fb38b8a"

# Native commands don't stop the script on failure by themselves.
function Run {
	& $args[0] $args[1..($args.Count - 1)]
	if ($LASTEXITCODE -ne 0) { throw "failed: $($args -join ' ')" }
}

foreach ($tool in "git", "uv") {
	if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
		throw "needs $tool; install it with: winget install Git.Git astral-sh.uv, then open a new terminal"
	}
}
if (-not (Get-Command nvidia-smi -ErrorAction SilentlyContinue)) {
	Write-Warning "no nvidia-smi found; ComfyUI will be very slow without an NVIDIA GPU and driver"
}

Write-Host "== ComfyUI in $Dir"
if (-not (Test-Path (Join-Path $Dir ".git"))) {
	Run git clone -q https://github.com/comfyanonymous/ComfyUI.git $Dir
}
Run git -C $Dir fetch -q origin
Run git -C $Dir checkout -q $ComfyCommit
$Node = Join-Path $Dir "custom_nodes\ComfyUI-GGUF"
if (-not (Test-Path (Join-Path $Node ".git"))) {
	Run git clone -q https://github.com/city96/ComfyUI-GGUF.git $Node
}
Run git -C $Node fetch -q origin
Run git -C $Node checkout -q $GgufCommit

Write-Host "== Python environment"
Set-Location $Dir
if (-not (Test-Path ".venv")) { Run uv venv -q --python 3.12 .venv }
$env:VIRTUAL_ENV = Join-Path $Dir ".venv"
# The CUDA build of PyTorch; uv prefers the extra index over PyPI's CPU build.
Run uv pip install -q --extra-index-url https://download.pytorch.org/whl/cu128 `
	torch torchvision torchaudio -r requirements.txt -r (Join-Path $Node "requirements.txt") `
	"huggingface_hub[cli]" resvg-py potracer
$Python = Join-Path $Dir ".venv\Scripts\python.exe"
$Hf = Join-Path $Dir ".venv\Scripts\hf.exe"
Run $Python -c "import torch; assert torch.cuda.is_available(), 'PyTorch cannot see the GPU'; print('GPU:', torch.cuda.get_device_name(0))"

Write-Host "== Models (about 17 GB, more with -Q8)"
# Forward slashes: Windows takes them, and hf.exe is given the same paths.
function Fetch($repo, $file, $folder, $name) {
	$dest = "models/$folder/$name"
	if (Test-Path $dest) { return }
	Run $Hf download $repo $file --local-dir "models/.dl" | Out-Null
	Move-Item "models/.dl/$file" $dest
	Write-Host "   $folder/$name"
}
foreach ($f in "unet", "text_encoders", "vae") { New-Item -ItemType Directory -Force "models/$f" | Out-Null }
Fetch Comfy-Org/Lumina_Image_2.0_Repackaged split_files/vae/ae.safetensors vae ae.safetensors
Fetch comfyanonymous/flux_text_encoders clip_l.safetensors text_encoders clip_l.safetensors
Fetch city96/t5-v1_1-xxl-encoder-gguf t5-v1_1-xxl-encoder-Q5_K_M.gguf text_encoders t5-v1_1-xxl-encoder-Q5_K_M.gguf
Fetch city96/FLUX.1-dev-gguf flux1-dev-Q4_K_S.gguf unet flux1-dev-Q4_K_S.gguf
Fetch YarvixPA/FLUX.1-Fill-dev-GGUF flux1-fill-dev-Q4_K_S.gguf unet flux1-fill-dev-Q4_K_S.gguf
if ($Q8) {
	Fetch city96/t5-v1_1-xxl-encoder-gguf t5-v1_1-xxl-encoder-Q8_0.gguf text_encoders t5-v1_1-xxl-encoder-Q8_0.gguf
	Fetch city96/FLUX.1-dev-gguf flux1-dev-Q8_0.gguf unet flux1-dev-Q8_0.gguf
	Fetch YarvixPA/FLUX.1-Fill-dev-GGUF flux1-fill-dev-Q8_0.gguf unet flux1-fill-dev-Q8_0.gguf
}
# FLUX Redux, for generate_art.py --style and tools\paint_art.py. Its repo is gated:
# accept the licence at https://huggingface.co/black-forest-labs/FLUX.1-Redux-dev and
# log in with .venv\Scripts\hf.exe auth login, then run this again.
foreach ($f in "style_models", "clip_vision") { New-Item -ItemType Directory -Force "models/$f" | Out-Null }
Fetch Comfy-Org/sigclip_vision_384 sigclip_vision_patch14_384.safetensors clip_vision sigclip_vision_patch14_384.safetensors
try {
	Fetch black-forest-labs/FLUX.1-Redux-dev flux1-redux-dev.safetensors style_models flux1-redux-dev.safetensors
} catch {
	Write-Warning "skipped style_models/flux1-redux-dev.safetensors: accept its licence and log in to Hugging Face first"
}
Remove-Item -Recurse -Force "models/.dl" -ErrorAction SilentlyContinue

Write-Host "== Done"
if ($Serve) {
	Write-Host "Starting ComfyUI on port 8188 for the network. Ctrl-C stops it."
	Write-Host "If Windows Firewall asks, allow it on private networks only."
	Write-Host "This PC's name for --server: http://$($env:COMPUTERNAME):8188"
	Run $Python main.py --listen 0.0.0.0 --port 8188
} else {
	Write-Host "Start it with: cd $Dir; .venv\Scripts\python.exe main.py"
	Write-Host "For another computer to send it work, add: --listen 0.0.0.0"
}
