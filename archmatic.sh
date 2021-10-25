#!/bin/bash
echo "Beginning setup..."
bash 0-preinstall.sh
echo "Running setup..."
arch-chroot /mnt /root/bootstrap/1-setup.sh
source /mnt/root/bootstrap/install.conf
arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/bootstrap/2-user.sh
arch-chroot /mnt /root/bootstrap/3-post-setup.sh

# copy configs
cp -R ./configs/* /mnt/home/$username/

umount -R /mnt
echo "Done."
