# Guia de despliegue

Esta guia resume como dejamos el servidor funcionando en un hosting de OTS y,
sobre todo, **los errores que aparecieron y como se arreglaron**, para no
repetirlos en el servidor definitivo.

> Los pasos del 1 al 5 se hicieron a mano y funcionaron. El script `setup.sh`
> los automatiza, pero ese script completo aun no se ha probado de principio a fin.

## Requisitos

- Ubuntu 22.04 o 24.04, con root o sudo.
- 2 GB de RAM como minimo (el servidor usa ~1.3 GB con el mapa cargado).
- Puertos TCP abiertos: **7171** (login), **7172** (juego), 80/443 (web).

## 1. Compilar

```bash
sudo apt update
sudo apt install -y build-essential cmake git gdb libluajit-5.1-dev \
  libmariadb-dev-compat libboost-date-time-dev libboost-filesystem-dev \
  libboost-system-dev libboost-iostreams-dev libpugixml-dev libgmp3-dev \
  libcrypto++-dev libfmt-dev libjsoncpp-dev
cd compiler && mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release .. && make -j$(nproc)
```

El binario queda en `compiler/build/tfs`. Hay que ejecutarlo desde `compiler/`
(ahi estan `data/` y `config.lua`).

## 2. Base de datos

```bash
sudo mariadb -e "CREATE DATABASE tibiacore CHARACTER SET utf8mb4;"
sudo mariadb -e "CREATE USER 'tibia'@'127.0.0.1' IDENTIFIED BY 'UNA_CONTRASENA_LARGA';"
sudo mariadb -e "GRANT ALL ON tibiacore.* TO 'tibia'@'127.0.0.1'; FLUSH PRIVILEGES;"
sudo mariadb tibiacore < sql/tibiacore-schema.sql
```

Este esquema **no trae cuentas ni tablas de MyAAC**. Las tablas `myaac_*` las
crea el instalador de MyAAC (el SQL viejo las traia en una version antigua y
hacia fallar el instalador con `Unknown column 'hide'`).

## 3. Configuracion

```bash
cp config.lua.example compiler/config.lua
chmod 600 compiler/config.lua
```

Edita `ip`, `mysqlPass` y lo que quieras. Reglas que importan:

| Ajuste | Valor | Por que |
|---|---|---|
| `loginProtocolPort` | `7171` | El cliente entra siempre por 7171 |
| `gameProtocolPort` | `7172` | Puerto del juego |
| `statusProtocolPort` | `7176` | **No** puede repetir el de login |
| `ip` | IP publica o dominio | Es lo que el servidor le dice al cliente |

## 4. Corregir el templo de Thais

En `maptest.otbm` el templo de Thais estaba en z=3 (sin terreno). Sintomas:
`temple position is wrong`, `character could not be loaded`.

```bash
python3 tools/fix_thais_temple.py compiler/data/world/maptest.otbm
```

Pone el templo en (32369, 32241, 7). Hace copia `.bak`, es seguro repetirlo.
Si no quieres tocar el mapa, usa la ciudad 2 (Carlin), que si funciona.

## 5. Servicio systemd

```bash
sed -e "s|__DIR__|$PWD|g" -e "s|__USER__|$USER|g" deploy/tfs.service | \
  sudo tee /etc/systemd/system/tfs.service
sudo systemctl daemon-reload && sudo systemctl enable --now tfs
journalctl -u tfs -f
```

Debe terminar con `Tibiaserver Server Online!`.

## 6. Pagina web (MyAAC)

1. Descarga la ultima version de https://github.com/slawkens/myaac/releases
   (el `.zip` trae todo, incluida la carpeta `vendor`).
2. Descomprimela en la raiz del sitio. **Cuidado:** el zip crea una subcarpeta
   `myaac-X.Y.Z`; mueve su contenido a la raiz.
3. Nginx: usa `nginx-sample.conf` que trae MyAAC. PHP 8.x con `pdo_mysql`, `gd`,
   `zip`, `xml`, `mbstring`.
