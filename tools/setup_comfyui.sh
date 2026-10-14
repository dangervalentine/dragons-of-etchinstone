#!/bin/sh
# Sets up ComfyUI with FLUX the way tools/generate_art.py expects, on macOS (Apple
# Silicon) or Linux (NVIDIA). It needs git, curl and uv (https://docs.astral.sh/uv/).
# On Windows, use setup_comfyui.ps1, which does the same.
#
#   sh setup_comfyui.sh [dir] [--q8] [--serve]
#
# dir     where to install; ~/ComfyUI by default
# --q8    also fetch the 12.7 GB Q8 models, sharper but needing about 32 GB of
#         memory; the Q4 models (about 7 GB) are always fetched and are the default
# --serve start ComfyUI on the network afterwards, so another computer can send it
#         work: python3 tools/generate_art.py --server http://<this-host>:8188 ...
#
# The script only needs this one file; it doesn't need the game's repo. It's safe to
# run again: finished steps are skipped.
set -e

# The versions this project was set up and tested with.
COMFY_COMMIT=e0a32bce84f4603f2b61b16b50f8958e68fd6171
GGUF_COMMIT=6ea2651e7df66d7585f6ffee804b20e92fb38b8a

DIR="$HOME/ComfyUI"
Q8=0
SERVE=0
for arg in "$@"; do
	case "$arg" in
	--q8) Q8=1 ;;
	--serve) SERVE=1 ;;
	-*) echo "unknown option $arg"; exit 1 ;;
	*) DIR="$arg" ;;
	esac
done

for tool in git curl uv; do
	command -v $tool >/dev/null || { echo "needs $tool"; exit 1; }
done

echo "== ComfyUI in $DIR"
[ -d "$DIR/.git" ] || git clone -q https://github.com/comfyanonymous/ComfyUI.git "$DIR"
git -C "$DIR" fetch -q origin && git -C "$DIR" checkout -q $COMFY_COMMIT
NODE="$DIR/custom_nodes/ComfyUI-GGUF"
[ -d "$NODE/.git" ] || git clone -q https://github.com/city96/ComfyUI-GGUF.git "$NODE"
git -C "$NODE" fetch -q origin && git -C "$NODE" checkout -q $GGUF_COMMIT

echo "== Python environment"
cd "$DIR"
[ -d .venv ] || uv venv -q --python 3.12 .venv
TORCH_INDEX=""
if [ "$(uname)" = "Linux" ] && command -v nvidia-smi >/dev/null; then
	# The CUDA build of PyTorch; Mac and CPU builds come from the default index.
	TORCH_INDEX="--extra-index-url https://download.pytorch.org/whl/cu128"
fi
VIRTUAL_ENV=.venv uv pip install -q $TORCH_INDEX torch torchvision torchaudio \
	-r requirements.txt -r "$NODE/requirements.txt" "huggingface_hub[cli]" \
	resvg-py potracer

echo "== Models (about 17 GB, more with --q8)"
fetch() { # repo, file in repo, folder under models/, name to save as
	[ -f "models/$3/$4" ] && return
	.venv/bin/hf download "$1" "$2" --local-dir "models/.dl" >/dev/null 2>&1
	mv "models/.dl/$2" "models/$3/$4"
	echo "   $3/$4"
}
mkdir -p models/unet models/text_encoders models/vae
fetch Comfy-Org/Lumina_Image_2.0_Repackaged split_files/vae/ae.safetensors vae ae.safetensors
fetch comfyanonymous/flux_text_encoders clip_l.safetensors text_encoders clip_l.safetensors
fetch city96/t5-v1_1-xxl-encoder-gguf t5-v1_1-xxl-encoder-Q5_K_M.gguf text_encoders t5-v1_1-xxl-encoder-Q5_K_M.gguf
fetch city96/FLUX.1-dev-gguf flux1-dev-Q4_K_S.gguf unet flux1-dev-Q4_K_S.gguf
fetch YarvixPA/FLUX.1-Fill-dev-GGUF flux1-fill-dev-Q4_K_S.gguf unet flux1-fill-dev-Q4_K_S.gguf
if [ $Q8 = 1 ]; then
	fetch city96/t5-v1_1-xxl-encoder-gguf t5-v1_1-xxl-encoder-Q8_0.gguf text_encoders t5-v1_1-xxl-encoder-Q8_0.gguf
	fetch city96/FLUX.1-dev-gguf flux1-dev-Q8_0.gguf unet flux1-dev-Q8_0.gguf
	fetch YarvixPA/FLUX.1-Fill-dev-GGUF flux1-fill-dev-Q8_0.gguf unet flux1-fill-dev-Q8_0.gguf
fi
rm -rf models/.dl

echo "== Done"
if [ $SERVE = 1 ]; then
	echo "Starting ComfyUI on port 8188 for the network. Ctrl-C stops it."
	exec .venv/bin/python main.py --listen 0.0.0.0 --port 8188
fi
echo "Start it with: cd $DIR && .venv/bin/python main.py"
echo "For another computer to send it work, add: --listen 0.0.0.0"
