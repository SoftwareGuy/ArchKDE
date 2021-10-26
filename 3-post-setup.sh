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

# ------------------------------------------------------------------------

echo "Setting up X11..."
# Generate the .xinitrc file so we can launch Awesome from the
# terminal using the "startx" command
cat <<EOF > ${HOME}/.xinitrc
#!/bin/bash
# Disable bell
xset -b

# Disable all Power Saving Stuff
xset -dpms
xset s off

# X Root window color
xsetroot -solid darkgrey

# Merge resources (optional)
#xrdb -merge $HOME/.Xresources

# Caps to Ctrl, no caps
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "\$f" ] && . "\$f"
    done
    unset f
fi

exit 0
EOF


# ------------------------------------------------------------------------

echo "Configuring console fonts..."
sudo cat <<EOF >> /etc/vconsole.conf
FONT=ter-v16b
EOF

# ------------------------------------------------------------------------

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

# ------------------------------------------------------------------------

echo "Enabling bluetooth daemon and setting it to auto-start..."
sed -i 's|#AutoEnable=false|AutoEnable=true|g' /etc/bluetooth/main.conf
systemctl enable bluetooth.service

# ------------------------------------------------------------------------

echo "Enabling the cups service daemon so we can print..."
systemctl enable cups.service

# Moved to pre-install phase
# sudo systemctl enable ntpd.service
# sudo systemctl disable dhcpcd.service
# sudo systemctl stop dhcpcd.service
# NetworkManager already configured in pre-install phase
# sudo systemctl enable NetworkManager.service

echo "Setting up game mode..."
systemctl --user enable gamemoded
systemctl enable auto-cpufreq
# No need to do this in a chroot.
# systemctl --user start gamemoded

echo "Setting up sysctl tweaks..."
cat <<EOF >> /etc/sysctl.d/10-networking.conf
sysctl -w net.core.netdev_max_backlog = 16384
sysctl -w net.core.somaxconn = 8192
sysctl -w net.core.rmem_default = 1048576
sysctl -w net.core.rmem_max = 16777216
sysctl -w net.core.wmem_default = 1048576
sysctl -w net.core.wmem_max = 16777216
sysctl -w net.core.optmem_max = 65536
sysctl -w net.ipv4.tcp_rmem = 4096 1048576 2097152
sysctl -w net.ipv4.tcp_wmem = 4096 65536 16777216
sysctl -w net.ipv4.udp_rmem_min = 8192
sysctl -w net.ipv4.udp_wmem_min = 8192
sysctl -w net.ipv4.tcp_fastopen = 3
sysctl -w net.ipv4.tcp_max_syn_backlog = 8192
sysctl -w net.ipv4.tcp_max_tw_buckets = 2000000
sysctl -w vm.swappiness = 10
EOF

echo "--------------------------------------"
echo "Fixing up administration privileges..."
echo "--------------------------------------"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Replace in the same state
cd $pwd

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

echo "--------------------------------------"
echo "Done polishing the install."
echo "--------------------------------------"
exit 0