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
# Hapus paket utama beserta dependency yang udah gak dipakai
sudo pacman -Rns --noconfirm apache mariadb php php-fpm php-gd php-intl unzip wget 2>/dev/null || true
# Hapus orphan packages (paket yang udah gak relevan/tersisa)
sudo pacman -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null || true

echo "=== [3/5] Cleaning System Users & Groups ==="
sudo userdel -f mysql 2>/dev/null || true
sudo groupdel mysql 2>/dev/null || true

echo "=== [4/5] Nuking All Configs, Databases, Logs & Temporary Files ==="
# Directori Web & Omeka
sudo rm -rf /srv/http/*
sudo rm -rf /var/www/*

# Konfigurasi Apache, PHP, & MariaDB
sudo rm -rf /etc/httpd
sudo rm -rf /etc/php
sudo rm -rf /etc/php-fpm.d
sudo rm -rf /etc/php-fpm.conf*
sudo rm -rf /etc/my.cnf*
sudo rm -rf /etc/mysql

# Data Database & Socket Run State
sudo rm -rf /var/lib/mysql
sudo rm -rf /run/mysqld
sudo rm -rf /run/php-fpm
sudo rm -rf /run/httpd

# Log Files
sudo rm -rf /var/log/httpd
sudo rm -rf /var/log/mariadb
sudo rm -rf /var/log/mysqld.log*
sudo rm -rf /var/log/php-fpm.log*

# Temp Files
sudo rm -f /tmp/omeka*.zip
sudo rm -rf /tmp/omeka*

echo "=== [5/5] Cleaning Pacman Cache ==="
sudo pacman -Sc --noconfirm

echo ""
echo "=========================================="
echo "  PEMBERSIHAN TOTAL SELESAI! SISTER SPICK & SPAN."
echo "=========================================="#!/usr/bin/env bash

echo "=========================================="
echo "    UNINSTALLER / CLEANUP OMEKA (ARCH)    "
echo "=========================================="
echo ""

read -p "Yakin mau menghapus total Omeka, Web Server, dan Database? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Pembersihan dibatalkan."
    exit 0
fi

echo ""
echo "=== [1/4] Stopping Services ==="
sudo systemctl stop httpd php-fpm mariadb 2>/dev/null || true
sudo systemctl disable httpd php-fpm mariadb 2>/dev/null || true

echo "=== [2/4] Removing Packages ==="
sudo pacman -Rns --noconfirm apache mariadb php php-fpm php-gd php-intl unzip wget 2>/dev/null || true

echo "=== [3/4] Cleaning Users & Groups ==="
sudo userdel mysql 2>/dev/null || true
sudo groupdel mysql 2>/dev/null || true

echo "=== [4/4] Deleting Configurations & Data Directories ==="
sudo rm -rf /srv/http/omeka
sudo rm -rf /etc/httpd
sudo rm -rf /etc/php
sudo rm -rf /etc/php-fpm.d
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/my.cnf*
sudo rm -rf /var/log/httpd
sudo rm -rf /run/mysqld
sudo rm -rf /run/php-fpm
rm -f /tmp/omeka.zip

echo ""
echo "=========================================="
echo "  PEMBERSIHAN SELESAI! SISTER BALIK BERSIH."
echo "=========================================="
