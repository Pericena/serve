#!/bin/bash

# Configuración
NEXTCLOUD_DOMAIN=""
NEXTCLOUD_USER=""
NEXTCLOUD_PASSWORD=""

# Actualizar el sistema
sudo apt update
sudo apt upgrade -y

# Instalar paquetes necesarios
sudo apt install -y apache2 mariadb-server libapache2-mod-php8.1 php8.1-cli php8.1-mysql php8.1-gd php8.1-json php8.1-curl php8.1-zip php8.1-xml php8.1-mbstring php8.1-bz2 php8.1-intl php8.1-ldap php8.1-apcu php8.1-redis php8.1-imagick php8.1-fpm redis-server fail2ban ufw

# Configurar Apache y PHP
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod env
sudo a2enmod dir
sudo a2enmod mime
sudo systemctl restart apache2

# Crear la base de datos para Nextcloud
sudo mysql_secure_installation
sudo mysql -u root -p -e "CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
sudo mysql -u root -p -e "CREATE USER '$NEXTCLOUD_USER'@'localhost' IDENTIFIED BY '$NEXTCLOUD_PASSWORD';"
sudo mysql -u root -p -e "GRANT ALL PRIVILEGES ON nextcloud.* TO '$NEXTCLOUD_USER'@'localhost';"
sudo mysql -u root -p -e "FLUSH PRIVILEGES;"

# Descargar e instalar Nextcloud
wget https://download.nextcloud.com/server/releases/latest.zip
sudo unzip latest.zip -d /var/www/html/
sudo chown -R www-data:www-data /var/www/html/nextcloud/
sudo chmod -R 755 /var/www/html/nextcloud/

# Configurar el sitio de Apache
sudo tee /etc/apache2/sites-available/nextcloud.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/nextcloud/
    ServerName $NEXTCLOUD_DOMAIN

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/html/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>

</VirtualHost>
EOF

# Habilitar el sitio de Nextcloud y reiniciar Apache
sudo a2ensite nextcloud.conf
sudo systemctl restart apache2

# Instalar Let's Encrypt y obtener certificado
sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache --agree-tos --redirect --hsts --staple-ocsp --email admin@$NEXTCLOUD_DOMAIN -d $NEXTCLOUD_DOMAIN

# Configurar Redis para Nextcloud
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Configurar fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Configurar ufw
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Calificar la seguridad de Nextcloud
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:install --database "mysql" --database-name "nextcloud"  --database-user "$NEXTCLOUD_USER" --database-pass "$NEXTCLOUD_PASSWORD" --admin-user "admin" --admin-pass "$NEXTCLOUD_PASSWORD"

# Configuraciones de seguridad adicionales
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set loglevel --value="2"
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set log_rotate_size --value="104857600"
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set logdateformat --value="Y-m-d H:i:s"
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set syslog_tag --value="nextcloud"
sudo -u www-data php /var/www/html/nextcloud/occ config:system:set syslog_loglevel --value="2"

# Configurar el dominio en config.php
sudo -u www-data sed -i "s/'overwrite.cli.url' => '',/'overwrite.cli.url' => 'https:\/\/$NEXTCLOUD_DOMAIN',/" /var/www/html/nextcloud/config/config.php

# Reiniciar Apache después de realizar cambios en config.php
sudo systemctl restart apache2

# Ejecutar el cron de fondo de Nextcloud
sudo -u www-data php /var/www/html/nextcloud/occ background:cron

# Configurar el archivo 001-nextcloud-le-ssl.conf
sudo tee /etc/apache2/sites-available/001-nextcloud-le-ssl.conf <<EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/nextcloud/
    ServerName $NEXTCLOUD_DOMAIN

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/html/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>

    SSLCertificateFile /etc/letsencrypt/live/$NEXTCLOUD_DOMAIN/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$NEXTCLOUD_DOMAIN/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
</IfModule>
EOF

# Habilitar el sitio SSL y reiniciar Apache
sudo a2ensite 001-nextcloud-le-ssl.conf
sudo systemctl restart apache2

# Imprimir mensaje de finalización
echo "La instalación de Nextcloud se ha completado. Puedes acceder a tu instancia en: https://$NEXTCLOUD_DOMAIN"
