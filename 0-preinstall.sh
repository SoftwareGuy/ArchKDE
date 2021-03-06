#!/usr/bin/env bash
#-------------------------------------------------------------------------
#      _          _    __  __      _   _
#     /_\  _ _ __| |_ |  \/  |__ _| |_(_)__
#    / _ \| '_/ _| ' \| |\/| / _` |  _| / _|
#   /_/ \_\_| \__|_||_|_|  |_\__,_|\__|_\__|
#  Arch Linux Post Install Setup and Config
#-------------------------------------------------------------------------

# Used later in partitioning step.
PARTBASE=""

setfont ter-v22b

echo "Welcome to the automated installation script!"
echo ""

# setup hostname and username
read -p "What is the hostname of this device? " hostname
read -p "What is the username you wish to use? " username

export hostname=$hostname
export username=$username

printf "hostname="$hostname"\nusername="$username"\n" >> "install.conf"

echo "Got it! One fresh copy of Arch Linux with KDE coming right up!"

echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
iso="au" # set the mirrorlist for Australia

echo "Setting the clock with NTP ..."
timedatectl set-ntp true

echo "Setting up pacman mirror lists..."
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector -c $iso -l 5 --sort rate --save /etc/pacman.d/mirrorlist

echo "Preparing disks..."
if [ ! -d /mnt ]; then 
	mkdir /mnt
fi

echo "-------------------------------------------------"
echo "Disk Selection"
echo "-------------------------------------------------"
lsblk

echo "Please enter disk to work on: (example /dev/sda)"
read DISK
echo "You specified $DISK."

if [ ! -e $DISK ]; then
	echo "ERROR: The specified disk does not exist. Cannot continue."
	exit 1
fi

read -p "Is this a NVMe device (ie. /dev/nvme0n1)? (Y/N): " this_is_nvme

case $this_is_nvme in 
  y|Y|yes|Yes|YES)
	# Prefix because NVMe drives are special.  
	PARTBASE="${DISK}p"
	;;
	
  *)
	# No prefix.
	PARTBASE="$DISK"
	;;
esac

echo "WARNING: THIS WILL FORMAT $DISK AND DELETE ALL DATA ON THE TARGET!!"
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
	mkfs.vfat -v -F32 -n EFISystem "${PARTBASE}1"
	
    if [ $? -ne 0 ]; then 
        echo "ERROR: Formatting EFI Boot partition returned an error. Aborting."
        exit 1
    fi
    
	# Format the GRUB Boot partition.
	mkfs.ext4 -m0 -L BootFS "${PARTBASE}2"

    if [ $? -ne 0 ]; then 
        echo "ERROR: Formatting Boot partition returned an error. Aborting."
        exit 1
    fi


	# Format the swap partition.
	mkswap --verbose "${PARTBASE}3"
	    
    if [ $? -ne 0 ]; then 
        echo "ERROR: Formatting swap partition returned an error. Aborting."
        exit 1
    fi

    # just in case format the partition to linux
    mkfs.ext4 -m1 -L RootFS "${PARTBASE}4"
    
    if [ $? -ne 0 ]; then 
        echo "ERROR: Formatting System root partition returned an error. Aborting."
        exit 1
    fi

	echo "--------------------------------------"
    echo "Mounting partitions..."
    echo "--------------------------------------"
	
    # RootFS is partition 4
	if [ ! -d /mnt ]; then 
		mkdir /mnt
	fi	
	mount "${PARTBASE}4" /mnt
	
    if [ $? -ne 0 ]; then 
        echo "ERROR: Mounting System root partition returned an error. Aborting."
        exit 1
    fi
    
	# EFI is partition 1
	if [ ! -d /mnt/efi ]; then 
		mkdir /mnt/efi
	fi
	mount "${PARTBASE}1" /mnt/efi
    
    if [ $? -ne 0 ]; then 
        echo "ERROR: Mounting EFI Boot partition returned an error. Aborting."
        exit 1
    fi    
	
	# BootFS is partition 2
	if [ ! -d /mnt/boot ]; then 
		mkdir /mnt/boot
	fi
	
	mount "${PARTBASE}2" /mnt/boot
	
    if [ $? -ne 0 ]; then 
        echo "ERROR: Mounting Boot partition returned an error. Aborting."
        exit 1
    fi
    
	# Turn swap on or we may have shit break.
	swapon "${PARTBASE}3"
    
    if [ $? -ne 0 ]; then 
        echo "ERROR: Enabling swap partition returned an error. Aborting."
        exit 1
    fi
    
	sysctl -w vm.swappiness=10
    ;;

  *)
	echo "Safety check: user wants out - aborted!"
	exit 1
	;;
