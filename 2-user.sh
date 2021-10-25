#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------

echo "--------------------------------------"
echo "Installing AUR Packages..."
echo "--------------------------------------"
# You can solve users running this script as root with this and then doing the same for the next for statement. However I will leave this up to you.

echo "CLONING: YAY"
cd ~
git clone "https://aur.archlinux.org/yay.git"
cd ${HOME}/yay
makepkg -si --noconfirm
cd ~
touch "$HOME/.cache/zshhistory"
git clone "https://github.com/ChrisTitusTech/zsh"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/powerlevel10k
ln -s "$HOME/zsh/.zshrc" $HOME/.zshrc

PKGS=(
'ananicy-git'
# 'autojump'
# 'awesome-terminal-fonts'
# 'brave-bin' # Brave Browser
'dxvk-bin' # DXVK DirectX to Vulcan
'github-desktop-bin' # Github Desktop sync
'goverlay'
'lightly-git'
# 'lightlyshaders-git' # Not found?
'mangohud' # Gaming FPS Counter
'mangohud-common'
'nerd-fonts-fira-code'
'nordic-darker-standard-buttons-theme'
'nordic-darker-theme'
'nordic-kde-git'
'nordic-theme'
'noto-fonts-emoji'
'papirus-icon-theme'
'sddm-nordic-theme-git'
'ocs-url' # install packages from websites
'timeshift-bin'
'ttf-droid'
'ttf-hack'
'ttf-meslo' # Nerdfont package
'ttf-roboto'
'ttf-liberation'
# 'zoom' # video conferences
'nodejs' # node
'npm' # npm
'the_silver_searcher' # fzf dependency
'octave'
'vkbasalt'
'auto-cpufreq'
'steamcmd'
)

for PKG in "${PKGS[@]}"; do
    yay -S --noconfirm $PKG
done

mkdir -p /home/$(whoami)/.config/mpv
cat <<EOF >> /home/$(whoami)/.config/mpv/mpv.conf
vo=vdpau
profile=opengl-hq
hwdec=vdpau
hwdec-codecs=all
scale=ewa_lanczossharp
cscale=ewa_lanczossharp
interpolation
tscale=oversample
EOF

export PATH=$PATH:~/.local/bin
cp -r $HOME/bootstrap/dotfiles/* $HOME/.config/
pip install konsave
konsave -i $HOME/bootstrap/kde.knsv
sleep 1
konsave -a kde

echo "Installing Ungoogled Chromium..."
curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/x86_64/home_ungoogled_chromium_Arch.key' | sudo pacman-key -a -
echo '
[home_ungoogled_chromium_Arch]
SigLevel = Required TrustAll
Server = https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/$arch' | sudo tee --append /etc/pacman.conf
sudo pacman -Sy
sudo pacman -Sy ungoogled-chromium

echo "--------------------------------------"
echo "Done Installing AUR Packages."
echo "--------------------------------------"
exit