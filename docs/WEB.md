# Sitio web (MyAAC 1.9.7)

Carpeta `web/` = copia del sitio en produccion, sin datos privados.

## Instalar
1. Copia `web/` a la carpeta publica de tu servidor (nginx + PHP 8.3).
2. Copia `deploy/myaac.config.local.php.example` a `web/config.local.php` y rellena DB y site_url.
3. Instala dependencias si falta `vendor/`: `composer install`.
4. Importa `sql/myaac-settings.sql` (ajusta `status_ip`).
5. Admin > Menus > "Reset Menus to default" (llena el menu: Characters, Highscores, Guilds...).
6. Limpia cache: borra `system/cache/*` y reinicia php-fpm (o `opcache_reset()` / `apcu_clear_cache()`).

## Cambios respecto a MyAAC original
- Solo plantilla `tibiacom` (Kathrine eliminada).
- Selector de plantilla oculto: `templates/tibiacom/index.php` ~linea 463 `if(false)`.
- Estado del servidor: puerto de status 7176 (`core.status_port`) e IP publica (`core.status_ip`).

## Nunca subir
`web/config.local.php`, `system/cache`, logs, `install/`.
