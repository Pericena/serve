
Actualizar los Certificados del Sistema:


sudo update-ca-certificates --fresh
cat /etc/ssl/certs/ca-certificates.crt
sudo apt-get install --reinstall ca-certificates
sudo apt-get install openssl ca-certificates
sudo apt-get install openssl ca-certificates
sudo c_rehash /etc/ssl/certs


