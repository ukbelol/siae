#!/bin/bash
# Script para preparar netinstall do Debian 12 Bookworm
# Rode como root

set -e

# Configurações
DEBIAN_VERSION="12.11.0"  # Confere a última em cdimage.debian.org
ARCH="amd64"
TFTP_ROOT="/srv/tftp"
HTTP_ROOT="/var/www/html/debian"
INTERFACE="eth0"  # Placa de rede que vai servir o PXE

echo "=== Instalando dependências ==="
apt update
apt install -y wget dnsmasq apache2 syslinux-common pxelinux

echo "=== Baixando netboot Debian 12 ==="
mkdir -p $TFTP_ROOT
cd $TFTP_ROOT
wget -O netboot.tar.gz https://deb.debian.org/debian/dists/bookworm/main/installer-$ARCH/current/images/netboot/netboot.tar.gz
tar -xzf netboot.tar.gz
cp /usr/lib/PXELINUX/pxelinux.0 $TFTP_ROOT/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 $TFTP_ROOT/
rm netboot.tar.gz

echo "=== Criando arquivo preseed ==="
mkdir -p $HTTP_ROOT
cat > $HTTP_ROOT/preseed.cfg << 'EOF'
# Debian 12 Preseed - Instalação automática básica
d-i debian-installer/locale string pt_BR.UTF-8
d-i keyboard-configuration/xkb-keymap select br
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string debian12
d-i netcfg/get_domain string local

# Particionamento - usa disco inteiro, LVM
d-i partman-auto/method string lvm
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-lvm/confirm boolean true
d-i partman-auto-lvm/guided_size string max
d-i partman-auto/choose_recipe select atomic
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# Usuário
d-i passwd/root-password password root123
d-i passwd/root-password-again password root123
d-i passwd/user-fullname string Admin
d-i passwd/username string admin
d-i passwd/user-password password admin123
d-i passwd/user-password-again password admin123
d-i user-setup/allow-password-weak boolean true

# Repositórios
d-i apt-setup/use_mirror boolean true
d-i mirror/country string BR
d-i mirror/http/mirror select deb.debian.org
d-i apt-setup/non-free boolean true
d-i apt-setup/contrib boolean true

# Pacotes
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string curl wget sudo net-tools
d-i pkgsel/upgrade select full-upgrade

# Bootloader
d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default

# Finalizar