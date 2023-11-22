#!/bin/bash

# Comentarios descriptivos
# Este script instala y configura Nextcloud en un servidor Ubuntu.

# Solicitar la contraseña para el usuario de Nextcloud
read -s -p "Ingresa la contraseña para el usuario de Nextcloud: " nextcloud_user_password
echo  # Agregar nueva línea después de la entrada de contraseña

# Solicitar la contraseña para la base de datos de Nextcloud
read -s -p "Ingresa la contraseña para la base de datos de Nextcloud: " db_password
echo  # Agregar nueva línea después de la entrada de contraseña

# Validar entrada del usuario
if [ -z "$nextcloud_user_password" ] || [ -z "$db_password" ]; then
    echo "Las contraseñas no pueden estar en blanco. Salir."
    exit 1
fi

# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Verificar la actualización del sistema
if [ $? -eq 0 ]; then
    echo "Sistema actualizado con éxito"
else
    echo "Error al actualizar el sistema. Salir."
    exit 1
fi

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

# Verificar la instalación del certificado SSL
certbot_status=$?
if [ $certbot_status -eq 0 ]; then
    echo "Certificado SSL instalado con éxito"
else
    echo "Error al instalar el certificado SSL. Salir."
    exit 1
fi

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

# Verificar la instalación de Nextcloud
nextcloud_status=$(sudo -u www-data php /var/www/html/nextcloud/occ status | grep "installed:")

# Mostrar el estado de Nextcloud
echo "Estado de Nextcloud: $nextcloud_status"

# Proporcionar el enlace para navegar
echo "Puedes acceder a Nextcloud en: https://agoranube.ddns.net/"

# Instalar seguridad adicional
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

# Mensaje final
echo "La instalación y configuración de Nextcloud se ha completado con éxito."
