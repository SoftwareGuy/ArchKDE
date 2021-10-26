#!/bin/bash
echo "Preinstallation phase begins..."
bash 0-preinstall.sh
if [ $? -ne 0 ]; then
	echo "Error code $? encountered. Shit's fucked, aborting."
	exit
fi

echo "Setup phase begins..."
arch-chroot /mnt /root/bootstrap/1-setup.sh
if [ $? -ne 0 ]; then
	echo "Error code $? encountered. Shit's fucked, aborting."
	exit
fi

source /mnt/root/bootstrap/install.conf
if [ $? -ne 0 ]; then
	echo "Error code $? encountered. Shit's fucked, aborting."
	exit
fi

echo "User setup phase begins..."
arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/bootstrap/2-user.sh
if [ $? -ne 0 ]; then
	echo "Error code $? encountered. Shit's fucked, aborting."
	exit
fi

echo "Post setup phase begins..."
arch-chroot /mnt /root/bootstrap/3-post-setup.sh
if [ $? -ne 0 ]; then
	echo "Error code $? encountered. Shit's fucked, aborting."
	exit
fi

# copy configs
# cp -R ./configs/* /mnt/home/$username/

umount -R /mnt
echo "Installation complete unless errors occurred."
exit 0
