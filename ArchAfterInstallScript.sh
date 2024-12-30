sudo pacman -Syu
mkdir /tmp/yay && (
	cd /tmp/yay
	curl -OJ 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=yay-bin'
	makepkg -si
)

yay -S $(cat ArchNativePackages.txt)
yay -S $(cat ArchAurPackages.txt)

chsh -s $(which zsh)
sudo ln -sfT dash /usr/bin/sh
sudo sed -Ei '/Color/s/^#//' /etc/pacman.conf
sudo sed -Ei 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
sudo sed -Ei "s/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=3s/" /etc/systemd/system.conf
sudo sed -Ei 's/CriticalPowerAction=HybridSleep/CriticalPowerAction=PowerOff/' /etc/UPower/UPower.conf
sudo flatpak override --filesystem=~/.themes
sudo cp -r /mnt/Disk_D/Muhammad/Repositories/Arch-Backup/root_files/volnoti /usr/share/pixmaps/
sudo cp /mnt/Disk_D/Muhammad/Repositories/Arch-Backup/root_files/20-connectivity.conf /etc/NetworkManager/conf.d
sudo cp /mnt/Disk_D/Muhammad/Repositories/Arch-Backup/root_files/bilal /usr/local/bin
sudo cp /mnt/Disk_D/Muhammad/Repositories/Arch-Backup/root_files/default.conf /usr/lib/sddm/sddm.conf.d
sudo cp /mnt/Disk_D/Muhammad/Repositories/Arch-Backup/root_files/environment /etc
sudo cp /mnt/Disk_D/Muhammad/Repositories/Arch-Backup/root_files/my-kbd.yaml /etc/interception-vimproved/
sudo cp /mnt/Disk_D/Muhammad/Repositories/Arch-Backup/root_files/nobeep.conf /etc/modprobe.d
sudo cp /mnt/Disk_D/Muhammad/Repositories/Arch-Backup/root_files/smb.conf /etc/samba
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

sudo systemctl enable --now smb
sudo systemctl enable --now nmb
sudo smbpasswd -a muhammad
sudo groupadd -r sambauser
sudo gpasswd sambauser -a muhammad
sudo systemctl restart smb
sudo systemctl restart nmb

sudo systemctl enable --now libvirtd.service
sudo sed -Ei '/unix_sock_group = "libvirt"/s/^#//' /etc/libvirt/libvirtd.conf
sudo sed -Ei '/unix_sock_rw_perms = "0770"/s/^#//' /etc/libvirt/libvirtd.conf
sudo usermod -a -G libvirt $(whoami)
newgrp libvirt
sudo systemctl restart libvirtd.service
sudo modprobe -r kvm_intel
sudo modprobe kvm_intel nested=1
echo "options kvm-intel nested=1" | sudo tee /etc/modprobe.d/kvm-intel.conf
sudo systemctl enable --now iptables.service
sudo virsh net-autostart default
sudo virsh net-start default

sudo systemctl enable --now auto-cpufreq
sudo systemctl enable --now cups
sudo systemctl enable --now systemd-timesyncd
sudo systemctl enable --now tlp.service
sudo systemctl enable --now udevmon
sudo systemctl enable --now vnstat.service

sudo npm install -g live-server

sudo -s
echo "kernel.sysrq = 1" >> /etc/sysctl.d/99-sysctl.conf
echo "modules_force_load: nvidia,nvidia_modeset,nvidia_uvm,nvidia_drm" >> /etc/booster.yaml
rm -r /root/.local/share/nvim /root/.config/nvim /root/.zshrc /root/.config/zsh /root/.themes /root/.icons /root/.fonts /root/.config/gtk-2.0 /root/.config/gtk-3.0 /root/.config/gtk-4.0
ln -s /home/muhammad/.local/share/nvim /root/.local/share/
ln -s /home/muhammad/.config/nvim /root/.config/
ln -s /home/muhammad/.config/yazi /root/.config/
ln -s /home/muhammad/.config/kanata /root/.config/
ln -s /home/muhammad/.zshrc /root/
ln -s /home/muhammad/.config/zsh /root/.config/
ln -s /home/muhammad/.icons /root/
ln -s /home/muhammad/.fonts /root/
ln -s /home/muhammad/.config/gtk-2.0 /root/.config/
ln -s /home/muhammad/.config/gtk-3.0 /root/.config/
ln -s /home/muhammad/.config/gtk-4.0 /root/.config/
