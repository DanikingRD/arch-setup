#!/user/bin/env bash

# Note: this installation script assumes that you already have 
# partitioned your disk e.g. using cfdisk or fdisk

lsblk

echo "Please enter your EFI partition: (e.g /dev/sda1 or /dev/nvme0n1p1)"
read -p "EFI partition: " EFI

echo "Please enter your root partition: (e.g /dev/sda2 or /dev/nvme0n1p2)"
read -p "Root partition: " ROOT
echo "Making filesystems..."
mkfs.fat -F32 $EFI
mkfs.ext4 $ROOT
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
pacstrap /mnt base base-devel linux linux-firmware
echo "Installing core programs..."1
pacstrap /mnt networkmanager vim git

echo "Generating filesystem table..."
genfstab -U /mnt > /mnt/etc/fstab

cat <<REALEND > /mnt/next.sh
systemctl enable NetworkManager

echo "================================"
echo "  == Installing boot loader ==  "
echo "================================"
# fix sudo not found

sudo pacman -S efibootmgr grub
grub-install --target=x86_64-efi —-efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg

echo "Boot loader setup complete."

echo "================================"
echo "  == Setting up user account == "
echo "================================"
useradd -mG wheel,video,audio,tty daniking
passwd
echo "Please enter your hostname: "
read -p "Hostname: " HOSTNAME
echo $HOSTNAME > /etc/hostname

REALEND

chmod +x /mnt/next.sh
arch-chroot /mnt ./next.sh