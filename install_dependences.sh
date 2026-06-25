#!/bin/bash

# Salir inmediatamente si algún comando falla
set -e

echo "=========================================================="
echo " INICIANDO CONFIGURACIÓN DE ENTORNO EN UBUNTU SERVER (AWS)"
echo "=========================================================="

echo "=== 1. Actualizando el sistema base ==="
sudo apt-get update && sudo apt-get upgrade -y

echo "=== 2. Instalando utilidades de desarrollo (Make, GCC, etc.) ==="
# Instala 'make' junto con todo el paquete esencial de compilación
sudo apt-get install -y build-essential

echo "=== 3. Descargando e instalando Docker y Docker Compose ==="
# Se utiliza el script oficial de conveniencia recomendado para entornos Cloud
curl -fsSL https://docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh  # Limpia el archivo temporal descargado

echo "=== 4. Configurando permisos del usuario actual ($USER) ==="
# Agrega el usuario por defecto de AWS (u otro activo) al grupo docker
if ! getent group docker > /dev/null; then
    sudo groupadd docker
fi
sudo usermod -aG docker $USER

echo "=========================================================="
echo " CONFIGURACIÓN COMPLETADA CON ÉXITO "
echo "=========================================================="
echo "Para comenzar a usar Docker y Make sin cerrar sesión, ejecute:"
echo ""
echo "    newgrp docker"
echo ""
echo "Comandos para validar que todo funciona:"
echo " - Verificar Make:          make --version"
echo " - Verificar Docker:        docker run hello-world"
echo " - Verificar Compose:       docker compose version"
echo "=========================================================="
