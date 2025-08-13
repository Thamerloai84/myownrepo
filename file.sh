#!/bin/bash
# LineageOS build environment setup for Arch Linux
# Works on Arch or Arch-based distros

set -e

echo "==> Updating system and installing base packages..."
sudo pacman -Syu --needed --noconfirm \
    base-devel git git-lfs ccache bc bison flex gperf imagemagick \
    lib32-readline lib32-zlib libelf lz4 sdl2 \
    python python2 zlib pngcrush rsync \
    squashfs-tools libxslt zip ncurses jdk11-openjdk wget curl

echo "==> Setting up ~/bin and ccache environment..."
mkdir -p ~/bin
grep -qxF 'export PATH="$HOME/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
grep -qxF 'export USE_CCACHE=1' ~/.bashrc || echo 'export USE_CCACHE=1' >> ~/.bashrc
grep -qxF 'export CCACHE_EXEC=$(which ccache)' ~/.bashrc || echo 'export CCACHE_EXEC=$(which ccache)' >> ~/.bashrc

ccache --max-size=50G || echo "==> Warning: ccache not found or failed to set size"

source ~/.bashrc

echo "==> Setting up Python 2 virtual environment (for LOS 11–16 if needed)..."
if ! command -v virtualenv &> /dev/null; then
    python2 -m pip install --user virtualenv
fi
python2 -m virtualenv -p python2 ~/.lineage_venv
echo "==> Activate Python 2 virtualenv with: source ~/.lineage_venv/bin/activate"

echo "==> Installing repo tool..."
curl -o ~/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
chmod a+x ~/bin/repo

echo "==> Configuring git and git-lfs..."
git config --global user.email "you@example.com"
git config --global user.name  "LineageOS Dev"
git lfs install
git config --global trailer.changeid.key "Change-Id"

echo "==> Done! Your Arch Linux environment is ready for LineageOS builds."
echo "Next steps:"
echo "1. mkdir -p ~/android/lineage/.repo/local_manifests"
echo "2. cd ~/android/lineage"
echo "3. repo init -u https://github.com/LineageOS/android.git -b lineage-<version> --git-lfs"
echo "4. repo sync -c --optimized-fetch --no-clone-bundle -j$(nproc)"
echo "5. Add your device/kernel/vendor manifests in .repo/local_manifests/"
echo "6. Build with: source build/envsetup.sh && lunch lineage_<devicecodename>-userdebug && mka bacon"
