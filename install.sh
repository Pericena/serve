#!/bin/bash

# Solicitar la contraseña para el usuario de Nextcloud
read -s -p "Ingresa la contraseña para el usuario de Nextcloud: " nextcloud_user_password
echo  # Agregar nueva línea después de la entrada de contraseña

# Solicitar la contraseña para la base de datos de Nextcloud
read -s -p "Ingresa la contraseña para la base de datos de Nextcloud: " db_password
echo  # Agregar nueva línea después de la entrada de contraseña

# Actualizar el sistema
sudo apt update
sudo apt upgrade -y

# Configuración de firewall (ufw)
sudo apt install -y ufw
sudo ufw allow 22  # Permitir SSH
sudo ufw allow 80  # Permitir tráfico HTTP
sudo ufw allow 443 # Permitir tráfico HTTPS
sudo ufw enable

# Instalar Apache2
sudo apt install -y apache2

# Instalar certbot y obtener el certificado SSL
sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache -d agoranube.ddns.net --non-interactive --agree-tos --email tu@email.com

# Configurar redirección HTTP a HTTPS en Apache2
echo -e "<VirtualHost *:80>\n\tServerName agoranube.ddns.net\n\tRedirect permanent / https://agoranube.ddns.net/\n</VirtualHost>" | sudo tee /etc/apache2/sites-available/000-default.conf > /dev/null

# Reiniciar Apache2
sudo systemctl restart apache2

# Instalar Nextcloud
sudo apt install -y mariadb-server
sudo apt install -y nextcloud

# Configurar la base de datos para Nextcloud
sudo mysql_secure_installation
sudo mysql -u root -p -e "CREATE DATABASE nextcloud;"
sudo mysql -u root -p -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '$db_password';"
sudo mysql -u root -p -e "GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost';"
sudo mysql -u root -p -e "FLUSH PRIVILEGES;"

# Configurar Nextcloud
sudo nextcloud.occ maintenance:install --database "mysql" --database-name "nextcloud" --database-user "nextcloud" --database-pass "$db_password"
sudo nextcloud.occ maintenance:mode --on

# Configurar Apache2 para servir Nextcloud
echo -e "<VirtualHost *:443>\n\tServerName agoranube.ddns.net\n\tDocumentRoot /var/www/html/nextcloud\n\tSSLEngine on\n\tSSLCertificateFile /etc/letsencrypt/live/agoranube.ddns.net/fullchain.pem\n\tSSLCertificateKeyFile /etc/letsencrypt/live/agoranube.ddns.net/privkey.pem\n</VirtualHost>" | sudo tee /etc/apache2/sites-available/nextcloud.conf > /dev/null
sudo a2ensite nextcloud.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

# Configuración de seguridad adicional
sudo apt install -y fail2ban

# Configuración de seguridad de Apache
echo -e "ServerTokens Prod\nServerSignature Off" | sudo tee -a /etc/apache2/conf-available/security.conf > /dev/null
sudo a2enconf security

# Configuración de seguridad de PHP
sudo sed -i 's/expose_php = On/expose_php = Off/' /etc/php/7.*/apache2/php.ini

# Reiniciar Apache2 después de la configuración de seguridad
sudo systemctl restart apache2

# Monitorización de registros de seguridad
sudo apt install -y logwatch

# Obtener el estado de Nextcloud
nextcloud_status=$(sudo -u www-data php /var/www/html/nextcloud/occ status | grep "installed:")

# Mostrar el estado de Nextcloud
echo "Estado de Nextcloud: $nextcloud_status"

# Proporcionar el enlace para navegar
echo "Puedes acceder a Nextcloud en: https://agoranube.ddns.net/"
