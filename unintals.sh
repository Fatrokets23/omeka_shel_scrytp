#!/usr/bin/env bash

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
