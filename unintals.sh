#!/usr/bin/env bash

echo "=========================================="
echo "    DEEP CLEANUP / UNINSTALL OMEKA (ARCH) "
echo "=========================================="
echo ""

read -p "Yakin mau MENGHAPUS TOTAL Omeka, Apache, PHP, MariaDB, & konfigurasinya? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Pembersihan dibatalkan."
    exit 0
fi

echo ""
echo "=== [1/5] Stopping Services & Killing Running Processes ==="
sudo systemctl stop httpd php-fpm mariadb 2>/dev/null || true
sudo systemctl disable httpd php-fpm mariadb 2>/dev/null || true
sudo killall -9 httpd php-fpm mariadbd mysqld 2>/dev/null || true

echo "=== [2/5] Purging Packages & Unneeded Dependencies ==="
# Hapus paket utama beserta dependency
sudo pacman -Rns --noconfirm apache mariadb php php-fpm php-gd php-intl unzip wget 2>/dev/null || true

# Hapus orphan packages (paket gantung yang udah gak dipakai)
ORPHANS=$(pacman -Qdtq 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    sudo pacman -Rns --noconfirm $ORPHANS 2>/dev/null || true
fi

echo "=== [3/5] Cleaning System Users & Groups ==="
sudo userdel -f mysql 2>/dev/null || true
sudo groupdel mysql 2>/dev/null || true

echo "=== [4/5] Nuking All Configs, Databases, Logs & Temporary Files ==="
# Direktori Web & Omeka
sudo rm -rf /srv/http/*
sudo rm -rf /var/www/*

# Konfigurasi Apache, PHP, & MariaDB
sudo rm -rf /etc/httpd
sudo rm -rf /etc/php
sudo rm -rf /etc/php-fpm.d
sudo rm -rf /etc/php-fpm.conf*
sudo rm -rf /etc/my.cnf*
sudo rm -rf /etc/mysql
u
# Data Database, Socket, & Run State
sudo rm -rf /var/lib/mysql
sudo rm -rf /run/mysqld
sudo rm -rf /run/php-fpm
sudo rm -rf /run/httpd

# Log Files
sudo rm -rf /var/log/httpd
sudo rm -rf /var/log/mariadb
sudo rm -rf /var/log/mysqld.log*
sudo rm -rf /var/log/php-fpm.log*

# Temp Files & Symlinks Socket
sudo rm -f /tmp/omeka*.zip
sudo rm -rf /tmp/omeka*
sudo rm -f /tmp/mysql.socku

echo "=== [5/5] Cleaning Pacman Cache ==="
sudo pacman -Sc --noconfirm

echo ""
echo "=========================================="
echo "  PEMBERSIHAN TOTAL SELESAI! SISTEM BERSIH."
echo "=========================================="
