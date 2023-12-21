#!/user/bin/env bash

# Note: this installation script assumes that you already have 
# partitioned your disk e.g. using cfdisk or fdisk

lsblk

echo "Please enter your EFI partition: (e.g /dev/sda1 or /dev/nvme0n1p1)"
read -p "EFI partition: " EFI

echo "Please enter your root partition: (e.g /dev/sda2 or /dev/nvme0n1p2)"
read -p "Root partition: " ROOT

echo "Mounting partitions..."
mkfs.fat -F32 $EFI
mkfs.ext4 $ROOT

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

echo "Installing base system..."