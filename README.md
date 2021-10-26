# Coburn's Arch Linux KDE Bootstrapper

This is a heavily modified version of the Titus ArchMatic Installer Script that strings together from start to finish a fully functional KDE installation. As it is heavily modified to suit my taste, 
it may not be suitable for you as a daily driver. It tries to support a lot of usage cases, including productivity, gaming, virtual machines... and a little more. It is also tweaked in a few ways,
as well as using the Liquorix kernel for even more performance.

## How to use
-	Create a Arch Linux Installer boot USB
-	Boot said Arch Linux Installer USB
-	Install `git` via `pacman -Sy git`
-	Git clone this repository and change into the directory
- 	Run the `archmatic.sh` from terminal and answer questions when prompted

The script aims for UEFI installation only because that's current year using GRUB Bootloader and supports both SATA and NVMe installations. NVMe isn't always the same naming scheme as SATA so watch out...

### System Description

This is an automated arch install with minimal prompting that will bootstrap a KDE desktop environment with a generous sprinkle of applications and stuff.

### Troubleshooting Arch Linux

**[Arch Linux Installation Guide](https://github.com/rickellis/Arch-Linux-Install-Guide)**

#### Wait, what? No Wifi?

Something broke, you probably can fix it.
