#!/bin/bash
set -e

echo "==> Installation des dépendances..."
sudo apt-get update -q
sudo apt-get install -y -q \
  php php-xml php-curl php-gd php-intl php-ldap \
  php-mbstring php-mysqli php-zip php-bz2 \
  libapache2-mod-php apache2 mariadb-server wget

echo "==> Extraction de GLPI..."
sudo mkdir -p /var/www/html/glpi
sudo tar -xzf /workspaces/glpi/glpi-10.0.15.tgz -C /var/www/html/
sudo chown -R www-data:www-data /var/www/html/glpi

echo "==> Configuration Apache..."
sudo bash -c 'cat > /etc/apache2/sites-available/glpi.conf <<APACHEEOF
<VirtualHost *:8080>
    DocumentRoot /var/www/html/glpi/public
    Alias /css_compiled /var/www/html/glpi/css_compiled
    Alias /js /var/www/html/glpi/js
    Alias /pics /var/www/html/glpi/pics
    <Directory /var/www/html/glpi>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
APACHEEOF'

sudo bash -c 'echo "Listen 8080" > /etc/apache2/ports.conf'
sudo bash -c 'echo "session.cookie_httponly = on" >> /etc/php/8.3/apache2/php.ini'
sudo a2dissite 000-default.conf
sudo a2ensite glpi.conf
sudo a2enmod rewrite
sudo service apache2 start

echo "==> Configuration MariaDB..."
sudo service mariadb start
sleep 2
sudo mysql -e "CREATE DATABASE IF NOT EXISTS glpi;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'glpi'@'localhost' IDENTIFIED BY 'glpi';"
sudo mysql -e "GRANT ALL ON glpi.* TO 'glpi'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "==> Création du .htaccess..."
sudo bash -c 'cat > /var/www/html/glpi/public/.htaccess <<HTEOF
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php [QSA,L]
HTEOF'
sudo chown www-data:www-data /var/www/html/glpi/public/.htaccess

echo "==> GLPI prêt sur le port 8080 !"
