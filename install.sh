echo "Connect to internet wifi"

iwctl device list

echo "Enter Device Name: "

deviceName=""
read deviceName

echo "Enter SSID: "

ssid=""
read ssid

echo "Enter Password: "

pass=""
read pass

iwctl --passphrase $pass station $deviceName connect $ssid


echo "Connected to internet."
echo "Testing..."

ping www.google.com


clear

echo "Keymapping Setup"

ls /usr/share/kbd/keymaps/**/*.map.gz | less

echo "Enter name of key map: "

keyMap=""
read keyMap

loadkeys $keyMap

echo "Done..."

clear

echo "Timezone Setup"

timedatectl --list-timezone

echo "Enter timezone:"

timeZone=""
read timeZone

timedatectl --set-timezone $timeZone
timedatectl set-ntp true
timedatectl status

clear

echo "Disk Setup"

fdisk -l

echo "Disk Name: "

diskName=""
read diskName

fdisk $diskName

clear

echo "EFI: "

efi=""
read efi

echo "Swap: "

swap=""
read swap

echo "Linux Filesystem: "

lfs=""
read lfs


mkfs.fat -F32 $efi
mkswap $swap
swapon $swap
mkfs.ext4 $lfs
mount $lfs /mnt

clear

pacstrap /mnt base linux-lts linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

ls /usr/share/zoneinfo/

echo "Select region: "

rgn=""
read rgn

ls /usr/share/zoneinfo/$rgn/

echo "Select city: "

city=""
read city

ln -sf /usr/share/zoneinfo/$rgn/$city /etc/localtime

hwclock -systohc

pacman -S neovim
nvim /etc/locale.gen
locale-gen

echo "Enter hostname: "

hostname=""
read hostname

touch /etc/hostname
echo $hostname > /etc/hostname

echo "
127.0.0.1   localhost
::1         localhost
127.0.0.1   $hostname.localdomain   $hostname
" > /etc/hosts

cat /etc/hosts

passwd


echo "user: "

user=""
read user

useradd -m $user
passwd $user

usermod -aG wheel,audio,video,storage,optical,$user $user

pacman -S sudo grub efibootmgr dosfstools os-prober mtools

mkdir /boot/EFI
mount /dev/$efi /boot/EFI

grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S iwd iw wireless_tools wpa_supplicant nm-connection-editor networkmanager neovim git

systemctl enable NetworkManager

umount -l /mnt

reboot
