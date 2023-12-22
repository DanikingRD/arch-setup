#!/user/bin/env bash

# Note: this installation script assumes that you already have 
# partitioned your disk e.g. using cfdisk or fdisk

lsblk

echo "Please enter your EFI partition: (e.g /dev/sda1 or /dev/nvme0n1p1)"
read -p "EFI partition: " EFI

echo "Please enter your root partition: (e.g /dev/sda2 or /dev/nvme0n1p2)"
read -p "Root partition: " ROOT

echo "Please enter your username: "
read -p "Username: " USERNAME

echo "Please enter your password: "
read -p "Password: " PASSWORD

echo "Making filesystems..."
mkfs.ext4 $ROOT
mkfs.fat -F32 $EFI
echo "Mounting partitions..."
mount $ROOT /mnt
mkdir /mnt/boot
mount $EFI /mnt/boot

echo "Partitioning complete!"
echo "Now confirm that the mountpoints are correct".
echo "Press (y) to continue or (n) to abort."
lsblk
read -p "Continue? (y/n): " CONTINUE

if [ $CONTINUE == "n" ]; then
    echo "Aborting..."
    exit 1
fi

echo "================================"
echo "  == Installing base system ==  "
echo "================================"
pacstrap /mnt base base-devel linux linux-firmware --noconfirm
echo "Installing core programs..."1
pacstrap /mnt networkmanager vim git --noconfirm

echo "Generating filesystem table..."
genfstab -U /mnt > /mnt/etc/fstab
cat <<REALEND > /mnt/next.sh
systemctl enable NetworkManager

echo "================================"
echo "  == Installing boot loader ==  "
echo "================================"

sudo pacman -S efibootmgr grub --noconfirm
grub-install --target=x86_64-efi —-efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg

echo "Boot loader setup complete."

echo "================================"
echo "  == Setting up user account == "
echo "================================"

useradd -mG wheel,video,audio,tty $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

HOSTNAME="arch"
echo $HOSTNAME > /etc/hostname

echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

echo "================================"
echo "  == Setting up time zone ==    "
echo "================================"
# default to en_US.UTF-8
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
ln -sf /usr/share/zoneinfo/America/Santo_Domingo /etc/localtime

echo "================================"
echo "  == Setting up audio ==        "
echo "================================"
pacman -S  pulseaudio --noconfirm
systemctl enable pulseaudio

echo "===================================================="
echo " == Base system installed, you can reboot now ==   "
echo "===================================================="

REALEND

chmod +x /mnt/next.sh
arch-chroot /mnt ./next.sh
