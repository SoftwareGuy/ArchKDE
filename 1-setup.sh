#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------
echo "--------------------------------------"
echo "Running step 2 of GRUB install..."
echo "--------------------------------------"
grub-install --target=x86_64-efi --efi-directory=/efi

echo "--------------------------------------"
echo "Installing Network..."
echo "--------------------------------------"
pacman --noconfirm --needed -S networkmanager modemmanager usbutils usb_modeswitch dhclient 
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
iso="au"
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
ln -sf /usr/share/zoneinfo/Australia/Brisbane /etc/localtime
timedatectl --no-ask-password set-timezone Australia/Brisbane
timedatectl --no-ask-password set-ntp 1
hwclock --systohc

echo "Setting language..."
echo "LANG=en_AU.UTF-8" >> /etc/vconsole.conf
echo "LANGUAGE=en_AU:en" >> /etc/vconsole.conf

echo "LC_TIME=en_AU.UTF-8" >> /etc/vconsole.conf
echo "LC_COLLATE=C" >> /etc/vconsole.conf

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
# Xorg Essentials
'xorg-server'
'xorg-xinit'
# KDE Essentials
'plasma-meta'
'kde-applications-meta'
'discover'
'powerdevil'
'xdg-user-dirs'
'xdg-desktop-portal'
'xdg-desktop-portal-kde'
'packagekit-qt5'
# KDE Compatiblity
'gnome-settings-daemon'
'gsettings-desktop-schemas'
'gsettings-qt'
# KDE apparently already pulls this stuff in.
# 'drkonqi'
# 'breeze'
# 'breeze-gtk'
# Audio
'alsa-plugins'
'alsa-utils'
'audiocd-kio'
'pulseaudio'
'pulseaudio-alsa'
'pulseaudio-bluetooth'
# Compression
'ark'
'rar'
'zip'
'unrar'
'unzip'
'p7zip'
# Build Essentials
'autoconf'
'automake'
# Bash Tools
'bash-completion'
'neofetch'
'openbsd-netcat'
# BlueTooth
'bluedevil'
'bluez'
'bluez-libs'
# Development
'code'
'jdk-openjdk'
'libtool'
'python-pip'
'nodejs'
'npm'
# Video stuff
'baka-mplayer'
'gst-libav'
'gst-plugins-good'
'gst-plugins-ugly'
# Printing
'cups'
'print-manager'
'system-config-printer';
# QEMU Emulation
'fuseiso'
'edk2-ovmf'
'libvirt'
'qemu'
'swtpm'
'virt-manager'
'virt-viewer'
# Gaming
'gamemode'
'lutris'
'steam'
# WINE
'wine-staging'
'wine-gecko'
'wine-mono'
'winetricks'
# Photo Editing
'gimp'
# Disks
'gparted'
'gsmartcontrol'
# Fonts
'noto-fonts'
'powerline-fonts'
'terminus-font'
# System
'intel-ucode'
'amd-ucode'
'grub-customizer'
'pacman-contrib'
'patch'
'picom'
'zsh'
'zsh-syntax-highlighting'
'zsh-autosuggestions'
'zeroconf-ioslave'
'lib32-systemd'
'wqy-zenhei'
# Liquorix Kernel
'linux-lqx'
'linux-lqx-headers'
)

echo "Asking pacman to synchronize before installing..."
pacman -Sy 
echo "Done."

echo "Batch installing desired packages..."

for PKG in "${PKGS[@]}"; do
    echo "- Installing package: ${PKG}"
    sudo pacman --noconfirm --needed -S "$PKG" 
done
echo "Done."

echo "Detecting graphics card and installing drivers..."

# Graphics Drivers find and install
if [ ! -d "/etc/pacman.d/hooks" ]; then
	mkdir -p /etc/pacman.d/hooks
fi

if lspci | grep -E "NVIDIA|GeForce"; then
	echo "- Detected an nVidia/GeForce GPU!"	
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
    pacman --noconfirm --needed -S nvidia-dkms
elif lspci | grep -E "Radeon"; then
	echo " - Detected AMD Radeon GPU!"
    pacman --needed --noconfirm -S xf86-video-amdgpu
elif lspci | grep -E "Integrated Graphics Controller"; then
	echo "- Detected Integrated (Intel?) Graphics Processor!"
    pacman --needed --noconfirm -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils 
fi
echo "GPU detection complete."

echo "Configuring services."
systemctl enable libvirtd
echo "GTK_USE_PORTAL=1" >> /etc/environment

echo "GRUB configuration."
grub-mkconfig -o /boot/grub/grub.cfg

# WTF??
if [ $(whoami) = "root" ];
then
    useradd -m -g users -G wheel -s /bin/bash $username 
    echo "--------------------------------------"
    echo "User Configuration"
	echo "--------------------------------------"
	# cp -Rv /root/bootstrap /home/$username/
	
    echo "Setting password for $username: "
    passwd $username
	
	echo "Copying base data..."
    cp /etc/skel/.bash_profile /home/$username/
    cp /etc/skel/.bash_logout /home/$username/
    cp /etc/skel/.bashrc /home/$username/.bashrc
    chown -R $username: /home/$username
	
	echo "Copying user portion of the setup phase..."
	mkdir -p /home/$username/bootstrap
	cp -rv /root/bootstrap/2-user.sh /home/$username/bootstrap/2-user.sh
	
    sed -n '#/home/'"$username"'/#,s#bash#zsh#' /etc/passwd
else
	echo "You are already a user proceed with aur installs"
fi

