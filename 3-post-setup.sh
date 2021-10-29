#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------

echo "--------------------------------------"
echo "Putting the finishing touches on the new install..."
echo "--------------------------------------"

echo "--------------------------------------"
echo "Optional extra packages"
echo "--------------------------------------"

INSTALL_KERNEL=""
INSTALL_CHROMIUM=""
INSTALL_OBS=""

read -p "Would you like to install Liquorix kernel? (Y/N): " INSTALL_KERNEL
case $INSTALL_KERNEL in 
  y|Y|yes|Yes|YES)
	echo "OK, installing Liquorix kernel..."
	cat <<EOF >> /etc/pacman.conf
[liquorix]
Server = https://liquorix.net/archlinux/liquorix/x86_64
EOF
	pacman -Sy --noconfirm --needed linux-lqx linux-lqx-headers 
	;;
  *)
	echo "OK, won't install."
	;;
esac

read -p "Would you like to install Ungoogled Chromium? (Y/N): " INSTALL_CHROMIUM
case $INSTALL_CHROMIUM in 
  y|Y|yes|Yes|YES)
	echo "OK, installing ungoogled Chromium..."
	curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/x86_64/home_ungoogled_chromium_Arch.key' | sudo pacman-key -a -
	cat <<EOF >> /etc/pacman.conf
[home_ungoogled_chromium_Arch]
SigLevel = Required TrustAll
Server = https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/x86_64

EOF
	pacman -Sy --noconfirm --needed gnome-keyring ungoogled-chromium 
	;;
  *)
	echo "OK, won't install."
	;;
esac

read -p "Would you like to install OBS Studio? (Y/N): " INSTALL_OBS
case $INSTALL_OBS in 
  y|Y|yes|Yes|YES)
	echo "Enabling the chaotic AUR repository..."
	echo "- Getting keys..."
	pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	pacman-key --lsign-key 3056513887B78AEB
	pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
	cat <<EOF >> /etc/pacman.conf
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist

EOF
	echo "- Installing the package"
	pacman -Sy --noconfirm --needed obs-studio-git
	;;
	
	*)
	echo "OK, won't install."
	;;
esac

echo "Cleaning up yay again..."
yay -Yc --noconfirm

# ------------------------------------------------------------------------
echo "Configuring mkinitcpio..."
sed -i 's/^HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block mdadm_udev lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
# ------------------------------------------------------------------------

# ------------------------------------------------------------------------

echo "Configuring console fonts..."
sudo cat <<EOF >> /etc/vconsole.conf
FONT=ter-v16b
EOF
echo "Increasing file watcher count..."
# This prevents a "too many files" error in Visual Studio Code
echo fs.inotify.max_user_watches=524288 | tee /etc/sysctl.d/40-max-user-watches.conf

# ------------------------------------------------------------------------

echo "Disabling Pulse .esd_auth module..."
# Pulse audio loads the `esound-protocol` module, which best I can tell is rarely needed.
# That module creates a file called `.esd_auth` in the home directory which I'd prefer to not be there. So...
sed -i 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa

# ------------------------------------------------------------------------

echo "Enabling SSDM..."
systemctl enable sddm.service
cat <<EOF >> /etc/sddm.conf.d/theme.conf
[Theme]
Current=redrock
CursorTheme='We10XOS Cursors'
EOF


# ------------------------------------------------------------------------

echo "Enabling bluetooth daemon and setting it to auto-start..."
sed -i 's|#AutoEnable=false|AutoEnable=true|g' /etc/bluetooth/main.conf
systemctl enable bluetooth.service

# ------------------------------------------------------------------------

echo "Enabling the cups service daemon so we can print..."
systemctl enable cups.service

echo "Setting up game mode..."
systemctl --user enable gamemoded
systemctl enable auto-cpufreq
# No need to do this in a chroot.
# systemctl --user start gamemoded

echo "Setting up sysctl tweaks..."
cat <<EOF >> /etc/sysctl.d/10-networking.conf
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.core.rmem_default = 1048576
net.core.rmem_max = 16777216
net.core.wmem_default = 1048576
net.core.wmem_max = 16777216
net.core.optmem_max = 65536
net.ipv4.tcp_rmem = 4096 1048576 2097152
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 2000000
EOF
echo "vm.swappiness = 10" >> /etc/sysctl.d/10-swappiness.conf

echo "--------------------------------------"
echo "Fixing up administration privileges..."
echo "--------------------------------------"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

echo "--------------------------------------"
echo "Finalizing GRUB once again..."
echo "--------------------------------------"
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg

echo "--------------------------------------"
echo "Cleaning up"
echo "--------------------------------------"
rm -rvf /root/bootstrap
rm -rvf /home/*/bootstrap
rm -rvf /tmp/*

echo "--------------------------------------"
echo "Done polishing the install."
echo "--------------------------------------"
exit 0