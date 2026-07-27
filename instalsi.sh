#!/usr/bin/env bash

# Exit jika terjadi error
set -e

# === INTERACTIVE INPUT ===
echo "=========================================="
echo "    AUTOMATED OMEKA INSTALLER (ARCH)     "
echo "=========================================="
echo ""

# 1. Input Password Database
read -sp "Masukkan Password baru untuk MariaDB (omeka_user): " DB_PASS
echo ""
while [ -z "$DB_PASS" ]; do
    echo "Password tidak boleh kosong!"
    read -sp "Masukkan Password baru untuk MariaDB (omeka_user): " DB_PASS
    echo ""
done

# 2. Deteksi IP Server Secara Otomatis
DETECTED_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
if [ -z "$DETECTED_IP" ]; then
    DETECTED_IP="localhost"
fi

read -p "Masukkan IP Address / Domain Server [$DETECTED_IP]: " SERVER_NAME
SERVER_NAME=${SERVER_NAME:-$DETECTED_IP}

echo ""
echo "------------------------------------------"
echo " Configuration Summary:"
echo " DB User    : omeka_user"
echo " DB Name    : omeka_db"
echo " DB Pass    : ********"
echo " Server Name: $SERVER_NAME"
echo "------------------------------------------"
read -p "Lanjutkan instalasi? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Instalasi dibatalkan."
    exit 1
fi

echo ""
echo "=== [1/7] Updating System & Installing Packages ==="
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm apache mariadb php php-fpm php-gd php-intl unzip wget

echo "=== [2/7] Initializing & Starting MariaDB ==="
# Buat user & group mysql jika belum ada
sudo groupadd -g 89 mysql 2>/dev/null || true
sudo useradd -u 89 -g mysql -d /var/lib/mysql -s /bin/false mysql 2>/dev/null || true

# Matikan service jika sempat running setengah jalan
sudo systemctl stop mariadb 2>/dev/null || true

# Bersihkan direktori & set permission yang tepat
sudo rm -rf /var/lib/mysql /run/mysqld
sudo mkdir -p /var/lib/mysql /run/mysqld
sudo chown -R mysql:mysql /var/lib/mysql /run/mysqld
sudo chmod 700 /var/lib/mysql

# Inisialisasi Database
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

# Start service MariaDB
sudo systemctl enable --now mariadb

# Symlink socket untuk mengantisipasi PHP MySQLi
sudo ln -sf /run/mysqld/mysqld.sock /tmp/mysql.sock 2>/dev/null || true
sudo ln -sf /run/mysqld/mysqld.sock /var/lib/mysql/mysql.sock 2>/dev/null || true

echo "=== [3/7] Setting up Database & User ==="
sudo mariadb -u root <<EOF
CREATE DATABASE IF NOT EXISTS omeka_db;
CREATE USER IF NOT EXISTS 'omeka_user'@'localhost' IDENTIFIED BY '$DB_PASS';
CREATE USER IF NOT EXISTS 'omeka_user'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';
ALTER USER 'omeka_user'@'localhost' IDENTIFIED BY '$DB_PASS';
ALTER USER 'omeka_user'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON omeka_db.* TO 'omeka_user'@'localhost';
GRANT ALL PRIVILEGES ON omeka_db.* TO 'omeka_user'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF

echo "=== [4/7] Downloading & Extracting Omeka ==="
wget -q https://github.com/omeka/omeka/releases/download/v3.2.1/omeka-3.2.1.zip -O /tmp/omeka.zip
unzip -q /tmp/omeka.zip -d /tmp/
sudo rm -rf /srv/http/omeka
sudo mv /tmp/omeka-3.2.1 /srv/http/omeka
rm -f /tmp/omeka.zip

echo "=== [5/7] Configuring db.ini & PHP ==="
# Gunakan 127.0.0.1 (TCP port 3306) untuk menghindari socket error pada Zend
sudo bash -c "cat <<EOF > /srv/http/omeka/db.ini
[database]
host = \"127.0.0.1\"
username = \"omeka_user\"
password = \"$DB_PASS\"
dbname = \"omeka_db\"
prefix = \"omeka_\"
charset = \"utf8\"
port = \"3306\"
EOF"

# Aktifkan ekstensi di php.ini
PHP_INI="/etc/php/php.ini"
EXTS=("pdo_mysql" "mysqli" "gd" "iconv" "exif")

for ext in "${EXTS[@]}"; do
    sudo sed -i "s/^;extension=${ext}/extension=${ext}/" "$PHP_INI"
done

sudo systemctl enable --now php-fpm

echo "=== [6/7] Configuring Apache (httpd) ==="
# VirtualHost Omeka dengan ServerName dinamis
sudo bash -c "cat <<EOF > /etc/httpd/conf/extra/omeka.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot \"/srv/http/omeka\"
    ServerName $SERVER_NAME

    ErrorLog \"/var/log/httpd/omeka.error_log\"
    CustomLog \"/var/log/httpd/omeka.access_log\" common

    <Directory \"/srv/http/omeka\">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF"

# Aktifkan modul-modul penting Apache
MODULES=("rewrite_module" "proxy_module" "proxy_fcgi_module")
for mod in "${MODULES[@]}"; do
    sudo sed -i "s/^#LoadModule ${mod}/LoadModule ${mod}/" /etc/httpd/conf/httpd.conf
done

# Pastikan DirectoryIndex membaca index.php
sudo sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /etc/httpd/conf/httpd.conf

# Tambahkan konfigurasi PHP-FPM dan Include jika belum ada
if ! grep -q "conf/extra/omeka.conf" /etc/httpd/conf/httpd.conf; then
    sudo bash -c 'cat <<EOF >> /etc/httpd/conf/httpd.conf

<Directory "/srv/http">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php-fpm/php-fpm.sock|fcgi://localhost/"
</FilesMatch>

Include conf/extra/omeka.conf
EOF'
fi

echo "=== [7/7] Setting Permissions & Restarting Services ==="
sudo chmod 755 /srv
sudo chmod 755 /srv/http
sudo chown -R http:http /srv/http/omeka
sudo chmod -R 755 /srv/http/omeka

sudo systemctl restart php-fpm httpd mariadb

echo ""
echo "================================================="
echo "  INSTALASI SELESAI!"
echo "  Akses browser kamu di:"
echo "  http://$SERVER_NAME/install/install.php"
echo "================================================="
