#!/bin/bash
echo "BEGIN: Preinstall phase"
bash 0-preinstall.sh
LAST_ERRORCODE=$?
if [ $LAST_ERRORCODE -ne 0 ]; then
	echo "Error code $LAST_ERRORCODE encountered. Shit's fucked, aborting."
	umount -R /mnt
	exit
fi

echo "BEGIN: Install phase"
arch-chroot /mnt /root/bootstrap/1-setup.sh
LAST_ERRORCODE=$?
if [ $LAST_ERRORCODE -ne 0 ]; then
	echo "Error code $LAST_ERRORCODE encountered. Shit's fucked, aborting."
	umount -R /mnt
	exit
fi

echo "BEGIN: User/AUR package installation phase"
source /mnt/root/bootstrap/install.conf
LAST_ERRORCODE=$?
if [ $LAST_ERRORCODE -ne 0 ]; then
	echo "Error code $? encountered. Shit's fucked, aborting."
	umount -R /mnt
	exit
fi

arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/bootstrap/2-user.sh
LAST_ERRORCODE=$?
if [ $LAST_ERRORCODE -ne 0 ]; then
	echo "Error code $LAST_ERRORCODE encountered. Shit's fucked, aborting."
	umount -R /mnt
	exit
fi

echo "BEGIN: Post setup phase"
arch-chroot /mnt /root/bootstrap/3-post-setup.sh
LAST_ERRORCODE=$?
if [ $LAST_ERRORCODE -ne 0 ]; then
	echo "Error code $LAST_ERRORCODE encountered. Shit's fucked, aborting."
	umount -R /mnt
	exit
fi

echo "BEGIN: Clean up and unmount"
swapoff -a
umount -R /mnt
LAST_ERRORCODE=$?
if [ $LAST_ERRORCODE -ne 0 ]; then
	echo "WARNING: Couldn't unmount the target, please check and unmount manually."
	umount -R /mnt
	exit
fi

echo "Installation complete unless errors occurred."
exit 0
