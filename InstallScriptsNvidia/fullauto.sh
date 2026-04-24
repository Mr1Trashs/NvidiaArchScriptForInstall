#!/bin/bash
NAME="Home"
PASS_USER="1"
PASS_ROOT="root"
DRIVE="/dev/nvme0n1"
# Пакеты: Cinnamon, NVIDIA, Темы и PipeWire
DE_PKGS="cinnamon lightdm lightdm-slick-greeter lightdm-settings nvidia-open nvidia-utils arc-gtk-theme papirus-icon-theme"
SOUND="pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber"

reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
printf "label: gpt\n,512M,U,*\n,,L,\n" | sfdisk "$DRIVE"
mkfs.vfat -F 32 "${DRIVE}p1"
mkfs.ext4 "${DRIVE}p2"
mount "${DRIVE}p2" /mnt
mkdir -p /mnt/boot/efi
mount "${DRIVE}p1" /mnt/boot/efi

pacstrap /mnt base base-devel linux linux-firmware linux-headers nano bash-completion \
grub efibootmgr networkmanager xorg ttf-ubuntu-font-family ttf-hack $DE_PKGS $SOUND \
kitty discord steam chromium jre-openjdk fastfetch btop wget curl

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
timedatectl set-timezone Europe/Kyiv
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Sy
useradd -m -G wheel "$NAME"
echo "$NAME:$PASS_USER" | chpasswd
echo "root:$PASS_ROOT" | chpasswd

# Настройка GRUB под NVIDIA
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nvidia-drm.modeset=1"/' /etc/default/grub

echo -e "[Seat:*]\ngreeter-session=lightdm-slick-greeter" > /etc/lightdm/lightdm.conf
systemctl enable NetworkManager
systemctl enable lightdm

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF
umount -R /mnt
reboot
