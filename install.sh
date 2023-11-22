#!/bin/bash

# Este script instala y configura Nextcloud en un servidor Ubuntu con Apache2.
# También incluye la creación de un certificado SSL.

# Solicitar la contraseña para el usuario de Nextcloud
read -s -p "Ingresa la contraseña para el usuario de Nextcloud: " nextcloud_user_password
echo  # Agregar nueva línea después de la entrada de contraseña

# Solicitar la contraseña para la base de datos de Nextcloud
read -s -p "Ingresa la contraseña para la base de datos de Nextcloud: " db_password
echo  # Agregar nueva línea después de la entrada de contraseña

# Validar entrada del usuario
if [[ -z "$nextcloud_user_password" || -z "$db_password" ]]; then
    echo "Las contraseñas no pueden estar en blanco. Saliendo."
    exit 1
fi

# Crear directorio para los certificados
sudo mkdir -p /etc/apache2/ssl
cd /etc/apache2/ssl

# Generar claves SSL
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nextcloud.key -out nextcloud.crt -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=agoranube.ddns.net"

# Ajustar permisos
sudo chmod 600 nextcloud.key
sudo chmod 644 nextcloud.crt

# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Verificar la actualización del sistema
if [ $? -ne 0 ]; then
    echo "Error al actualizar el sistema. Saliendo."
    exit 1
fi

# Configuración de firewall (ufw)
sudo apt install -y ufw
sudo ufw allow 22  # Permitir SSH
sudo ufw allow 80  # Permitir tráfico HTTP
sudo ufw allow 443 # Permitir tráfico HTTPS
sudo ufw enable

# Instalar Apache2 y módulos SSL
sudo apt install -y apache2 libapache2-mod-php

# Habilitar módulos
sudo a2enmod ssl
sudo a2enmod headers
sudo a2enmod rewrite

# Configurar Apache2 con SSL
sudo tee /etc/apache2/sites-available/nextcloud.conf > /dev/null <<EOL
<VirtualHost *:80>
    ServerName agoranube.ddns.net
    Redirect permanent / https://agoranube.ddns.net/
</VirtualHost>

<VirtualHost *:443>
    ServerName agoranube.ddns.net
    DocumentRoot /var/www/html/nextcloud

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/nextcloud.crt
    SSLCertificateKeyFile /etc/apache2/ssl/nextcloud.key

    <Directory /var/www/html/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Habilitar el sitio
sudo a2ensite nextcloud

# Reiniciar Apache2
sudo systemctl restart apache2

# Descargar e instalar Nextcloud
wget https://download.nextcloud.com/server/releases/latest.zip -P /tmp
sudo apt install -y unzip
sudo unzip /tmp/latest.zip -d /var/www/html/
sudo chown -R www-data:www-data /var/www/html/nextcloud/

# Configurar Nextcloud
sudo nextcloud.occ maintenance:install --database "mysql" --database-name "nextcloud" --database-user "nextcloud" --database-pass "$db_password"
sudo nextcloud.occ maintenance:mode --on

# Verificar la instalación de Nextcloud
nextcloud_status=$(sudo -u www-data php /var/www/html/nextcloud/occ status | grep "installed:")

# Mostrar el estado de Nextcloud
echo "Estado de Nextcloud: $nextcloud_status"

# Proporcionar el enlace para navegar
echo "Puedes acceder a Nextcloud en: https://agoranube.ddns.net/"

# Instalar seguridad adicional
sudo apt install -y fail2ban

# Configuración de seguridad de PHP
sudo sed -i 's/expose_php = On/expose_php = Off/' /etc/php/7.*/apache2/php.ini

# Reforzar seguridad de MySQL
sudo tee /etc/mysql/mariadb.conf.d/99-nextcloud.cnf > /dev/null <<EOL
[mysqld]
bind-address = 127.0.0.1
EOL

# Reiniciar servicios después de la configuración de seguridad
sudo systemctl restart apache2
sudo systemctl restart mysql

# Monitorización de registros de seguridad
sudo apt install -y logwatch

# Mostrar los servicios y paquetes instalados
echo -e "\nServicios y paquetes instalados:"
echo "---------------------------------"
echo "1. Apache2"
echo "2. MariaDB Server"
echo "3. Nextcloud"
echo "4. Fail2Ban"
echo "5. Logwatch"

# Lista de paquetes instalados
installed_packages=$(dpkg -l | grep ^ii | awk '{print $2}')
echo -e "\nPaquetes instalados:"
echo "$installed_packages"

# Comandos adicionales
echo -e "\nComandos adicionales ejecutados:"
echo "---------------------------------"
echo "apt install -y apt-transport-https bash-completion bzip2 ca-certificates cron curl dialog \
dirmngr ffmpeg ghostscript git gpg gnupg gnupg2 htop jq libfile-fcntllock-perl \
libfontconfig1 libfuse2 locate lsb-release net-tools rsyslog screen smbclient \
socat software-properties-common ssl-cert tree ubuntu-keyring unzip wget zip  systemctl mask sleep.target suspend.target hibernate.target"
echo "reboot now"
echo "sudo -s"
echo "apt update && apt upgrade -y && apt autoremove -y && apt autoclean -y"
echo "mkdir -p /var/www /var/nc_data"
echo "chown -R www-data:www-data /var/nc_data /var/www"
echo "apt install -y redis-server libapache2-mod-php8.1 php-common \
php8.1-{fpm,gd,curl,xml,zip,intl,mbstring,bz2,ldap,apcu,bcmath,gmp,imagick,igbinary,mysql,redis,smbclient,cli,common,opcache,readline} \
imagemagick --allow-change-held-packages"
echo "timedatectl set-timezone Europe/Madrid"
echo "wget https://download.nextcloud.com/server/releases/latest.zip"
echo "unzip latest.zip && mv nextcloud/ /var/www/ && chown -R www-data:www-data /var/www/nextcloud && rm -f latest.zip"
