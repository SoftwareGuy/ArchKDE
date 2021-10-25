#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------
echo "--------------------------------------"
echo "Installing Network..."
echo "--------------------------------------"
pacman -S networkmanager modemmanager usbutils usb_modeswitch dhclient --noconfirm --needed
systemctl enable NetworkManager

echo "--------------------------------------"
echo "User configuration..."
echo "--------------------------------------"
echo "Enter password for root user: "
passwd root

if ! source /root/bootstrap/install.conf; then
	echo "WARNING: Could not source install.conf... What happened?"
	
	read -p "What is the hostname of this device? " hostname
	read -p "What is the username you wish to use? " username

  printf "hostname="$hostname"\n" >> "install.conf"
  printf "username="$username"\n" >> "install.conf"
  export hostname=$hostname
  export username=$username
fi

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
pacman -S --noconfirm pacman-contrib curl
pacman -S --noconfirm reflector rsync
iso="au" # brazil mirrolist
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

nc=$(grep -c ^processor /proc/cpuinfo)
echo "You have $nc processor cores."
echo "-------------------------------------------------"
echo "Changing the makeflags for $nc processor cores."
sudo sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$nc"/g' /etc/makepkg.conf
echo "Changing the compression settings for $nc cores."
sudo sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g' /etc/makepkg.conf

echo "-------------------------------------------------"
echo "Configuring the system..."
echo "-------------------------------------------------"
sed -i 's/^#en_AU.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo "Setting the timezone..."
timedatectl --no-ask-password set-timezone Australia/Brisbane
timedatectl --no-ask-password set-ntp 1

# this wont run
#localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_COLLATE="" LC_TIME="en_US.UTF-8"
# persistant configuration

echo "Setting language..."
echo "LANG=en_AU.UTF-8" >> /etc/vconsole.conf
echo "LANGUAGE=en_AU:en" >> /etc/vconsole.conf

# English is my native language, no latin please.
# echo "KEYMAP=la-latin1" >> /etc/vconsole.conf

echo "LC_TIME=en_AU.UTF-8" >> /etc/vconsole.conf
echo "LC_COLLATE=C" >> /etc/vconsole.conf

# Set keymaps
# localectl --no-ask-password set-keymap la-latin1

# Hostname
echo "Setting hostname..."

hostnamectl --no-ask-password set-hostname $hostname

# Setup sudo.
echo "Setting up sudo for administrative privileges..."

sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Add parallel downloading
echo "Tweaking package manager..."

sed -i 's/^#Para/Para/' /etc/pacman.conf

# Enable multilib
cat <<EOF >> /etc/pacman.conf
[multilib]
Include = /etc/pacman.d/mirrorlist

[liquorix]
Server = https://liquorix.net/archlinux/liquorix/x86_64
EOF

pacman-key --keyserver hkps://keyserver.ubuntu.com --recv-keys 9AE4078033F8024D
pacman-key --lsign-key 9AE4078033F8024D

pacman -Sy --noconfirm

# echo "NOTE: Liquorix kernel repository is commented out in /etc/pacman.conf."
# echo "Enable it manually if you want it (the package key should be imported by now)."

echo "-------------------------------------------------"
echo "Installing additional packages..."
echo "-------------------------------------------------"

