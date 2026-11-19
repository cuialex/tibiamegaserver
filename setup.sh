#!/usr/bin/env bash
# Instalador del servidor de juego en Ubuntu 22.04 / 24.04 (como root).
# Uso:  sudo ./setup.sh TU_IP_O_DOMINIO
#
# AVISO: cada paso se hizo a mano y funciono, pero este script completo
# todavia no se ha probado de principio a fin. Leelo antes de ejecutarlo.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Ejecuta con sudo."; exit 1; }
[ $# -ge 1 ] || { echo "Uso: sudo ./setup.sh TU_IP_O_DOMINIO"; exit 1; }

PUBLIC_IP="$1"
DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_USER="${SUDO_USER:-root}"
DB_NAME=tibiacore
DB_USER=tibia
DB_PASS="$(openssl rand -hex 16)"

echo "==> 1/6 Instalando dependencias"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential cmake git curl zip unzip gdb python3 openssl \
  libluajit-5.1-dev libmariadb-dev-compat libboost-date-time-dev \
  libboost-filesystem-dev libboost-system-dev libboost-iostreams-dev \
  libpugixml-dev libgmp3-dev libcrypto++-dev libfmt-dev libjsoncpp-dev \
  mariadb-server

echo "==> 2/6 Compilando el servidor (tarda varios minutos)"
sudo -u "$RUN_USER" bash -c "cd '$DIR/compiler' && mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make -j\$(nproc)"

echo "==> 3/6 Base de datos"
systemctl enable --now mariadb
mariadb -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4;"
mariadb -e "CREATE USER IF NOT EXISTS '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';"
mariadb -e "ALTER USER '$DB_USER'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';"
mariadb -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'127.0.0.1'; FLUSH PRIVILEGES;"
mariadb "$DB_NAME" < "$DIR/sql/tibiacore-schema.sql"

echo "==> 4/6 config.lua"
CFG="$DIR/compiler/config.lua"
if [ -e "$CFG" ]; then
  echo "    Ya existe config.lua; no lo toco."
else
  sed -e "s|TU_IP_O_DOMINIO|$PUBLIC_IP|" -e "s|CAMBIAME|$DB_PASS|" "$DIR/config.lua.example" > "$CFG"
  chown "$RUN_USER" "$CFG"; chmod 600 "$CFG"
fi

echo "==> 5/6 Corrigiendo el templo de Thais en el mapa"
python3 "$DIR/tools/fix_thais_temple.py" "$DIR/compiler/data/world/maptest.otbm"

echo "==> 6/6 Servicio systemd"
sed -e "s|__DIR__|$DIR|g" -e "s|__USER__|$RUN_USER|g" "$DIR/deploy/tfs.service" > /etc/systemd/system/tfs.service
systemctl daemon-reload
systemctl enable --now tfs

cat <<MSG

Listo. Revisa:  systemctl status tfs   y   journalctl -u tfs -f
Abre en el firewall los puertos TCP 7171 y 7172 (y 80/443 para la web).
Siguiente paso: instalar MyAAC (ver docs/DEPLOY.md, seccion "Pagina web").
MSG
