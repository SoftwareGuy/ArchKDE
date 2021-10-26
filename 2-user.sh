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

echo "Installing Yay..."
cd $HOME
if [ ! -d "Staging" ]; then 
	mkdir Staging
fi

cd "$HOME/Staging"

echo "- Cloning"
git clone "https://aur.archlinux.org/yay.git"
cd "$HOME/Staging/yay"
echo "- Installing"
makepkg -si --noconfirm

if [ $? -eq 0 ]; then
	PKGS=(
	'ananicy-git'
	'auto-cpufreq'
	# Fonts
	'nerd-fonts-fira-code'
	'noto-fonts-emoji'
	'ttf-droid'
	'ttf-hack'
	'ttf-meslo'
	'ttf-roboto'
	'ttf-dejavu'
	'ttf-liberation'
	# Themes
	'papirus-icon-theme'
	'windows10-icon-theme-git'
	'We10XOS-cursors'
	# Gaming
	'dxvk-bin' # DXVK DirectX to Vulcan
	'goverlay'
	'mangohud' # Gaming FPS Counter
	'mangohud-common'
	'vkbasalt'
	# Tools
	'timeshift-bin'
	'ocs-url' # install packages from websites
	'the_silver_searcher' # fzf dependency
	)
	echo "- Done."
	echo "Installing AUR Packages..."
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

	export PATH=$PATH:$HOME/.local/bin
	# Todo: Clean this.
	# cp -r $HOME/bootstrap/dotfiles/* $HOME/.config/
	# pip install konsave
	# konsave -i $HOME/bootstrap/kde.knsv
	# sleep 1
	# konsave -a kde

	echo "Installing Ungoogled Chromium..."
	curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/x86_64/home_ungoogled_chromium_Arch.key' | sudo pacman-key -a -
	cat <<EOF >> /etc/pacman.conf
	[home_ungoogled_chromium_Arch]
	SigLevel = Required TrustAll
	Server = https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/$arch
EOF
	sudo pacman -Sy --noconfirm --needed ungoogled-chromium
else
	echo "Sorry, looks like AUR user package installation failed with error code $?"
fi

echo "--------------------------------------"
echo "Done Installing AUR Packages."
echo "--------------------------------------"
exit 0