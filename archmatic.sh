#!/bin/bash

    bash 0-preinstall.sh
    arch-chroot /mnt /root/archKDE/1-setup.sh
    source ./install.conf
	arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/archKDE/2-user.sh
    arch-chroot /mnt /root/archKDE/3-post-setup.sh
