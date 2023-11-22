#!/bin/bash

# Detener Apache2 si está en ejecución
sudo systemctl stop apache2

# Desinstalar Apache2
sudo apt purge -y apache2
sudo apt autoremove -y

# Eliminar el contenido de /var/www/html
sudo rm -rf /var/www/html/*

# Detener MariaDB si está en ejecución
sudo systemctl stop mariadb

# Desinstalar MariaDB
sudo apt purge -y mariadb-server
sudo apt autoremove -y

# Eliminar la base de datos de Nextcloud en MariaDB
sudo mysql -u root -p -e "DROP DATABASE IF EXISTS nextcloud;"
sudo mysql -u root -p -e "DROP USER IF EXISTS 'nextcloud'@'localhost'; FLUSH PRIVILEGES;"

# Desinstalar Nextcloud
sudo nextcloud.occ maintenance:mode --off
sudo rm -rf /var/www/html/nextcloud
sudo apt purge -y nextcloud
sudo apt autoremove -y

# Desinstalar certbot
sudo apt purge -y certbot python3-certbot-apache
sudo apt autoremove -y

# Eliminar configuraciones y certificados de Apache2
sudo rm /etc/apache2/sites-available/nextcloud.conf
sudo a2dissite nextcloud.conf
sudo rm -rf /etc/letsencrypt

# Limpiar la configuración y los datos de MySQL/MariaDB
sudo rm -rf /etc/mysql/
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/my.cnf*

# Limpiar el directorio de log de MySQL/MariaDB
sudo rm -rf /var/log/mysql

# Limpiar directorios y archivos residuales de certbot
sudo rm -rf /etc/letsencrypt

# Limpiar configuraciones adicionales si las hay
# ...

# Mostrar el estado del servidor
echo "Estado del servidor después de la limpieza:"
sudo systemctl status apache2
sudo systemctl status mariadb
sudo systemctl status ufw

# Mostrar el uso de memoria
echo -e "\nUso de memoria:"
free -h

# Mostrar el espacio en disco
echo -e "\nEspacio en disco:"
df -h

echo "Limpieza completa y estado del servidor mostrado."