4. Abre `https://TU_DOMINIO/install/`. Si dice que tu IP no esta permitida,
   escribe tu IP (una por linea, con salto de linea al final) en
   `install/ip.txt` y recarga.
5. En el paso **Configuration**:
   - *Server path*: la ruta de `compiler/` (donde esta `config.lua`), con `/` final.
   - *Client version*: `7.72`.
   - Desmarca las estadisticas de uso si no quieres enviarlas.
6. En **Admin Account** crea tu cuenta de administrador (numero + contrasena
   nuevos, nunca los de prueba).
7. El ultimo paso puede decir `Cannot load file .../items.xml`. Es normal: este
   servidor usa `items.srv` y MyAAC solo pierde las paginas informativas de
   objetos y monstruos. No afecta al registro ni al login.
8. **Borra o mueve la carpeta `install/`** al terminar.
9. Ciudad de los personajes nuevos: copia `deploy/myaac.config.local.php.example`
   al final de `config.local.php` (ya con el templo corregido puedes usar `[1]`).

## 7. Cuentas y personajes

Las contrasenas se guardan con **SHA1** (40 caracteres hexadecimales). Si creas
una cuenta a mano:

```sql
SET SESSION sql_mode='';
INSERT INTO accounts (id, password) VALUES (111222, SHA1('tu_clave'));
INSERT INTO players (name, account_id, town_id, group_id)
VALUES ('NombrePersonaje', 111222, 1, 1);
```

- `id` de `accounts` = numero de cuenta con el que se entra.
- `group_id`: **1 = jugador, 2 = gamemaster, 3 = god** (ver `compiler/data/XML/groups.xml`).
  No existe el grupo 5.
- `town_id` debe existir en el mapa. Si no: `Town ID X which doesn't exist`.
- `SET SESSION sql_mode=''` evita errores por columnas sin valor por defecto.

## Comandos de administrador

`/goto nombre` (jugador, criatura o NPC), `/gotopos x, y, z`, `/pos`, `/town ciudad`,
`/a n`, `/up`, `/down`, `/i id cantidad`, `/m monstruo`, `/addskill`, `/ghost`,
`/kick`, `/ban`, `/save`, `/openserver`, `/closeserver`.

## Problemas que ya vimos

| Sintoma | Causa | Solucion |
|---|---|---|
| Cliente: ERROR 2 / 10060 con un proxy anti-DDoS (OTShield) | El proxy antepone una cabecera de 28 bytes que este servidor no entiende | Desactivar el proxy, o adaptar `protocollogin.cpp` |
| Web Client: error 73 | La version del cliente no coincide con la del servidor | Usar version 7.72 en los dos lados |
| `Town ID 0 which doesn't exist` | Personaje con `town_id = 0` | `UPDATE players SET town_id=...` |
| `Group ID 5 which doesn't exist` | Ese servidor solo define grupos 1, 2 y 3 | Usar `group_id = 3` para god |
| `temple position is wrong` | Templo de Thais en z=3 | `tools/fix_thais_temple.py` |
| SQL `#1364 field has no default` | Modo SQL estricto | `SET SESSION sql_mode='';` |
| MyAAC `Unknown column 'hide'` | Tablas `myaac_*` viejas ya existian | Usar `sql/tibiacore-schema.sql` (sin ellas) |
| Monstruos quietos | Los grupos de admin suelen ser ignorados por monstruos | Probar con un personaje de grupo 1 |
| Aviso `top_player_week doesn't exist` en el log | Tabla opcional de un evento | Inofensivo |

## Seguridad

- Nunca subas `config.lua`, `key.pem`, contrasenas ni copias de la base de datos.
- Cambia cualquier contrasena que hayas escrito en un chat.
- Haz copias de la base: `mysqldump tibiacore | gzip > backup-$(date +%F).sql.gz` (guardalas fuera del repo).
- Mantén el servicio con `Restart=on-failure` y revisa `journalctl -u tfs`.
