import os
import logging
import subprocess
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def download_file(url, output_path):
    import requests
    from tqdm import tqdm
    
    if os.path.exists(output_path):
        logger.info(f"File already exists: {output_path}")
        return

    logger.info(f"Downloading {url} to {output_path}...")
    response = requests.get(url, stream=True)
    total_size = int(response.headers.get('content-length', 0))
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    with open(output_path, 'wb') as f, tqdm(
        desc=os.path.basename(output_path),
        total=total_size,
        unit='iB',
        unit_scale=True,
        unit_divisor=1024,
    ) as bar:
        for data in response.iter_content(chunk_size=1024):
            size = f.write(data)
            bar.update(size)

def setup_liveportrait():
    base_dir = Path(__file__).parent.parent
    liveportrait_dir = base_dir / 'LivePortrait'
    weights_dir = liveportrait_dir / 'pretrained_weights'
    
    if not liveportrait_dir.exists():
        logger.info("Cloning LivePortrait repository...")
        subprocess.run(["git", "clone", "https://github.com/KwaiVGI/LivePortrait", str(liveportrait_dir)], check=True)
    
    # Define weights to download
    # Source: https://github.com/KwaiVGI/LivePortrait?tab=readme-ov-file#download-pretrained-weights
    weights = {
        "insightface/models/buffalo_l": [
            "https://github.com/deepinsight/insightface/releases/download/v0.7/buffalo_l.zip"
        ],
        "liveportrait": [
            "https://huggingface.co/KwaiVGI/LivePortrait/resolve/main/appearance_feature_extractor.pth",
            "https://huggingface.co/KwaiVGI/LivePortrait/resolve/main/motion_extractor.pth",
            "https://huggingface.co/KwaiVGI/LivePortrait/resolve/main/spade_generator.pth",
            "https://huggingface.co/KwaiVGI/LivePortrait/resolve/main/warping_module.pth",
        ],
        "liveportrait/landmark": [
             "https://huggingface.co/KwaiVGI/LivePortrait/resolve/main/landmark.onnx"
        ]
    }
    
    # Download LivePortrait weights
    for url in weights["liveportrait"]:
        filename = url.split('/')[-1]
        download_file(url, weights_dir / f"liveportrait/{filename}")

    # Download Landmark
    download_file(weights["liveportrait/landmark"][0], weights_dir / "landmark.onnx")

    logger.info("LivePortrait setup complete.")

if __name__ == "__main__":
    setup_liveportrait()
