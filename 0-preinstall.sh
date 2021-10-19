#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------

# setup hostname and username
read -p "Please enter hostname:" hostname
read -p "Please enter username:" username
printf "hostname="$hostname"\n" >> "install.conf"
printf "username="$username"\n" >> "install.conf"
export hostname=$hostname
export username=$username

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
iso="br" # set the mirrorlist for Brazil
timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib terminus-font
setfont ter-v22b
pacman -S --noconfirm reflector rsync
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector -c $iso -l 5 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt


echo -e "\nInstalling prereqs...\n$HR"
pacman -S --noconfirm gptfdisk btrfs-progs

echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"

lsblk
echo "Please enter disk to work on: (example /dev/sda)"
read DISK
echo "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
read -p "are you sure you want to continue (Y/N):" formatdisk
case $formatdisk in 
  y|Y|yes|Yes|YES)

    # CASE THE USER WANTS TO FORMAT THE DISK
    echo "--------------------------------------"
    echo -e "\nFormatting disk...\n$HR"
    echo "--------------------------------------"

    # disk prep
    sfdisk --delete $DISK # delete all partitions


    # make filesystems
    echo -e "\nCreating Filesystems...\n$HR"

    # only create a single partition with a MBR partition table
    fdisk $DISK << EOF
o
n
p
1




Y
a
w
EOF

    # just in case format the partition to linux
    mkfs.ext4 "${DISK}1"

    # mount the partition to /mnt
    mount "${DISK}1" /mnt

    ;;

  *)
    # CASE THE USER DOES NOT WANT TO FORMAT THE DISK
    read -p "What partition should mount as root? [i.e: /dev/sda1]" mounting_partition
    mount $mounting_partition /mnt
    ;;

esac

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
echo "--------------------------------------"
echo "-- Bootloader Systemd Installation  --"
echo "--------------------------------------"


# install grub for MBR booting instead of UEFI
arch-chroot /mnt pacman -S --noconfirm grub
arch-chroot /mnt grub-install --target=i386-pc --root-directory=/mnt $DISK 
arch-chroot /mnt grub-mkconfig -o /mnt/boot/grub/grub.cfg

cp -R ~/archKDE /mnt/root/
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

echo "--------------------------------------"
echo "--   SYSTEM READY FOR 0-setup       --"
echo "--------------------------------------"