PKGS=(
'alsa-plugins' # audio plugins
'alsa-utils' # audio utils
'ark' # compression
'audiocd-kio' 
'autoconf' # build
'automake' # build
'base'
'bash-completion'
'bashtop'
'bind'
'binutils'
'bison'
'bluedevil'
'bluez'
'bluez-libs'
'breeze'
'breeze-gtk'
'bridge-utils'
'btrfs-progs'
'baka-mplayer' # video players
'cmatrix'
'code' # Visual Studio code
'cronie'
'cups'
'dhcpcd'
'dialog'
'discover'
'dmidecode'
'dnsmasq'
'dolphin'
'dosfstools'
'drkonqi'
'earlyoom'
'edk2-ovmf'
'efibootmgr' # EFI boot
'exfat-utils'
'flex'
'fuse2'
'fuse3'
'fuseiso'
'gamemode'
'gcc'
'gimp' # Photo editing
'git'
'gparted' # partition management
'gptfdisk'
'gsmartcontrol'
'groff'
'grub'
'grub-customizer'
'gst-libav'
'gst-plugins-good'
'gst-plugins-ugly'
'haveged'
'hdparm'
'htop'
'iftop'
'iotop'
'iptables-nft'
'jdk-openjdk'
'kactivitymanagerd'
'kate'
'kvantum-qt5'
'kcalc'
'kcharselect'
'kcron'
'kde-cli-tools'
'kde-gtk-config'
'kdecoration'
'kdenetwork-filesharing'
'kdeplasma-addons'
'kdesdk-thumbnailers'
'kdialog'
'keychain'
'kfind'
'kgamma5'
'kgpg'
'khotkeys'
'kinfocenter'
'kitty'
'kmenuedit'
'kmix'
'konsole'
'kscreen'
'kscreenlocker'
'ksshaskpass'
'ksystemlog'
'ksystemstats'
'kwallet-pam'
'kwalletmanager'
'kwayland-integration'
'kwayland-server'
'kwin'
'kwrite'
'kwrited'
'layer-shell-qt'
'libguestfs'
'libkscreen'
'libksysguard'
'libnewt'
'libtool'
'libvirt'
'linux-lqx'
'linux-lqx-headers'
'lsof'
'lutris'
'lvm2'
'lzop'
'm4'
'make'
'mdadm'
'milou'
'nano'
'neofetch'
'networkmanager'
'noto-fonts'
'ntfs-3g'
'okular'
'openbsd-netcat'
'openssh'
'os-prober'
'oxygen'
'p7zip'
'pacman-contrib'
'patch'
'picom'
'pkgconf'
'plasma-browser-integration'
'plasma-desktop'
'plasma-disks'
'plasma-firewall'
'plasma-integration'
'plasma-nm'
'plasma-pa'
'plasma-sdk'
'plasma-systemmonitor'
'plasma-thunderbolt'
'plasma-vault'
'plasma-workspace'
'plasma-workspace-wallpapers'
'polkit-kde-agent'
'powerdevil'
'powerline-fonts'
'print-manager'
'pulseaudio'
'pulseaudio-alsa'
'pulseaudio-bluetooth'
'python-pip'
'qemu'
'rsync'
'sddm-kcm'
'spectacle'
'steam'
'sudo'
'swtpm'
'synergy'
'systemsettings'
'terminus-font'
'texinfo'
'traceroute'
'ufw'
'unrar'
'unzip'
'usbutils'
'vde2'
'vim'
'virt-manager'
'virt-viewer'
'wget'
'which'
'wine-staging'
'wine-gecko'
'wine-mono'
'winetricks'
'xdg-desktop-portal-kde'
'xdg-user-dirs'
'xorg-server'
'xorg-xinit'
'zeroconf-ioslave'
'zip'
'zsh'
'zsh-syntax-highlighting'
'zsh-autosuggestions'
)

echo "Safety sync..."
pacman -Sy 

echo "Start installing packages..."

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo pacman -S "$PKG" --noconfirm --needed
done

pacman -Sy --noconfirm intel-ucode amd-ucode

# Graphics Drivers find and install
mkdir /etc/pacman.d/hooks

if lspci | grep -E "NVIDIA|GeForce"; then
    sudo cat <<EOF > /etc/pacman.d/hooks/nvidia.hook
    [Trigger]
    Operation=Install
    Operation=Upgrade
    Operation=Remove
    Type=Package
    Target=nvidia

    [Action]
    Depends=mkinitcpio
    When=PostTransaction
    Exec=/usr/bin/mkinitcpio -P
EOF
    pacman -S nvidia-dkms dkms --noconfirm --needed
elif lspci | grep -E "Radeon"; then
    pacman -S xf86-video-amdgpu --noconfirm --needed
elif lspci | grep -E "Integrated Graphics Controller"; then
    pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
fi
echo -e "\nDone!\n"

# WTF??
if [ $(whoami) = "root" ];
then
    useradd -m -g users -G wheel -s /bin/bash $username 
    echo "--------------------------------------"
    echo "User Configuration"
	echo "--------------------------------------"
	cp -Rv /root/bootstrap /home/$username/
	
    echo "Setting password for $username: "
    passwd $username
	echo "Copying base data..."
    cp /etc/skel/.bash_profile /home/$username/
    cp /etc/skel/.bash_logout /home/$username/
    cp /etc/skel/.bashrc /home/$username/.bashrc
    chown -R $username: /home/$username
    sed -n '#/home/'"$username"'/#,s#bash#zsh#' /etc/passwd
else
	echo "You are already a user proceed with aur installs"
fi

