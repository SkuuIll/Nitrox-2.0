#!/bin/bash

# Script de inicio fácil para el instalador del servidor de Nitrox
# Pide al usuario la configuración y luego ejecuta el script principal de instalación.

set -e

# Colores para la salida
BLUE='[0;34m'
GREEN='[0;32m'
YELLOW='[1;33m'
NC='[0m' # Sin color

echo -e "${BLUE}--- Asistente de Instalación del Servidor Nitrox ---${NC}"
echo "Este script te ayudará a configurar los parámetros para la instalación."
echo

# Verificar si el script principal existe
if [ ! -f "./install-vps.sh" ]; then
    echo -e "${RED}[ERROR]${NC} El script principal 'install-vps.sh' no se encuentra. Asegúrate de que esté en el mismo directorio."
    exit 1
fi

# Pedir la información al usuario
read -p "Introduce tu nombre de usuario de Steam: " steam_user
read -s -p "Introduce tu contraseña de Steam: " steam_pass
echo
read -p "Crea una contraseña de administrador para el servidor: " admin_pass
read -p "Introduce un nombre para tu servidor (deja en blanco para el predeterminado): " server_name
read -p "Introduce una contraseña para el servidor (deja en blanco para un servidor público): " server_pass
read -p "Introduce el número máximo de jugadores (1-100, deja en blanco para 100): " max_players

echo
echo -e "${GREEN}--- Resumen de la Configuración ---${NC}"
echo "Usuario de Steam: $steam_user"
echo "Contraseña de Admin: $admin_pass"
echo "Nombre del Servidor: ${server_name:-"Nitrox VPS Server"}"
echo "Contraseña del Servidor: ${server_pass:-"Ninguna (Público)"}"
echo "Máximo de Jugadores: ${max_players:-100}"
echo

read -p "¿Es correcta esta información? (s/n): " confirm
if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
    echo "Instalación cancelada."
    exit 0
fi

# Construir el comando
COMMAND="./install-vps.sh --steam-user "$steam_user" --steam-pass "$steam_pass" --admin-password "$admin_pass""

if [ -n "$server_name" ]; then
    COMMAND="$COMMAND --server-name "$server_name""
fi

if [ -n "$server_pass" ]; then
    COMMAND="$COMMAND --server-password "$server_pass""
fi

if [ -n "$max_players" ]; then
    COMMAND="$COMMAND --max-players "$max_players""
fi

echo
echo -e "${YELLOW}La instalación requiere privilegios de superusuario (sudo) para instalar paquetes.${NC}"
echo "Se te podría pedir tu contraseña de sudo."
echo

# Ejecutar el script principal con sudo
eval "sudo bash -c '$COMMAND'"

echo
echo -e "${GREEN}--- ¡Instalación Completa! ---${NC}"
echo "Puedes gestionar tu servidor usando los scripts en el directorio 'server_data':"
echo "  - ./server_data/start-server.sh  (para iniciar el servidor)"
echo "  - ./server_data/stop-server.sh   (para detener el servidor)"
echo "  - ./server_data/status-server.sh (para ver el estado)"
