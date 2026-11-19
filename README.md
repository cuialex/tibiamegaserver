# Tibia Mega Server

Servidor de Tibia 7.72 basado en **TibiaCore** (derivado de TFS / OTServ),
listo para desplegar en un VPS Ubuntu, con pagina de registro (MyAAC) y el
cliente OTClientV8.

- Guia de instalacion completa: [`docs/DEPLOY.md`](docs/DEPLOY.md)
- Como compilar (Windows y Ubuntu): [`docs/COMPILAR.md`](docs/COMPILAR.md)
- Instalador rapido (Ubuntu): `sudo ./setup.sh TU_IP_O_DOMINIO`
- Configuracion de ejemplo: [`config.lua.example`](config.lua.example)

## Estructura

| Carpeta / archivo | Para que sirve |
|---|---|
| `compiler/` | Codigo fuente (`src/`) y datos del servidor (`data/`, mapa, spawns) |
| `sql/tibiacore-schema.sql` | Esquema de la base de datos, **sin cuentas ni personajes** |
| `tools/fix_thais_temple.py` | Corrige el templo de Thais en el mapa |
| `deploy/` | Servicio systemd y ejemplo de ajuste de MyAAC |
| `772/` | Archivos del cliente 7.72 (`Tibia.dat`, `Tibia.spr`, `Tibia.otfi`) |

## Importante antes de publicar tu servidor

- **No subas** `config.lua`, contrasenas ni copias de la base de datos. Ya estan en `.gitignore`.
- Cambia la contrasena de MySQL y la de SSH si alguna vez las escribiste en un chat.
- Crea tu propia cuenta de administrador al instalar MyAAC.

## Creditos

- **TibiaCore / Tibia GIMUD Server** — Roberto Carlos Preguica (RCP91), sobre The Forgotten Server y OTServ.
- **MyAAC** — slawkens (https://github.com/slawkens/myaac).
- **OTClientV8** — OTCv8 (https://github.com/OTCv8/otclientv8).
