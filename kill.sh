#!/bin/bash

# Mostrar estado del sistema antes de la eliminación
echo "Estado del sistema antes de la eliminación:"
free -h
df -h

# Mostrar estado de los servicios antes de la eliminación
echo "Estado de los servicios antes de la eliminación:"
sudo systemctl status apache2
sudo systemctl status mysql
sudo systemctl status mariadb
sudo systemctl status docker

# Detener servicios
sudo systemctl stop apache2     # Detener Apache
sudo systemctl stop mysql       # Detener MySQL / MariaDB
sudo systemctl stop mariadb     # Detener MySQL / MariaDB (si no se usa systemd)
sudo systemctl stop docker      # Detener Docker

# Desinstalar paquetes
sudo apt-get remove --purge apache2 apache2-utils mysql-server mysql-client mariadb-server mariadb-client docker-ce docker-ce-cli containerd.io openssl -y

# Eliminar configuraciones y datos
sudo rm -rf /etc/apache2       # Eliminar configuraciones de Apache
sudo rm -rf /etc/mysql         # Eliminar configuraciones de MySQL / MariaDB
sudo rm -rf /etc/php            # Eliminar configuraciones de PHP (pueden variar según la versión)
sudo rm -rf /var/lib/mysql      # Eliminar datos de MySQL / MariaDB
sudo rm -rf /var/www/html/nextcloud  # Eliminar datos de Nextcloud

# Eliminar certificados SSL (pueden variar según tu configuración)
sudo rm -rf /etc/ssl/certs/*
sudo rm -rf /etc/ssl/private/*

# Limpiar paquetes no utilizados
sudo apt-get autoremove -y

# Mostrar estado del sistema después de la eliminación
echo "Estado del sistema después de la eliminación:"
free -h
df -h

# Mostrar estado de los servicios después de la eliminación
echo "Estado de los servicios después de la eliminación:"
sudo systemctl status apache2
sudo systemctl status mysql
sudo systemctl status mariadb
sudo systemctl status docker

echo "Eliminación completa de Nextcloud, Apache, MySQL/MariaDB, Docker, OpenSSL completada."
