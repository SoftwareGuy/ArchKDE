#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------

# setup hostname and username
read -p "What is the hostname of this device? " hostname
read -p "What is the username you wish to use? " username
printf "hostname="$hostname"\n" >> "install.conf"
printf "username="$username"\n" >> "install.conf"
export hostname=$hostname
export username=$username

echo "Got it! One fresh copy of Arch Linux with KDE coming right up!"

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
iso="au" # set the mirrorlist for Australia

echo "Setting the clock with NTP ..."
timedatectl set-ntp true

pacman -S --noconfirm pacman-contrib terminus-font

echo "Setting up console fonts ..."
setfont ter-v22b

echo "Setting up pacman mirror lists..."
# No need to reinstall this shit
# pacman -S --noconfirm reflector rsync

mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector -c $iso -l 5 --sort rate --save /etc/pacman.d/mirrorlist
if [ ! -d /mnt ]; then 
	mkdir /mnt
fi

echo "-------------------------------------------------"
echo "Disk Selection"
echo "-------------------------------------------------"

lsblk
echo "Please enter disk to work on: (example /dev/sda)"
read DISK
echo "WARNING: THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK!!"
read -p "Take a deep breath. Are you really sure you want to continue? (Y/N):" formatdisk

case $formatdisk in 
  y|Y|yes|Yes|YES)
  
	swapoff -av
    # CASE THE USER WANTS TO FORMAT THE DISK
    echo "--------------------------------------"
    echo "Deleting all partitions on $DISK"
    echo "--------------------------------------"
    
	# disk prep
    sfdisk --delete $DISK # delete all partitions

    # make filesystems
	echo "--------------------------------------"
    echo "Partitioning $DISK"
    echo "--------------------------------------"

    # Create a GPT partition table, that has a 64MB EFI Partition,
	# 512MB Boot Partition, 4GB Swap and the rest allocated to Linux.
    fdisk $DISK << EOF
g
n
1

+64M
t
1
1
n
2

+512M
t
2
20
n
3

+4096M
t
3
19
n
4


w
EOF

	echo "--------------------------------------"
    echo "Formatting partitions..."
    echo "--------------------------------------"
	
	# Format EFI Boot partition.
	mkfs.vfat -v -F32 -n EFISystem "${DISK}1"
	
	# Format the GRUB Boot partition.
	mkfs.ext4 -m0 -L BootFS "${DISK}2"
	
	# Format the swap partition.
	mkswap --verbose "${DISK}3"
	
    # just in case format the partition to linux
    mkfs.ext4 -m1 -L RootFS "${DISK}4"

	echo "--------------------------------------"
    echo "Mounting partitions..."
    echo "--------------------------------------"
	
    # RootFS is partition 4
	if [ ! -d /mnt ]; then 
		mkdir /mnt
	fi	
	mount "${DISK}4" /mnt
	
	# EFI is partition 1
	if [ ! -d /mnt/efi ]; then 
		mkdir /mnt/efi
	fi
	mount "${DISK}1" /mnt/efi
	
	# BootFS is partition 2
	if [ ! -d /mnt/boot ]; then 
		mkdir /mnt/boot
	fi
	
	mount "${DISK}2" /mnt/boot
	
	# Turn swap on.
	swapon "${DISK}3"
    ;;

  *)
	echo "Safety check: user wants out - aborted!"
	exit 1
	;;

esac

echo "--------------------------------------"
echo "Installing Arch Linux Base..."
echo "--------------------------------------"
pacstrap /mnt base base-devel linux linux-headers linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf

echo "--------------------------------------"
echo "Installing GRUB..."
echo "--------------------------------------"
arch-chroot /mnt pacman -S --noconfirm grub
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/mnt/efi --boot-directory=/mnt/boot --root-directory=/mnt 
arch-chroot /mnt grub-mkconfig -o /mnt/boot/grub/grub.cfg

if [ ! -d /mnt/root/bootstrap ]; then 
	mkdir -p /mnt/root/bootstrap
fi
	
echo "--------------------------------------"
echo "Copying bootstrap files to chroot..."
echo "--------------------------------------"
cp -R $(pwd)/*.sh /mnt/root/bootstrap/
cp $(pwd)/install.conf /mnt/root/bootstrap/
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

echo "--------------------------------------"
echo "Arch Linux Base installation complete."
echo "Ready to continue."
echo "--------------------------------------"
