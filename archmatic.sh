#!/bin/bash

    bash 0-preinstall.sh
    arch-chroot /mnt /root/ArchKDE/1-setup.sh
    source /mnt/root/ArchKDE/install.conf
	arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/ArchKDE/2-user.sh
    arch-chroot /mnt /root/ArchKDE/3-post-setup.sh
