#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------

echo "--------------------------------------"
echo "Installing AUR Packages with Yay..."
echo "--------------------------------------"

cd $HOME
if [ ! -d "Staging" ]; then 
	mkdir Staging
fi

cd "$HOME/Staging"

echo "- Cloning yay..."
git clone "https://aur.archlinux.org/yay.git"
cd "$HOME/Staging/yay"
echo "- Making package and installing yay..."
makepkg -sic --noconfirm

if [ $? -eq 0 ]; then
	echo "- Done making package to install yay."
	
	PKGS=(
	# Kernel tweaking
	'ananicy-git'
	'auto-cpufreq'
	# Instant Messaging
	'betterdiscord-installer'
	# Development
	'visual-studio-code-bin'
	'dotnet-host-bin'
	'dotnet-runtime-bin'
	'dotnet-sdk-bin'
	# Fonts
	'nerd-fonts-fira-code'
	'noto-fonts-emoji'
	'ttf-droid'
	'ttf-hack'
	'ttf-meslo'
	'ttf-roboto'
	'ttf-dejavu'
	'ttf-liberation'
	'ttf-ms-fonts' # used for some windows application stuffs
	# Themes
	'papirus-icon-theme'
	'xcursor-we10xos'
	'sddm-theme-redrock'	
	# Gaming
	'dxvk-bin' # DXVK DirectX to Vulcan
	'goverlay'
	'mangohud' # Gaming FPS Counter
	'mangohud-common'
	'vkbasalt'
	# Tools
	'timeshift-bin'
	'barrier-bin'
	'ocs-url' # install packages from websites
	'the_silver_searcher' # fzf dependency
	)

	echo "- Installing AUR packages with yay..."
	for PKG in "${PKGS[@]}"; do
		yay -S --noconfirm $PKG
	done
	
	# The following was moved from post-setup since makepkg complains about root being super damaging or something idk	
	INSTALL_UNITY_HUB=""
	read -p "Would you like to install Unity Hub? (Y/N): " INSTALL_UNITY_HUB
case $INSTALL_UNITY_HUB in 
  y|Y|yes|Yes|YES)
	echo "OK, installing Unity Hub..."
	yay -S --noconfirm unityhub
	
	echo "Installing extra dependencies for Unity..."
	pacman -Sy --needed --noconfirm desktop-file-utils gcc-libs glu gtk3 intel-tbb lib32-gcc-libs libgl libpng12 libpqxx libxtst npm nss xdg-utils jq
#	Conflicts or something with an non-aur arch package?
#	yay -S --noconfirm gconf-gtk2
	;;
	
  *)
	echo "OK, won't install."
	;;
esac
	
	echo "- Yay cleanup..."
	yay -Yc --noconfirm
	
echo "--------------------------------------"
echo "User configurations"
echo "--------------------------------------"
	
echo "Writing configuration for mpv..."
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

else
	echo "Sorry, looks like AUR user package installation failed with error code $?"
fi

echo "--------------------------------------"
echo "Done Installing AUR Packages."
echo "--------------------------------------"
exit 0