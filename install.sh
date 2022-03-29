# variable

netdevice=""
netssid=""
netpass=""
keymap=""
timezone=""
disk=""
efi=""
swap=""
rootfs=""
region=""
city=""
hostname=""
user=""

function Network()
{
	iwctl device list

	echo "Device: "
	read netdevice

	iwctl station $netdevice scan
	iwctl station $netdevice get-networks

	echo "SSID: "
	read netssid

	echo "Passphrase: "
	read netpass

	iwctl --passphrase $netpass station $netdevice connect $netssid
}

function KeyMapping()
{
	ls /usr/share/kbd/keymaps/**/*.map.gz | less
	
	echo "Keymap: "
	read keymap

	loadkeys $keymap
}

function Timezone()
{
	timedatectl list-timezones

	echo "Timezone: "
	read timezone

	timedatectl set-timezone $timezone
	timedatectl set-ntp true
	timedatectl status
}

function Disk()
{
	fdisk -l

	echo "Disk: "
	read disk

	fdisk $disk

	clear

	echo "EFI: "
	read efi

	echo "Swap: "
	read swap

	echo "Linux Filesystem: "
	read rootfs


	mkfs.fat -F32 $efi
	mkswap $swap
	swapon $swap
	mkfs.ext4 $rootfs
	mount $rootfs /mnt
}

function BaseInstallation()
{
	pacstrap /mnt base linux-lts linux-firmware

	genfstab -U /mnt >> /mnt/etc/fstab
	cp ~/install-arch/install.sh /mnt
	arch-chroot /mnt && ./install.sh
}

function ZoneInfo()
{
	ls /usr/share/zoneinfo/

	echo "Select region: "
	read region

	ls /usr/share/zoneinfo/$region/

	echo "Select city: "
	read city

	ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime

	hwclock --systohc

	pacman -S neovim
	neovim /etc/locale.gen
	locale-gen
}

function User()
{
	echo "Hostname: "
	read hostname

	touch /etc/hostname
	echo $hostname > /etc/hostname

	echo "
	127.0.0.1   localhost
	::1         localhost
	127.0.0.1   $hostname.localdomain   $hostname
	" > /etc/hosts

	echo "Root Password: "
	passwd


	echo "New User: "
	read user

	useradd -m $user

	echo "$user password: "
	passwd $user

	usermod -aG wheel,audio,video,storage,optical,$user $user
}


function Install()
{
	pacman -S sudo grub efibootmgr dosfstools os-prober mtools

	mkdir /boot/EFI
	mount /dev/$efi /boot/EFI

	grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
	grub-mkconfig -o /boot/grub/grub.cfg

	pacman -S iwd iw wireless_tools wpa_supplicant nm-connection-editor networkmanager neovim git

	systemctl enable NetworkManager

	EDITOR=nvim visudo
}



function takeInput()
{
	read input
	echo $input
}

function checkInput()
{
	if [[ $1 == "1" ]]; then
		Network
	elif [[ $1 == "2" ]]; then
		KeyMapping
	elif [[ $1 == "3" ]]; then
		Timezone
	elif [[ $1 == "4" ]]; then
		Disk
	elif [[ $1 == "5" ]]; then
		BaseInstallation
	elif [[ $1 == "6" ]]; then
		ZoneInfo
	elif [[ $1 == "7" ]]; then
		User
	elif [[ $1 == "8" ]]; then
		Install
	elif [[ $1 == "0" ]]; then
		umount -l /mnt
		reboot
	fi
}


echo "==========================="
echo "[Arch base linux installer]"
echo "==========================="

echo "1) Network"
echo "2) Keymap"
echo "3) Timezone"
echo "4) Disk"
echo "5) Base Install"
echo "6) Zone Info"
echo "7) User setup"
echo "8) Install"
echo "0) Reboot"

option=$(takeInput)
checkInput $option
