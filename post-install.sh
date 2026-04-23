#!/usr/bin/env bash
# ===============================================================
# Arch Linux Post-Install Script
# ===============================================================
set -euo pipefail

# ── Helpers ────────────────────────────────────────────────────
log()  { echo -e "\n\e[1;34m==> $*\e[0m"; }
ok()   { echo    "    ✓ $*"; }
fail() { echo -e "\e[1;31m✗ $*\e[0m" >&2; exit 1; }

BACKUP_ROOT="/mnt/Disk_D/Muhammad/Repositories/Arch-Backup/root-files"

# ── 1. System update ───────────────────────────────────────────
log "System update"
sudo pacman -Syu --noconfirm

# ── 2. AUR helper (paru) ───────────────────────────────────────
log "Installing paru"
if ! command -v paru &>/dev/null; then
  tmp=$(mktemp -d)
  git clone https://aur.archlinux.org/paru.git "$tmp/paru"
  (cd "$tmp/paru" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  ok "paru installed"
else
  ok "paru already present, skipping"
fi

# ── 3. Packages ────────────────────────────────────────────────
log "Installing native packages"
paru -S --needed --noconfirm - < ArchNativePackages.txt

log "Installing AUR packages"
paru -S --needed --noconfirm - < ArchAurPackages.txt

# ── 4. Shell ───────────────────────────────────────────────────
log "Shell configuration"
chsh -s "$(which zsh)"
sudo ln -sfT dash /usr/bin/sh
ok "Default shell → zsh, /usr/bin/sh → dash"

# ── 5. Pacman tweaks ───────────────────────────────────────────
log "Pacman configuration"
sudo sed -Ei '/Color/s/^#//'                              /etc/pacman.conf
sudo sed -Ei 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
ok "Color + parallel downloads enabled"

# ── 6. Systemd tweaks ──────────────────────────────────────────
log "Systemd configuration"
sudo sed -Ei "s/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=3s/" \
  /etc/systemd/system.conf
sudo sed -Ei 's/CriticalPowerAction=HybridSleep/CriticalPowerAction=PowerOff/' \
  /etc/UPower/UPower.conf
ok "Stop timeout 3 s, critical power action → PowerOff"

# ── 7. sddm theme ──────────────────────────────────────────────
log "Installing simple-sddm theme"
git clone https://github.com/JaKooLit/simple-sddm.git ~/simple-sddm
sudo mv ~/simple-sddm /usr/share/sddm/themes/
ok "Done"

# ── 8. Copy config/root files ──────────────────────────────────
log "Copying root-level config files"

copy_root() {
  local src="$BACKUP_ROOT/$1" dst="$2"
  [[ -e "$src" ]] || fail "Missing: $src"
  sudo mkdir -p "$(dirname "$dst")"
  sudo cp "$src" "$dst"
  ok "$dst"
}

copy_root "20-connectivity.conf"   /etc/NetworkManager/conf.d/20-connectivity.conf
copy_root "Arc Dark.ini"           /usr/share/albert/widgetsboxmodel/themes/Arc\ Dark.ini
copy_root "Tokyonight Dark.ini"    /usr/share/albert/widgetsboxmodel/themes/Tokyonight\ Dark.ini
copy_root "bilal"                  /usr/local/bin/bilal
copy_root "confetti"               /usr/local/bin/confetti
copy_root "default.conf"           /usr/lib/sddm/sddm.conf.d/default.conf
copy_root "environment"            /etc/environment
copy_root "hyprland-minimizer"     /usr/local/bin/hyprland-minimizer
copy_root "kanata.service"         /etc/systemd/system/kanata.service
copy_root "nobeep.conf"            /etc/modprobe.d/nobeep.conf
copy_root "smb.conf"               /etc/samba/smb.conf
copy_root "theme.conf"             /usr/share/sddm/themes/simple-sddm/theme.conf

# Make /usr/local/bin scripts executable
sudo chmod +x /usr/local/bin/{bilal,confetti,hyprland-minimizer}

# ── 9. GTK dark mode ───────────────────────────────────────────
log "GTK dark mode"
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
sudo flatpak override --filesystem=~/.themes
ok "Done"

# ── 10. Samba ──────────────────────────────────────────────────
log "Samba setup"
sudo systemctl enable --now smb nmb
sudo groupadd -r sambauser 2>/dev/null || true
sudo gpasswd -a muhammad sambauser
sudo smbpasswd -a muhammad
sudo systemctl restart smb nmb
ok "Samba running"

# ── 11. Virtualization (KVM/libvirt) ───────────────────────────
log "Virtualization setup"
paru -S --needed --noconfirm qemu-full virt-manager virt-viewer dnsmasq

sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now virtlogd.service
sudo systemctl enable --now virtlogd.socket

sudo virsh net-autostart default
sudo virsh net-start default 2>/dev/null || true

sudo usermod -aG libvirt "$(whoami)"
ok "KVM/libvirt ready (re-login for group membership)"

# ── 12. Remaining services ─────────────────────────────────────
log "Enabling services"
for svc in auto-cpufreq cups kanata.service systemd-timesyncd vnstat.service bluetooth.service; do
  sudo systemctl enable --now "$svc" && ok "$svc"
done

# ── 13. Global npm packages ────────────────────────────────────
log "Global npm/pnpm packages"
pnpm add -g neovim live-server typescript tsx @google/gemini-cli
ok "neovim, live-server, gemini-cli"

# ── 14. Flatpak apps ───────────────────────────────────────────
log "Flatpak apps"
flatpak install -y flathub \
  io.github._0xzer0x.qurancompanion \
  net.sapples.LiveCaptions
ok "Flatpak apps installed"

# ── 15. Root account symlinks ──────────────────────────────────
log "Root user symlinks"
sudo bash -s <<'ROOT'
  set -euo pipefail
  echo "kernel.sysrq = 1" >> /etc/sysctl.d/99-sysctl.conf

  USER_HOME=/home/muhammad
  rm -rf \
    /root/.local/share/nvim /root/.config/nvim \
    /root/.zshrc /root/.config/zsh \
    /root/.themes /root/.icons /root/.fonts \
    /root/.config/gtk-{2,3,4}.0

  for d in gtk-2.0 gtk-3.0 gtk-4.0 kanata nvim yazi zsh; do
    ln -s "$USER_HOME/.config/$d" /root/.config/
  done
  for d in .fonts .icons .themes; do
    ln -s "$USER_HOME/$d" /root/
  done
  ln -s "$USER_HOME/.local/share/nvim" /root/.local/share/
  ln -s "$USER_HOME/.zshrc" /root/
  echo "  ✓ Root symlinks created"
ROOT

# ── Done ──────────────────────────────────────────────────────
log "All done! Re-login (or reboot) for group changes to take effect."