esac
echo "Done."

echo "--------------------------------------"
echo "Installing the base system..."
echo "--------------------------------------"
# Coburn's note: this is messy, but fuck it.
pacstrap /mnt archlinux-keyring base base-devel man man-db m4 bind bison cronie dialog dkms dhcpcd linux linux-headers linux-firmware sof-firmware git \
rng-tools hdparm binutils btrfs-progs gptfdisk dosfstools exfatprogs f2fs-tools e2fsprogs jfsutils nilfs-utils ntfs-3g reiserfsprogs udftools xfsprogs \
vim nano htop bashtop iftop iotop vde2 lvm2 mdadm lzop bridge-utils iptables-nft earlyoom sudo efibootmgr dmidecode networkmanager modemmanager usbutils \
usb_modeswitch pciutils openssh pkgconf rsync lsof wget libnewt ntp ufw nss-mdns

if [ $? -ne 0 ]; then
	echo "ERROR: Pacstrap failure code $?"
	exit 1
fi

echo "- Generating a fstab for the new system"
genfstab -U /mnt >> /mnt/etc/fstab

if [ $? -ne 0 ]; then
	echo "ERROR: Genfstab failure code $?"
	exit 1
fi

echo "Done."

echo "-------------------------------------------------"
echo "Setting up hostnames..."
echo "-------------------------------------------------"
cat <<EOF > /mnt/etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1 $hostname.localdomain $hostname
EOF
echo $hostname > /mnt/etc/hostname
echo "Done."

echo "--------------------------------------"
echo "(Pre-)Installing GRUB..."
echo "--------------------------------------"
arch-chroot /mnt pacman -S --noconfirm --needed grub os-prober 
echo "- GRUB will be configured inside chroot."
echo "Done."

echo "--------------------------------------"
echo "Preconfiguring some services..."
echo "--------------------------------------"
arch-chroot /mnt /usr/bin/systemctl enable sshd
arch-chroot /mnt /usr/bin/systemctl enable NetworkManager
arch-chroot /mnt /usr/bin/systemctl enable ModemManager
arch-chroot /mnt /usr/bin/systemctl enable cronie
arch-chroot /mnt /usr/bin/systemctl enable rngd
arch-chroot /mnt /usr/bin/systemctl enable ntpd
arch-chroot /mnt /usr/bin/systemctl enable earlyoom
arch-chroot /mnt /usr/bin/systemctl enable avahi-daemon
arch-chroot /mnt /usr/bin/systemctl stop dhcpcd
arch-chroot /mnt /usr/bin/systemctl disable dhcpcd
arch-chroot /mnt /usr/bin/systemctl disable systemd-resolved.service
cp -v $(pwd)/conf/etc_nsswitch.txt /mnt/etc/nsswitch.conf

echo "--------------------------------------"
echo "Copying bootstrap files to chroot..."
echo "--------------------------------------"
if [ ! -d /mnt/root/bootstrap ]; then 
	mkdir -p /mnt/root/bootstrap
fi
cp $(pwd)/1-setup.sh /mnt/root/bootstrap/
cp $(pwd)/2-user.sh /mnt/root/bootstrap/
cp $(pwd)/3-post-setup.sh /mnt/root/bootstrap/

cp $(pwd)/install.conf /mnt/root/bootstrap/
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
echo "Done."

echo "--------------------------------------"
echo "Arch Linux base installation complete."
echo "Ready to continue."
echo "--------------------------------------"
echo ""
